local res = require('resources')
require('strings')
local events = require('J-Swap-Events')
local bit = require('bit')
local packets = require('packets')

local predicate_factory = {}

function predicate_factory.distance_gt(dist)
    return function(spell) return spell.target.distance > dist end
end

function predicate_factory.distance_gte(dist)
    return function(spell) return spell.target.distance >= dist end
end

function predicate_factory.distance_lt(dist)
    return function(spell) return spell.target.distance < dist end
end

function predicate_factory.distance_lte(dist)
    return function(spell) return spell.target.distance <= dist end
end

do
    local opposing_element = {
        Fire = "Water",
        Ice = "Fire",
        Wind = "Ice",
        Earth = "Wind",
        Thunder = "Earth",
        Water = "Thunder",
        Light = "Dark",
        Dark = "Light"
    }
    local function bonus_tier(spell)
        local spell_element = spell and spell.element
        local bonus = 0

        if world.weather_element == spell_element then
            bonus = res.weather[world.weather_id].intensity
        elseif world.weather_element == opposing_element[spell_element] then
            bonus = -res.weather[world.weather_id].intensity
        end

        if world.day_element == spell_element then
            bonus = bonus + 1
        elseif world.day_element == opposing_element[spell_element] then
            bonus = bonus - 1
        end
        return bonus
    end

    function predicate_factory.weather_day_bonus(level)
        level = level or 1
        return function(spell) return bonus_tier(spell) >= level end
    end

    function predicate_factory.hachirin(spell)
        local bonus = bonus_tier(spell)
        return bonus >= 2 or (bonus > 0 and spell.target.distance > 7)
    end

    function predicate_factory.orpheus(spell)
        return bonus_tier() < 2 and spell.target.distance <= 7
    end
end

function predicate_factory.tp_gte(tp)
    return function() return player.tp >= tp end
end

function predicate_factory.time_between(start_time, end_time)
    if end_time < start_time then
        return function()
            local time = world.time
            return time <= end_time or time >= start_time
        end
    else
        return function()
            local time = world.time
            return time >= start_time and time <= end_time
        end
    end
end

function predicate_factory.buff_active(...)
    local n = select('#', ...)

    if n == 0 then
        error('buff_active requires at least one buff name')
    elseif n == 1 then
        local buff = select(1, ...)
        return function() return buffactive[buff] end
    else
        local buffs = {...}
        return function()
            for _, buff in ipairs(buffs) do
                if not buffactive[buff] then return false end
            end
            return true
        end
    end
end

function predicate_factory.equipped(slot, item_name)
    return function()
        local equipped = settings[slot] and settings[slot].value or
                             player.equipment[slot]
        return equipped == item_name
    end
end

function predicate_factory.p_and(...)
    local args = {...}
    return function()
        for _, fn in ipairs(args) do if not fn() then return false end end
        return true
    end
end

function predicate_factory.p_or(...)
    local args = {...}
    return function()
        for _, fn in ipairs(args) do if fn() then return true end end
        return false
    end
end

do
    local aeonic_weapons = S {
        "God Hands", "Aeneas", "Sequence", "Lionheart", "Ruinator", "Chango",
        "Anguta", "Trishula", "Heishi Shorinken", "Dojikiri Yasutsuna",
        "Tishtrya", "Khatvanga", "Fail-Not", "Fomalhaut"
    }

    local magian_weapons = S {
        "Barracudas +2", "Sphyras", "Fusetto +2", "Centovente", "Machaera +2",
        "Thibron", "Kalavejs +2", "Kauriraris", "Renaud's Axe +2", "Fernagu",
        "Sumeru +2", "Tavatimsa", "Reckoning +2", "Basanizo", "Stingray +2",
        "Sixgill", "Uzura +2", "Hitaki", "Keitonotachi +2", "Kantonotachi",
        "Makhila +2", "Ukaldi", "Sedikutchi +2", "Muruga", "Sparrowhawk +1",
        "Accipiter", "Anarchy +2", "Ataktos"
    }

    local warcry_source = 0
    local is_target = function(targets)
        local player_id = windower.ffxi.get_player().id
        for _, target in ipairs(targets) do
            if target.id == player_id then return true end
        end
    end
    windower.raw_register_event('action', function(act)
        if act.category == 6 and act.param == 32 then
            if is_target(act.targets) then
                warcry_source = act.actor_id
            end
        end
    end)
    local member_jobs = {}
    windower.raw_register_event('incoming chunk', function(id, data)
        if id ~= 0x0DD then return end
        local packet = packets.parse('incoming', data)
        member_jobs[packet.ID] = packet['Main job']
    end)

    local job_fencer = 0
    local jp_tp_bonus = 0
    local function calculate_job_fencer()
        if player.main_job == 'WAR' then
            job_fencer = 5
            jp_tp_bonus = 230
        elseif player.main_job == 'BST' then
            job_fencer = 3
            jp_tp_bonus = 230
        elseif player.main_job == 'BRD' then
            job_fencer = 2
            jp_tp_bonus = 0
        elseif player.sub_job == 'WAR' then
            job_fencer = 1
            jp_tp_bonus = 0
        else
            job_fencer = 0
            jp_tp_bonus = 0
        end
    end
    events.load:register(calculate_job_fencer)
    events.sub_job_change:register(calculate_job_fencer)
    local fencer_tp_bonus = {[0] = 0, 200, 300, 400, 450, 500, 550, 600, 630}
    function predicate_factory.etp_gt(tp, gear_fencer)
        gear_fencer = gear_fencer or 0
        return function(spell)
            local etp = player.tp
            local main = settings.main and settings.main.value or
                             player.equipment.main
            local sub = settings.sub and settings.sub.value or
                            player.equipment.sub
            local range = settings.range and settings.range.value or
                              player.equipment.range

            if spell.skill == 'Marksmanship' or spell.skill == 'Archery' then
                if aeonic_weapons[player.equipment.range] then
                    etp = etp + 500
                end
            elseif aeonic_weapons[player.equipment.main] then
                etp = etp + 500
            end
            if magian_weapons[main] or magian_weapons[range] or
                magian_weapons[sub] then etp = etp + 1000 end

            if buffactive.Warcry then
                if warcry_source == player.id and player.main_job == 'WAR' then
                    etp = etp + 500
                else
                    for _, member in ipairs(party) do
                        if member.mob.id == warcry_source then
                            if member_jobs[member.mob.id] == 1 then -- Warrior
                                etp = etp + 250
                                break
                            end
                        end
                    end
                end
            end
            -- if player is single wielding a 1h weapon
            local main = res.items[player.equipment.main]
            if main and bit.band(main.slot, 2) == 0 then
                local sub = res.items[player.equipment.sub]
                if not sub or sub and sub.slot == 2 then
                    etp = etp +
                              fencer_tp_bonus[math.min(job_fencer + gear_fencer,
                                                       8)] + jp_tp_bonus
                end
            end

            return etp > tp
        end
    end
end

return predicate_factory
