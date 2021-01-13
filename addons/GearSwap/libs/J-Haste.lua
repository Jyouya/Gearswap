local packets = require('packets')
-- local res = require('resources')
require('tables')
require('sets')

local events = require('J-Swap-Events')
_haste_change = _haste_change or require('event').new()

local job_dw = 0
local function update_job_dw() -- function must be called in a gearswap event for player to exist
    if player.main_job == 'NIN' then
        job_dw = 35
    elseif player.main_job == 'DNC' then
        job_dw = 35
    elseif player.main_job == 'THF' then
        job_dw = 30
    elseif player.sub_job == 'NIN' then
        job_dw = 25
    elseif player.sub_job == 'DNC' then
        job_dw = 15
    end
end

events.load:register(update_job_dw)
events.sub_job_change:register(update_job_dw)

-- Going to assume every build is haste capped, but the user can manually overwrite that
local gear_haste = 256
local function set_gear_haste(haste) gear_haste = haste end

local haste_level = 0
events.buff_change:register(function(buff, gain, buff_details)
    if buff == 'Haste' then
        if not gain then haste_level = 0 end
        _haste_change:trigger(true)
    elseif buff == 'Embrava' or buff == 'March' or buff_details.id == 604 or
        buff_details.id == 580 then
        _haste_change:trigger(true)
    end
end)

-- TODO: Test for marcato, assume HM has marcato if it's been 10 minutes since that bard last used it
local marches = T {'Honor March', 'Victory March', 'Advancing March'}
local march_haste = {
    ['Honor March'] = 261, -- 174 without marcato
    ['Victory March'] = 293,
    ['Advancing March'] = 194
}
local function get_MA_haste()
    local ma_haste = 0
    if buffactive[33] then
        ma_haste = ma_haste + (haste_level == 2 and 257 or 150)
    end

    -- buffactive.march gives the number of active marches
    for i = 1, buffactive.march or 0, 1 do
        ma_haste = ma_haste + march_haste[marches[i]]
    end

    if buffactive[604] then -- Mighty Guard
        ma_haste = ma_haste + 150
    end

    if buffactive[580] then -- indi/geo haste
        ma_haste = ma_haste + 300
    end

    return ma_haste
end

local haste_samba_time = 0
local haste_samba_potency = 51
local function expire_haste_samba()
    if os.time() - haste_samba_time >= 10 then _haste_change:trigger() end
end

local function get_JA_haste()
    local ja_haste = 0
    ja_haste = ja_haste +
                   ((os.time() - haste_samba_time < 10) and haste_samba_potency or
                       0)
    return ja_haste <= 256 and ja_haste or 256
end

local function get_total_haste()
    local ja_haste = get_JA_haste()
    local ma_haste = get_MA_haste()
    local embrava_haste = buffactive.embrava and 266 or 0

    ja_haste = ja_haste <= 256 and ja_haste or 256
    ma_haste = ma_haste <= 448 and ma_haste or 448


    local total = gear_haste + ja_haste + ma_haste + embrava_haste
    return total <= 819 and total or 819
end

local function get_dw_needed()
    return math.ceil((1 - (0.2 / ((1024 - get_total_haste()) / 1024))) * 100 -
                         job_dw)
end

local packets_incoming = {}

local party_from_packet = {}
packets_incoming[0x0DD] = function(data)
    local packet = packets.parse('incoming', data)
    party_from_packet[packet['ID']] = {
        id = packet['ID'],
        name = packet['Name'],
        ['Main job'] = packet['Main job'],
        ['Sub job'] = packet['Sub job']
    }
end

local members_haste_samba = {}
do -- Action packet processing
    local function is_target(player_id, targets)
        for _, target in ipairs(targets) do
            if player_id == target.id then return true end
        end
        return false
    end

    local function add_march(march)
        for i = 1, 3 do
            if marches[i] == march then
                marches:remove(i)
                marches:insert(1, march)
                break
            end
        end
    end

    local mob_haste_daze_potency = T {}
    windower.register_event('action', function(action)
        local player = windower.ffxi.get_player()
        if is_target(player.id, action.targets) and action.category == 4 then
            local param = action.param
            if param == 57 and haste_level ~= 2 then
                haste_level = 1
                _haste_change:trigger()
            elseif param == 511 then
                haste_level = 2
                _haste_change:trigger()
            elseif param == 417 then
                add_march('Honor March')
                _haste_change:trigger()
            elseif param == 420 then
                add_march('Victory March')
                _haste_change:trigger()
            elseif param == 419 then
                add_march('Advancing March')
                _haste_change:trigger()
            end
        elseif action.category == 1 then
            local target_id = action.targets[1].id
            if action.actor_id == player.id then
                local melee_attack = action.targets[1].actions[1]

                if melee_attack.has_add_effect and
                    melee_attack.add_effect_animation == 23 then
                    -- refresh player haste samba time
                    -- if we don't have an active haste samba then fire the haste change event
                    local update
                    if os.time() - haste_samba_time >= 10 then
                        update = true
                    end
                    haste_samba_time = os.time()
                    local new_potency = mob_haste_daze_potency[target_id] or 51
                    if haste_samba_potency ~= new_potency then
                        update = true
                    end
                    haste_samba_potency = new_potency

                    if update then _haste_change:trigger() end
                    coroutine.schedule(expire_haste_samba, 10)
                end
            end
            -- If someone with haste samba active attacks a mob:
            if members_haste_samba[action.actor_id] then
                if party_from_packet[action.actor_id] and
                    party_from_packet[action.actor_id]['Main Job'] == 'DNC' then
                    mob_haste_daze_potency[target_id] = 101
                else
                    mob_haste_daze_potency[target_id] = 51
                end
            end
        end
    end)
end

packets_incoming[0x076] = function(data)
    for k = 0, 4 do
        local id = data:unpack('I', k * 48 + 5)
        if id ~= 0 then
            local haste_samba = false
            for i = 1, 32 do
                -- Credit: Byrth, GearSwap
                local buff = data:byte(k * 48 + 5 + 16 + i - 1) + 256 *
                                 (math.floor(
                                     data:byte(
                                         k * 48 + 5 + 8 +
                                             math.floor((i - 1) / 4)) / 4 ^
                                         ((i - 1) % 4)) % 4)

                if buff == 370 then -- Haste Samba
                    haste_samba = true
                    break
                end
            end

            if haste_samba then
                members_haste_samba[id] = true
            else
                members_haste_samba[id] = false
            end
        end
    end
end

windower.raw_register_event('incoming chunk',
                            function(id, data, modified, injected, blocked)
    if packets_incoming[id] then
        packets_incoming[id](data, modified, injected, blocked)
    end
end)

return setmetatable({}, {
    dw_needed = {get = get_dw_needed},
    total = {get = get_total_haste},
    gear_haste = {set = set_gear_haste},
    change = _haste_change,

    __index = function(self, key)
        local v = getmetatable(self)[key]
        return v and v.get and v.get() or v
    end,
    __newindex = function(self, i, v)
        local prop = getmetatable(self)[i]
        if prop.set then prop.set(v) end
    end
})
