res = require('resources')
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
    local function hachirin_bonus_tier(spell)
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

    local function elemental_bonus_tier(spell)
        local spell_element = spell and spell.element
        local bonus = 0
        if world.weather_element == spell_element then
            bonus = res.weather[world.weather_id].intensity
        end

        if world.day_element == spell.element then bonus = bonus + 1 end
        return bonus
    end

    function predicate_factory.hachirin_bonus(level)
        level = level or 1
        return function(spell) return hachirin_bonus_tier(spell) >= level end
    end

    function predicate_factory.hachirin(spell)
        local bonus = hachirin_bonus_tier(spell)
        return bonus >= 2 or (bonus > 0 and spell.target.distance > 7)
    end

    function predicate_factory.orpheus(spell)
        return hachirin_bonus_tier(spell) < 2 and spell.target.distance <= 7
    end

    function predicate_factory.elemental_obi_bonus(level)
        level = level or 1
        return function(spell)
            return elemental_bonus_tier(spell) >= level
        end
    end

    function predicate_factory.orpheus_ele(spell)
        return elemental_bonus_tier(spell) < 2 and spell.target.distance <= 7
    end

    function predicate_factory.elemental_obi(spell)
        local bonus = elemental_bonus_tier(spell)
        return bonus >= 2 or (bonus > 0 and spell.target.distance > 7)
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

function predicate_factory.hpp_lt(value)
    return function() return player.hpp < value end
end

function predicate_factory.hpp_lte(value)
    return function() return player.hpp <= value end
end

function predicate_factory.hpp_gt(value)
    return function() return player.hpp > value end
end

function predicate_factory.hpp_gte(value)
    return function() return player.hpp >= value end
end

function predicate_factory.hp_lt(value)
    return function() return player.hp < value end
end

function predicate_factory.hp_lte(value)
    return function() return player.hp <= value end
end

function predicate_factory.hp_gt(value)
    return function() return player.hp > value end
end

function predicate_factory.hp_gte(value)
    return function() return player.hp >= value end
end

function predicate_factory.mpp_lt(value)
    return function() return player.mpp < value end
end

function predicate_factory.mpp_lte(value)
    return function() return player.mpp <= value end
end

function predicate_factory.mpp_gt(value)
    return function() return player.mpp > value end
end

function predicate_factory.mpp_gte(value)
    return function() return player.mpp >= value end
end

function predicate_factory.mp_lt(value)
    return function() return player.mp < value end
end

function predicate_factory.mp_lte(value)
    return function() return player.mp <= value end
end

function predicate_factory.mp_gt(value)
    return function() return player.mp > value end
end

function predicate_factory.mp_gte(value)
    return function() return player.mp >= value end
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

            if buffactive['TP Bonus'] then etp = etp + 250 end

            return etp > tp
        end
    end
end

do
    local impetus_count = 0
    local function bind_action()
        local impetus_active = buffactive.Impetus
        local player_id = windower.ffxi.get_player().id
        if player.main_job == 'MNK' then
            events.buff_change:register(function(buff, gain, buff_info)
                if buff == 'Impetus' then
                    impetus_active = gain
                    impetus_count = 0
                end
            end)
        end

        -- TODO: Feather step tracking
        windower.raw_register_event('action', function(act)
            if impetus_active and act.actor_id == player_id then
                if act.category == 1 or act.category == 3 then -- Melee Attack/WS
                    for _, action in ipairs(act.targets[1].actions) do
                        if action.reaction == 8 then
                            impetus_count = impetus_count + 1
                        else
                            impetus_count = 0
                        end
                    end
                end
            end
        end)
        return true
    end
    local crit_action_handler = false
    local job_bonus = 0
    local merit_bonus
    do
        merit_bonus = player.merits.critical_hit_rate
        local player = windower.ffxi.get_player()
        if player.main_job == 'WAR' then
            local jp_total = 0
            for k, v in pairs(player.job_points.war) do
                jp_total = jp_total + v
            end
            if jp_total >= 1200 then
                job_bonus = 10
            elseif jp_total >= 100 then
                job_bonus = 5
            end
        end
    end
    function predicate_factory.crit_bonus_gt(n)
        -- Requireing this here so it doesn't load if it's never used
        rolls = rolls or require('J-Rolltracker')
        -- We only want to start the event handler if the function is called
        crit_action_handler = crit_action_handler or bind_action()
        return function(spell)
            local bonus = 0
            if buffactive['Mighty Strikes'] then bonus = bonus + 100 end
            if player.equipment.main == 'Shining One' then
                bonus = bonus + player.tp / 200
            end
            if buffactive['Blood Rage'] then bonus = bonus + 40 end
            -- TODO: Add featherstep based on spell.target
            if player.main_job == 'WAR' then
                bonus = bonus + job_bonus
            end
            bonus = bonus + merit_bonus

            bonus = bonus + rolls['Rogue\'s Roll'].effect_value

            bonus = bonus + impetus_count
            return bonus > n
        end
    end
end

return predicate_factory
