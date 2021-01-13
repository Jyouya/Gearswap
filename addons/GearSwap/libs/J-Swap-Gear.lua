require('tables')
res = require('res')
local deferred = require('deferred')
local ltn = require('LTN')

local WARNING_COLOR = 104
local MESSAGE_COLOR = 105
local DEBUG_COLOR = 106
local ERROR_COLOR = 107

local gear -- the file returns this

local function warning(...) add_to_chat(WARNING_COLOR, table.concat {...}) end

local function debug_print(...)
    if debug then add_to_chat(DEBUG_COLOR, table.concat {...}) end
end

-- Returns a promise that is rejected after a certain amount of time
local function timeout(sec)
    local d = deferred.new()
    coroutine.schedule(function() d:reject('Timeout') end, sec)
    return d
end

local function set_timeout(cb, delay)
    local run = true
    local co = coroutine.schedule(function() if run then cb() end end, delay)
    return co, function() run = false end
end

local item_id_memo = setmetatable(T {}, {
    __index = function(t, k)
        local item_name = type(k) == 'table' and k.name or k
        t[k] = res.items:with('en', k).id
        return t[k]
    end
})

local function cancel_buff(id)
    windower.packets.inject_outgoing(0xF1, string.char(0xF1, 0x04, 0, 0,
                                                       id % 256,
                                                       math.floor(id / 256), 0,
                                                       0)) -- Inject the cancel packet
end

local function hash_item(item)
    if type(item) == "string" then
        return item
    else
        return item.alias or (item.name + (item.wardrobe or "") +
                   (item.augments and item.augments:concat() or ""))
    end
end

local calibrated_gear_info

local function write_gear_to_file(gear)
    calibrated_gear_info = gear -- We want the new table so we don't have to restart gs
    local player = windower.ffxi.get_player()
    gear = setmetatable(T {}, {__index = gear_stats})
    ltn.writeToFile(gear,
                    player.name .. '-' .. player.main_job .. '-gear-info.lua')
end

-- This function is the entrypoint for the entire calibration process, returns a promise
local two_h_weapon
local two_h_weapon_stats
local function untitled_main_function()
    windower.add_to_chat(MESSAGE_COLOR,
                         "Calibrating gear, this may take several minutes")

    local promise = deferred.new()
    removeAllBuffs:next(function()
        -- Check settings and sets for a 2h weapon
        two_h_weapon = find_2h_weapon(settings) or find_2h_weapon(sets)
        if not two_h_weapon then
            warning(
                "No two handed weapons detected.  Grips will not be calibrated")
        end

        return calibrate_all_gear()
    end, function(err) promise:reject(err) end):next(calibrate_all_gear):next(
        write_gear_to_file)

    return promise
end

-- Remove all buffs
local function remove_all_buffs()
    local promise = deferred.new()
    for _, buff in pairs(windower.ffxi.get_player().buffs) do cancel(buff) end
    set_timeout(function()
        if #windower.ffxi.get_player().buffs then
            promise:reject("Unable to remove buffs, try again later")
        else
            promise:resolve()
        end
    end, 5)
    return promise
end

local gear_slots = S {
    'main', 'sub', 'range', 'ammo', 'head', 'body', 'hands', 'legs', 'feet',
    'neck', 'waist', 'back', 'ear1', 'ear2', 'left_ear', 'right_ear', 'ring1',
    'ring2', 'left_ring', 'right_ring'
}

local function find_2h_weapon(table)
    for k, v in pairs(table) do
        if type(v) == 'string' and gear_slots[v] then
            local item = res.items[item_id_memo[v]]
            if item.skill ~= 1 and item_slots:contains(0) and
                not item_slots:contains(1) then return v end
        elseif type(v) == 'table' then
            if v.name then -- v is an item
                local item = res.items[item_id_memo[v]]
                if item.skill ~= 1 and item_slots:contains(0) and
                    not item_slots:contains(1) then return v end
            else -- v is not an item
                local item = find_2h_weapon(v)
                if item then return item end
            end
        end
    end
end

local function calibrate_all_gear()
    local promise = deferred.new()

    local all_gear = table.update(flatten_sets(sets), faltten_sets(settings))

    if two_h_weapon then
        calibrate_item(two_h_weapon):next(
            function(result)
                two_h_weapon_stats = result
                return
            end, function(error)
                add_to_chat(ERROR_COLOR, "Unable to calibrate 2h weapon.  " ..
                                tostring(error))
                add_to_chat(ERROR_COLOR, "Aborting")
                promise:reject()
            end):next(function()
            local promise = deferred.new()
            local res = T {}
            local k

            local function calibrate_next_gear()
                local item
                k, item = next(all_gear, k)
                if item then return calibrate_item(item) end
            end

            local function success(result)
                res[k] = result
                if next(all_gear, k) then
                    calibrate_next_gear():next(success, failure)
                else -- There is no more gear to calibrate
                    promise:resolve(res)
                end
            end

            local function failure(error)
                if next(all_gear, k) then
                    calibrate_next_gear():next(success, failure)
                else -- There is no more gear to calibrate
                    promise:resolve(res)
                end
            end

            calibrate_next_gear():next(success, failure)

            return promise
        end)
    end

    return promise
