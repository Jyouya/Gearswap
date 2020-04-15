-- This is a fork of rnghelper by snaps

require('queues')
local res = require('resources')
local packets = require('packets')
local config = require('config2')
local M = require('J-Mode')
local events = require('J-Swap-Events')
local coroutine = require('coroutine')

local player_id = windower.ffxi.get_player().player_id
local target = nil
local completion = false
local mode = nil
local weaponskill = M({string=''})
local cooldowns = {}
local timeouts = {}
local clear_timeout = function() end
local settings = config.load('libs/rnghelper_settings.xml')
local cooldown = 0
local queue = Q {}
local pending = nil
local enabled = M(true, 'AutoRA Enabled')
local use_aftermath = M(false, 'AutoRA Aftermath')
local ws_tp = M(1000, 'AutoRA Weaponskill TP')
local stop_on_tp = M(false, 'AutoRA Stop on TP')

local action_events = {
    [2] = 'mid /ra',
    [3] = 'mid /ws',
    [4] = 'mid /ma',
    [5] = 'mid /item',
    [6] = 'pre /ja',
    [7] = 'pre /ws',
    [8] = 'pre /ma',
    [9] = 'pre /item',
    [12] = 'pre /ra',
    [14] = 'pre /ja',
    [15] = 'pre /ja'
}

local terminal_action_events = {
    [2] = 'mid /ra',
    [3] = 'mid /ws',
    [4] = 'mid /ma',
    [5] = 'mid /item',
    [6] = 'pre /ja'
}

local action_interrupted = {[78] = 78, [84] = 84}

local action_message_interrupted = {[16] = 16, [62] = 62}

local action_message_unable = {
    [12] = 12,
    [17] = 17,
    [18] = 18,
    [34] = 34,
    [35] = 35,
    [40] = 40,
    [47] = 47,
    [48] = 48,
    [49] = 49,
    [55] = 55,
    [56] = 56,
    [71] = 71,
    [72] = 72,
    [76] = 76,
    [78] = 78,
    [84] = 84,
    [87] = 87,
    [88] = 88,
    [89] = 89,
    [90] = 90,
    [91] = 91,
    [92] = 92,
    [94] = 94,
    [95] = 95,
    [96] = 96,
    [104] = 104,
    [106] = 106,
    [111] = 111,
    [128] = 128,
    [154] = 154,
    [155] = 155,
    [190] = 190,
    [191] = 191,
    [192] = 192,
    [193] = 193,
    [198] = 198,
    [199] = 199,
    [215] = 215,
    [216] = 216,
    [217] = 217,
    [218] = 218,
    [219] = 219,
    [220] = 220,
    [233] = 233,
    [246] = 246,
    [247] = 247,
    [307] = 307,
    [308] = 308,
    [313] = 313,
    [315] = 315,
    [316] = 316,
    [325] = 325,
    [328] = 328,
    [337] = 337,
    [338] = 338,
    [346] = 346,
    [347] = 347,
    [348] = 348,
    [349] = 349,
    [356] = 356,
    [410] = 410,
    [411] = 411,
    [428] = 428,
    [443] = 443,
    [444] = 444,
    [445] = 445,
    [446] = 446,
    [514] = 514,
    [516] = 516,
    [517] = 517,
    [518] = 518,
    [523] = 523,
    [524] = 524,
    [525] = 525,
    [547] = 547,
    [561] = 561,
    [568] = 568,
    [569] = 569,
    [574] = 574,
    [575] = 575,
    [579] = 579,
    [580] = 580,
    [581] = 581,
    [649] = 649,
    [660] = 660,
    [661] = 661,
    [662] = 662,
    [665] = 665,
    [666] = 666,
    [700] = 700,
    [701] = 701,
    [717] = 717
}

local aftermath_weaponskills = {
    ['Gastraphetes'] = {ws = 'Trueflight', tp = 3000, buff = 272},
    ['Death Penalty'] = {ws = 'Leaden Salute', tp = 3000, buff = 272},
    ['Armageddon'] = {ws = 'Wildfire', tp = 3000, buff = 272},
    ['Gandiva'] = {ws = 'Jishnu\'s Radiance', tp = 3000, buff = 272},
    ['Annihilator'] = {ws = 'Coronach', tp = 1000, buff = 273},
    ['Yoichinoyumi'] = {ws = 'Namas Arrow', tp = 1000, buff = 273}
}

