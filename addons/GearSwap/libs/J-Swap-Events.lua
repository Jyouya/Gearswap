local event = require('event')

_events = _events or {
    load = event.new(),
    pretarget = event.new(),
    precast = event.new(),
    midcast = event.new(),
    aftercast = event.new(),
    status_change = event.new(),
    pet_change = event.new(),
    pet_midcast = event.new(),
    pet_aftercast = event.new(),
    pet_status_change = event.new(),
    filtered_action = event.new(),
    sub_job_change = event.new(),
    buff_change = event.new(),
    buff_refresh = event.new(),
    party_buff_change = event.new(),
    indi_change = event.new(),
    file_unload = event.new(),
    update = event.new()
}

function get_sets() _events.load:trigger() end

function pretarget(spell) _events.pretarget:trigger(spell) end

function precast(spell, action) _events.precast:trigger(spell, action) end

function midcast(spell) _events.midcast:trigger(spell) end

function aftercast(spell) _events.aftercast:trigger(spell) end

function status_change(new, old) _events.status_change:trigger(new, old) end

function pet_change(pet, gain) _events.pet_change:trigger(pet, gain) end

function pet_midcast(spell) _events.pet_midcast:trigger(spell) end

function pet_aftercast(spell) _events.pet_aftercast:trigger(spell) end

function pet_status_change(new, old) _events.pet_status_change:trigger(new, old) end

function filtered_action(spell) _events.filtered_action:trigger(spell) end

function sub_job_change(new, old) _events.sub_job_change:trigger(new, old) end

function buff_change(new, gain, buff_details)
    _events.buff_change:trigger(new, gain, buff_details)
end

function buff_refresh(name, buff_details)
    _events.buff_refresh:trigger(name, buff_details)
end

function party_buff_change(member, name, gain, buff)
    _events.party_buff_change:trigger(member, name, gain, buff)
end

function indi_change(indi_table, gain)
    _events.indi_change:trigger(indi_table, gain)
end

return _events