end

-- Call with no item_db to generate a new one
local function flatten_sets(sets, item_db)
    item_db = item_db or T {}
    for k, v in pairs(set) do
        if type(v) == 'string' and gear_slots[v] or type(v) == 'table' and
            v.name then
            item_db[hash_item(v)] = {slot = k, item = v}
        else
            flatten_sets(v, item_db)
        end
    end
    return item_db
end

local function equip_and_wait(gear_set)
    local promise = deferred.new()

    equip(gear_set)
    set_timeout(function() promise:resolve() end, 2) -- TODO: fine tune this number

    return promise
end

-- Wrapper function to load the gearswap environment and then trigger _calibrate_item
local function calibrate_item(item)
    local promise = deferred.new()
    -- tostring(promise) serves as a unique identifier
    command:register(tostring(promise), function()
        command:unregister(tostring(promise))
        _calibrate_item(item):next(promise.resolve:apply(promise),
                                   promise.reject:apply(promise))
    end)
    windower.send_command('gs c ' .. tostring(promise))
    return promise
end

local function _calibrate_item(item)
    local promise = deferred.new()
    local item_name = type(item) == 'table' and item.name or item
    local item_info = res.items:with('en', item_name)
    if not item_info then
        promise:reject('Item not found in resources: ' .. item_name)
        return promise
    end

    if item_info.slots:contains(8) and
        (item_info.skill == 25 or item_info.skill == 26) then
        promise:reject('Cannot calibrate bullets, bolts, or arrows')
        return promise
    end

    local equip_set = empty_set

    local is_grip = item_info.slots:contains(2) and item_info.skill == 0

    -- Add a 2h weapon to our test set 
    if is_grip then
        if two_h_weapon then
            equip_set = set_combine(equip_set, {main = two_h_weapon})
        else
            promise:reject('Cannot calibrate grips without a 2h weapon')
            return promise
        end
    end

    local equip_set = set_combine(equip_set, {[item.slot] = item.item})

    equip_and_wait(equip_set):next(function()
        -- do checkparam and checkequip

        -- Success handler
        local function success(results)
            -- Combine the results of checkparam and check equip
            local res = results[1]:update(results[2])

            -- Subtract the 2h weapon stats if item is a grip
            if is_grip then
                for k, v in pairs(two_h_weapon_stats) do
                    res[k] = res[k] - v
                end
            end

            promise:resolve(res)
        end

        -- Retry once, then fail
        local function retry(error)
            deferred.all({checkparam(), checkequip()}):next(success, failure)
        end

        -- Failure handler if retry fails
        local function failure(error) promise:reject() end

        deferred.all({checkparam(), checkequip()}):next(success, retry)
    end)

    return promise
end

local checkparam_messages = {
    [712] = {'accuracy', 'attack'},
    [713] = {'sub_accuracy', 'sub_attack'},
    [714] = {'ranged_accuracy', 'ranged_attack'},
    [715] = {'evasion', 'defense'}
}

-- function returns a promise of a table of stats
local function checkparam()
    -- Create our promise
    local promise = deferred.new()
    local result = T {}

    local function handle_checkparam_packet(id, data, modified, injected,
                                            blocked)
        if id == 0x029 and not blocked then
            local parsed = packets.parse('incoming', data)
            local message = checkparam_messages[parsed.Message]
            -- TODO: Block the packet
            result[message[1]] = parsed['Param 1']
            result[message[2]] = parsed['Param 2']

            if result.defense and result.evasion and result.rAcc and result.rAtk and
                result.subAcc and result.subAtk and result.acc and result.atk then

                windower.unregister_event('incoming chunk',
                                          handle_checkparam_packet)
                promise:resolve(result)
            end
        end
    end

    windower.raw_register_event('incoming chunk', handle_checkparam_packet)

    local player = windower.ffxi.get_player()
    local checkparam_packet = packets.new('outgoing', 0x0DD, {
        ['Target'] = player.id,
        ['Target Index'] = player.index,
        ['_unknown1'] = 0,
        ['Check Type'] = 2,
        ['_junk'] = {0, 0, 0}
    })
    packets.inject(checkparam_packet)
    return deferred.first {promise, timeout(5)}
end

local function checkequip()
    promise = deferred.new()

    local function handle_equip_screen_packet(id, data, modified, injected,
                                              blocked)
        if id == 0x061 and not blocked then
            windower.unregister_event('incoming chunk',
                                      handle_equip_screen_packet)

            local parsed = packets.parse('incoming', data)

            promise:resolve({
                hp = parsed['Maximum HP'],
                mp = parsed['Maximum MP'],
                str = parsed['Added STR'],
                dex = parsed['Added DEX'],
                vit = parsed['Added VIT'],
                int = parsed['Added INT'],
                mnd = parsed['Added MND'],
                chr = parsed['Added CHR'],
                attack = parsed['Attack']
            })

            -- TODO: Block the packet
        end
    end

    windower.raw_register_event('incoming chunk', handle_equip_screen_packet)

    local checkparam_packet = packets.new('outgoing', 0x061, {})
    packets.inject(checkparam_packet)

    return deferred.first {promise, timeout(5)}