function string.titlecase(str)
    return str:gsub("(%a)([%w_']*)",
                    function(f, r) return f:upper() .. r:lower() end)
end

local function load_profile(name, set_to_default)
    local profile = settings.profiles[name]
    for k, v in pairs(profile.cooldowns) do
        cooldowns[("/%s"):format(k)] = v
        timeouts[("/%s"):format(k)] = v + 1
    end
    weaponskill:set(profile.weaponskill)
    mode = profile.mode
    if set_to_default then
        settings.default = name
        settings:save('all')
    end
end

local function save_profile(name)
    local profile = {}
    profile.cooldowns = {}
    for k, v in pairs(cooldowns) do profile.cooldowns[k:sub(2)] = v end
    profile.weaponskill = weaponskill.value
    profile.mode = mode
    settings.profiles[name] = profile
    settings.default = name
    settings:save('all')
end

local function able_to_use_action()
    if pending.type == 'Corsair Shot' then
        return windower.ffxi.get_ability_recasts()[res.job_abilities[pending.id]
                   .recast_id] <= 60
    elseif pending.action_type == 'Ability' then
        return windower.ffxi.get_ability_recasts()[res.job_abilities[pending.id]
                   .recast_id] == 0
    elseif pending.action_type == 'Magic' then
        return windower.ffxi.get_spell_recasts()[res.spells[pending.id]
                   .recast_id] == 0
    end
    return true
end

local function set_timeout(cb, delay)
    local run = true
    coroutine.schedule(function() if run then cb() end end, delay)

    return function() run = false end
end

local function handle_interrupt() -- called when spell completes or is interrupted
    clear_timeout()
    completion = true
    windower.send_command(('@wait %f;gs rh process'):format(cooldown))
end

local function able_to_use_weaponskill()
    return windower.ffxi.get_player().vitals.tp >= 1000
end

local function action_timeout()
    if pending then
        local t = windower.ffxi.get_mob_by_id(pending.target) -- !
        if t and bit.band(t.id, 0xFF000000) then
            handle_interrupt()
        else
            windower.add_to_chat(200,
                                 "Rnghelper : Lockup detected, autoclearing queue")
            target = nil
            windower.send_command('autoface clear')
            pending = nil
            completion = false
            queue:clear()
        end
    end
end

local function execute_pending_action()
    cooldown = cooldowns[pending.prefix]
    clear_timeout()
    clear_timeout = set_timeout(action_timeout, timeouts[pending.prefix])
    windower.send_command('autoface ' .. pending.target)
    if pending.prefix == '/range' then
        windower.chat.input(windower.to_shift_jis(
                                ("%s %d"):format(pending.prefix, pending.target)))
    else
        windower.chat.input(windower.to_shift_jis(
                                ("%s \"%s\" %d"):format(pending.prefix,
                                                        pending.english,
                                                        pending.target)))
        -- else
        --     windower.chat.input(windower.to_shift_jis(
        --                             ("%s \"%s\" %d"):format(pending.prefix,
        --                                                     pending.name,
        --                                                     pending.target)))
    end
end

local process_queue

local function process_pending_action() -- Called only by processqueue
    if pending.prefix == '/weaponskill' then
        if not able_to_use_weaponskill() then -- if we queue a WS, but don't have TP, it does an RA
            queue:insert(1, pending) -- then tries to WS again.  Will repeat until we have TP
            pending = {
                prefix = '/range',
                name = 'Ranged',
                target = pending.target
            }
            windower.send_command('autoface ' .. target)
        end
        execute_pending_action()
    elseif not able_to_use_action() then
        windower.add_to_chat(200,
                             ("Rnghelper : Aborting %s - Ability not ready."):format(
                                 pending.name))
        completion = true
        process_queue() -- sets pending to nil,  then sets pending to the next item in queue
    else -- if the queue is empty, will try to WS or RA the target.  This function is run again on the new action, until an action is executed, and the recursion is broken
        execute_pending_action()
    end
end

local function buff_active(id)
    local player = windower.ffxi.get_player()
    for k, v in pairs(player.buffs) do
        if (v == id) then -- check for buff
            return true
        end
    end
    return false
