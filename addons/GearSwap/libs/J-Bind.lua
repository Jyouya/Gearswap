local events = require('J-Swap-Events')

_binds = _binds or {}

local function bind_key(key, command)
    if _binds[key] then error('Cannot attach multiple bindings to ' .. key) end
    if type(command) == 'string' then
        windower.send_command(('bind %s %s'):format(key, command))
    elseif type(command) == 'function' then
        windower.send_command(('bind %s gs _bind key'):format(key))
    end
    _binds[key] = command
end

register_unhandled_command(function(cmd, key)
    if cmd == '_bind' then if _binds[key] then _binds[key]() end end
end)

local function unbind_commands()
    for key, _ in pairs(_binds) do
        windower.send_command(('unbind %s'):format(key))
    end
end

events.file_unload:register(unbind_commands)

return bind_key