end

local empty_set = {
    main = empty,
    sub = empty,
    range = empty,
    ammo = empty,
    head = empty,
    body = empty,
    hands = empty,
    legs = empty,
    feet = empty,
    neck = empty,
    waist = empty,
    ear1 = empty,
    ear2 = empty,
    ring1 = empty,
    ring2 = empty,
    back = empty
}

-- Parse function provided by ZetaEypon
local function parse(item_id)

    local stat_table = {}
    local pet_table = {}
    local set_table = {}
    local unity_table = {}
    local latent_table = {}

    local tokens = string.split(
                       string.gsub(items[item_id].ja.description, '\n', ' '),
                       ' ')

    local active_table = stat_table

    for _, token in ipairs(tokens) do
        if token:startswith('ペット:') then
            active_table = pet_table
            token = token:gsub('ペット', '')
        elseif token:startswith('ユニティランク:') then
            active_table = unity_table
            token = token:gsub('ユニティランク:', '')
        elseif token:startswith('潜在能力') then
            active_table = latent_table
            token = token:gsub('潜在能力', '')
        end

        -- [+-]?\d+%?
        local value = string.match(token, "[+-]?%d+%%?") or ''

        local stat_str = string.gsub(token, '[+-]?%d+', '${VALUE}')
        local value_str = string.match(token, '[+-]?%d+') or ''

        active_table[stat_str] = value_str
        -- print(k..': '..tokens[k]..' '..value..' | '..stat_str..' | '..tonumber(value_str))
    end
    return {
        stats = stat_table,
        pet = pet_table,
        unity = unity_table,
        latent = latent_table
    }
end

-- removes conditions from stat strings.  e.g.  'Daytime: Accuracy' -> 'Accuracy'
-- values with ranges will become the upper bound of the range
local function normalize_stats(parsed_item)
    for _, stat_table in pairs(parsed_item) do
        for stat_str_1, value_str_1 in pairs(stat_table) do
            stat_str_2 = stat_str:gsub('.*:', '')
            value_str_2 = value_str:gsub('%d*～', '')

            if stat_str_1 ~= stat_str_2 then
                local value_1 = tonumber(stat_table[stat_str_2])
                local value_2 = tonumber(value_str_2)
                stat_table[stat_str_2] = value_1 + value_2
                stat_table[stat_str_1] = nil
            else
                stat_table[stat_str_2] = tonumber(value_str_2)
            end
        end
    end

    return parsed_item
end

local translation_table = T {
    ['Ｄ'] = 'DMG',
    ['隔'] = 'Delay',

    -- Things we care about
    ['攻'] = 'attack',
    ['命中'] = 'accuracy',
    ['飛攻'] = 'ranged_attack',
    ['飛命'] = 'ranged_accuracy',
    ['魔攻'] = 'magic_attack_bonus',
    ['魔命'] = 'magic_accuracy',

    -- Misc
    ['敵対心'] = 'enmity',
    ['コンサーブMP+4'] = 'conserve_mp',

    -- Skills (incomplete)
    ['投てきスキル'] = 'throwing_skill',
    ['弱体魔法スキル'] = 'enfeebling_skill'
}

local function translate(parsed_item)
    local res = {}
    for k, stat_table in pairs(parsed_item) do
        local new_stat_table = {}
        for stat_str, value_string in pairs(stat_table) do
            local en = translation_table[stat_str] or stat_str
            new_stat_table[en] = value_string
        end
        res[k] = new_stat_table
    end
    return res
end

local function apply_unity_effects(translated_item) 
    local res = translated_item.stats
    for k, v in translated_item.unity do
        res[k] = (res[k] or 0) + v
    end
    res.pet = translated_item.pet
end

local function parse_augments(augments) 
    local res = {}
    for _, augment in ipairs(augments) do
        if augment:match('Pet:') then

        end
        augment:match('.+[+-]?%d+')
    end 
    return res
end

local function no_stat() return 0 end

local function gear_stats(t, item)

    local hashed_item = hash_item(item)

    if t[hashed_item] then return t[hashed_item] end

    local item_id = item_id_memo(item)

    if not calibrated_gear_info then
        calibrated_gear_info = T(dofile(player.name .. '-' .. player.main_job ..
                                            '-gear-info.lua') or {})
    end

    local parsed = parse(item_id)
    normalize_stats(parsed)
    local translated = translate(parsed)

    local final_parsed = setmetatable(translated, {__index = no_stat})

    -- TODO: Try to parse augments
    if item.augments then
    
    end

    result = table.update(final_parsed, calibrated_gear_info(hash_item(item)))

    t[hashed_item] = item

    return item
end

gear = setmetatable(T {}, {__index = gear_stats})

return gear