end

process_queue = function()
    if completion then
        pending = nil
        completion = false
    end
    if pending then
    elseif not queue:empty() then
        pending = queue:pop()
    elseif target then
        local w = aftermath_weaponskills[player.equipment.range]
        local p = windower.ffxi.get_player()
        if weaponskill.value ~= '' and able_to_use_weaponskill() and p.vitals.tp >=
            ws_tp.value and
            (not use_aftermath.value or not w or buff_active(w.buff)) then
            pending = {
                ['prefix'] = '/weaponskill',
                ['name'] = weaponskill.value,
                ['english'] = weaponskill.value,
                ['target'] = target,
                ['action_type'] = 'Ability'
            }
        elseif use_aftermath.value and w and p.vitals.tp >= w.tp and not buff_active(w.buff) then
            pending = {
                ['prefix'] = '/weaponskill',
                ['name'] = w.ws,
                ['english'] = w.ws,
                ['target'] = target,
                ['action_type'] = 'Ability'
            }
        elseif not stop_on_tp.value or p.vitals.tp < ws_tp.value then
            pending = {
                ['prefix'] = '/range',
                ['name'] = 'Ranged',
                ['target'] = target,
                ['action_type'] = 'Ranged Attack'
            }
        end
    end
    if pending then process_pending_action() end
end

local function add_spell_to_queue(spell)
    queue:push({
        prefix = spell.prefix,
        name = spell.name,
        english = spell.english,
        target = spell.target.id,
        id = spell.id,
        action_type = spell.action_type
    })
end

events.pretarget:register(function(spell)
    if not (pending and pending.prefix == spell.prefix and pending.name ==
        spell.name and pending.target == spell.target.id ) and enabled.value then
        cancel_spell()
        if pending then
            if spell.name == 'Ranged' and spell.target.id then
                target = spell.target.id
                completion = true
                windower.send_command('autoface ' .. target)
                process_queue()
            else
                add_spell_to_queue(spell)
            end
        else
            add_spell_to_queue(spell)
            process_queue()
        end
    end
end)

local function monitor_target(id, data, modified, injected, blocked)
    if (id == 0xe) and target then
        local p = packets.parse('incoming', data)
        if (p.NPC == target) and ((p.Mask % 8) > 3) then
            if not (p['HP %'] > 0) then
                target = nil
                windower.send_command('autoface clear')
                pending = nil
                completion = false
                queue:clear()
                clear_timeout()
            end
        end
    end
end

local function handle_incoming_action_packet(id, data, modified, injected,
                                             blocked)
    if id == 0x28 and enabled then
        local p = packets.parse('incoming', data)
        if (p.Actor == player_id) and action_events[p.Category] then
            if action_interrupted[p['Target 1 Action 1 Message']] then
                handle_interrupt()
            elseif p.Param == 28787 then
            elseif terminal_action_events[p.Category] then
                handle_interrupt()
            end
        end
    end
end

local function handle_incoming_action_message_packet(id, data, modified,
                                                     injected, blocked)
    if id == 0x29 and enabled then
        local p = packets.parse('incoming', data)
        if (p.Actor == player_id) then
            if action_message_interrupted[p.Message] then
                handle_interrupt()
            elseif action_message_unable[p.Message] then
                windower.send_command('@wait 0;gs rh process')
            end
        end
    end
end

local function handle_outgoing_action_packet(id, data, modified, injected,
                                             blocked)
    if id == 0x1a and enabled then
        local p = packets.parse('outgoing', data)
        if p.Category == 16 then
            target = p.Target
            cooldown = cooldowns['/range']
            clear_timeout = set_timeout(action_timeout, timeouts['/range'])
        end
    end
end

local ws_shortcuts = {
    ['lead'] = 'Leaden Salute',
    ['true'] = 'Trueflight',
    ['wild'] = 'Wildfire',
    ['last'] = 'Last Stand',
    ['hot'] = 'Hot Shot',
    ['jis'] = "Jishnu's Radiance"
}

local function resolve_shortcuts(str)
    for k, v in pairs(ws_shortcuts) do if str:startswith(k) then return v end end
end

