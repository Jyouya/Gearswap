_addon.name = 'Autoface'
_addon.version = '1'
_addon.author = 'Jyouya'
_addon.commands = {'autoface'}

require('Modes')
require('GUI')
local bit = require('bit')
local coroutine = require('coroutine')

local enabled = M(true, 'Auto Face Target')
local target = nil

local function face_target()
    if not enabled.value then return end
    local t = target and windower.ffxi.get_mob_by_id(target) or
                  windower.ffxi.get_mob_by_target('t')
    if t and bit.band(t.id, 0xFF000000) ~= 0 then
        local player = windower.ffxi.get_mob_by_target('me')
        local heading = - math.atan2(t.y - player.y, t.x - player.x)
        -- print(player.x, player.y, t.x, t.y, heading)
        windower.ffxi.turn(heading)
    end

    coroutine.schedule(face_target, .1)
end

windower.register_event('addon command', function(arg)
    print(arg)
    if arg == 'on' then
        enabled:set()
        face_target()
    elseif arg == 'off' then
        enabled:unset()
    elseif arg == 'clear' then
        target = nil
    elseif windower.ffxi.get_mob_by_id(arg) then
        target = arg
    end
end)

ToggleButton ({
    x = 800,
    y = 800,
    var = enabled,
    iconUp = 'AutofaceOff.png',
    iconDown = 'AutofaceOn.png'
}):draw()

face_target()
