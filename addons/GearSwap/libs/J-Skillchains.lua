
local packets = require('packets')
res = require('resources')
require('tables')

local resonating = T{}
windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then
        local packet = packets.parse('incoming', data)
        
    end
end)

local api = {
    resonating = function() 
        -- return T table of all the resonating skillchains
    end,
    duration = function()
        -- return the amount of time till the skillchain wears off
    end,
    -- Return eligibility for another skillchain?
}
return setmetatable({}, {__index = function(t, k) 
    return api[k] and api[k]()
end})