register_unhandled_command(function(...)
    local args = T {...}
    if args[1] and args[1]:lower() == 'rh' then
        args:remove(1) -- remove 'rh'
        local cmd = args[1]:lower()
        args:remove(1) -- remove cmd
        if cmd then
            if cmd == 'process' then
                process_queue()
            elseif cmd == 'set' then
                if args[1] then
                    for i, v in pairs(args) do
                        args[i] = windower.convert_auto_trans(args[i])
                    end
                    weaponskill:set(resolve_shortcuts(args[1]:lower()) or
                                        table.concat(args, " "):titlecase())
                    windower.add_to_chat(200,
                                         ("Rnghelper : Setting weaponskill to %s"):format(
                                             weaponskill.value))
                else
                    windower.add_to_chat(200,
                                         "Rnghelper : Clearing weaponskill.")
                    weaponskill:set('')
                end
            elseif cmd == 'print' then
                if pending then
                    windower.add_to_chat(200, pending.prefix .. pending.name ..
                                             pending.target)
                end
                for k, v in pairs(queue.data) do
                    windower.add_to_chat(200,
                                         k .. v.prefix .. v.english .. v.target)
                end
            elseif cmd == 'save' then
                save_profile(args[1])
            elseif cmd == 'load' then
                load_profile(args[1], true)
            elseif cmd == 'clear' then
                windower.add_to_chat(200, "Rnghelper : Clearing queue")
                target = nil
                windower.send_command('autoface clear')
                pending = nil
                completion = false
                clear_timeout()
                queue:clear()
            elseif cmd == 'tp' then
                if type(tonumber(args[1])) ~= 'number' then
                    windower.add_to_chat(200, "Rnghelper : Invalid argument")
                elseif tonumber(args[1]) >= 1000 and tonumber(args[1]) <= 3000 then
                    ws_tp:set(tonumber(args[1]))
                    windower.add_to_chat(200,
                                         ("Rnghelper : Auto weaponskill at %d TP"):format(
                                             ws_tp.value))
                else
                    windower.add_to_chat(200,
                                         "Rnghelper : Argument out of bounds")
                end
            elseif T {'enable', 'on', 'start'}:contains(cmd) then
                if enabled.value then
                    windower.add_to_chat(200, "Rnghelper : Already enabled")
                else
                    windower.add_to_chat(200, "Rnghelper : Enabling")
                    enabled:set()
                end
            elseif T {'disable', 'off', 'stop'}:contains(cmd) then -- changed to clear queue as well
                if not enabled.value then
                    windower.add_to_chat(200, "Rnghelper : Already disabled")
                else
                    windower.add_to_chat(200, "Rnghelper : Disabling")
                    target = nil
                    windower.send_command('autoface clear')
                    pending = nil
                    completion = false
                    clear_timeout()
                    queue:clear()
                    enabled:unset()
                end
            elseif cmd:startswith('am') then
                if args[1] then
                    if T {'enable', 'on', 'true'}:contains(args[1]:lower()) then
                        windower.add_to_chat(200,
                                             "Rnghelper : Use Aftermath Enabled")
                        use_aftermath:set()
                    elseif T {'disable', 'off', 'false'}:contains(
                        args[1]:lower()) then
                        windower.add_to_chat(200,
                                             "Rnghelper : Use Aftermath Disabled")
                        use_aftermath:unset()
                    end
                end
            elseif cmd == 'stopontp' then
                if T {'true', 'on', 'enable', 'yes'}:contains(args[1]:lower()) then
                    windower.add_to_chat(200, "Rnghelper : Stop on TP enabled")
                    stop_on_tp:set()
                elseif T {'false', 'off', 'disable', 'no'}:contains(
                    args[1]:lower()) then
                    windower.add_to_chat(200, "Rnghelper : Stop on TP disabled")
                    stop_on_tp:unset()
                end
            end
        end
        return true
    end
    return false
end)

load_profile(settings.default)
windower.raw_register_event('incoming chunk', handle_incoming_action_packet)
windower.raw_register_event('incoming chunk',
                            handle_incoming_action_message_packet)
windower.raw_register_event('outgoing chunk', handle_outgoing_action_packet)
windower.raw_register_event('incoming chunk', monitor_target)

return {
    weaponskill = weaponskill,
    enabled = enabled,
    use_aftermath = use_aftermath,
    ws_tp = ws_tp,
    stop_on_tp = stop_on_tp
}
