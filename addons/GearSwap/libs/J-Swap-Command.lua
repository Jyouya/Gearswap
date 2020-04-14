require('string')

local command = {}
_commands = _commands or setmetatable({}, {__index = command})

function command:register(command, cb, arg_string)
    local arg_count = arg_string and #arg_string:split(' ') or 0
    local handler
    if arg_count > 0 then
        handler = function(raw_args)
            local args = raw_args:split(' ', arg_count)
            cb(unpack(args))
        end
    else
        handler = cb
    end

    self[command:lower()] = handler
    -- for k, v in pairs(_commands) do print(k, v) end
end

function self_command(command)
    -- for k, v in pairs(_commands) do print(k, v) end
    local cmd = command:split(' ', 2):map(string.lower)
    if rawget(_commands, cmd[1]) then _commands[cmd[1]:lower()](cmd[2]) end
end

return _commands

