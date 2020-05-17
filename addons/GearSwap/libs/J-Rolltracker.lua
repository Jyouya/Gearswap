res = require('Resources')
local packets = require('packets')
local events = require('J-Swap-Events')
local roll_info

local actions = res.job_abilities:filter(
                    function(el)
        return el.type == 'CorsairRoll' or el.en == 'Double-Up'
    end)
local player_id = windower.ffxi.get_player().id
local player_job = windower.ffxi.get_player().main_job

local rolls = T {}
local party = T {[player_id] = {main_job = player_job}}
local settings = {default_bonus = 7, player_bonuses = T {Qultada = 0}}

local party_index = {'p0', 'p1', 'p2', 'p3', 'p4', 'p5'}
local my_job = windower.ffxi.get_player().main_job
local last_roll = T {}
windower.raw_register_event('action', function(act)
    if act.category == 6 then
        if actions[act.param] then
            if table.with(act.targets, 'id', player_id) then
                local en = actions[act.param].en
                local actor_id = act.actor_id
                if en ~= 'Double-Up' then
                    last_roll[actor_id] = en
                else
                    en = last_roll[actor_id]
                    if not en then return end
                end
                local roller_name = windower.ffxi.get_mob_by_id(actor_id).name
                local party_info = windower.ffxi.get_party()
                local party_jobs = S {my_job}
                print('before')
                for i = 0, party_info.party1_count - 1 do
                    local mob = party_info['p' .. i].mob
                    if mob and party[mob.id] and party[mob.id].main_job then
                        party_jobs:add(party[mob.id].main_job)
                    end
                end
                print('after')
                rolls[en] = {
                    job_bonus_active = party_jobs[roll_info[en].job], -- ! May error
                    roll_bonus = settings.player_bonus[roller_name] or
                        settings.default_bonus,
                    value = act.targets[1].actions[1].param,
                    crooked_cards = party[actor_id] and
                        party[actor_id].crooked_cards
                }
                if party[actor_id] then
                    party[actor_id].crooked_cards = false
                end
            end
        -- ! Crooked cards detection not working
        elseif act.category == 6 and act.param == 392 then
            local actor_id = act.actor_id
            party[actor_id] = party[actor_id] or {}
            party[actor_id].crooked_cards = true
        end
    end
end)

windower.raw_register_event('incoming chunk', function(id, data)
    if id ~= 0x0DD then return end
    local packet = packets.parse('incoming', data)
    party[packet.ID] = {main_job = packet['Main job']}
end)
windower.raw_register_event('zone change', function()
    party = T {[player_id] = {main_job = player_job}}
end)

local c = function(t)
    return setmetatable(t, {
        __add = function(t1, t2)
            local res = {}
            for i, v in ipairs(t1) do res[i] = t1[i] + t2[i] end
            return setmetatable(res, getmetatable(t1))
        end,
        __multiply = function(t1, t2)
            local res = {}
            for i, v in ipairs(t1) do res[i] = t1[i] * t2[i] end
            return setmetatable(res, getmetatable(t1))
        end
    })
end
roll_info = {
    default = {
        effect_values = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        bonus_multiplier = 0
    },
    ['Allies\' Roll'] = {
        effect_values = {6, 7, 17, 9, 11, 13, 15, 17, 17, 5, 17},
        bonus_multiplier = 1,
        job = nil,
        job_bonus = 0,
        gear_bonus = 5
    },
    ['Beast Roll'] = {
        effect_values = {64, 80, 96, 256, 112, 128, 160, 32, 176, 192, 320},
        bonus_multiplier = 32,
        job = 'bst',
        job_bonus = 100
    },
    ['Blitzer\'s Roll'] = {
        effect_values = {2, 3.4, 4.5, 11.3, 5.3, 6.4, 7.2, 8.3, 1.5, 10.2, 12.1},
        bonus_multiplier = 1,
        gear_bonus = 5
    },
    ['Bolter\'s Roll'] = {
        effect_values = {0.3, 0.3, 0.8, 0.4, 0.4, 0.5, 0.5, 0.6, 0.2, 0.7, 1.0},
        bonus_multiplier = 0.2
    },
    ['Caster\'s Roll'] = {
        effect_values = {6, 15, 7, 8, 9, 10, 5, 11, 12, 13, 20},
        bonus_multiplier = 3,
        gear_bonus = 10
    },
    ['Chaos Roll'] = {
        effect_values = {64, 80, 96, 256, 112, 128, 160, 32, 176, 192, 320},
        bonus_multiplier = 32,
        job = 'drk',
        job_bnus = 100
    }, -- /1024 Confirmed
    ['Choral Roll'] = {
        effect_values = {8, 42, 11, 15, 19, 4, 23, 27, 31, 35, 50},
        bonus_multiplier = 4,
        job = 'brd',
        job_bonus = 25
    }, -- SE listed Values and hell if I'm testing this
    ['Companion\'s Roll'] = {
        effect_values = {
            c {4, 20}, c {20, 50}, c {6, 20}, c {8, 20}, c {10, 30}, c {12, 30},
            c {14, 30}, c {16, 40}, c {18, 40}, c {3, 10}, c {25, 60}
        },
        bonus_multiplier = c {2, 5}
    },
    ['Corsair\'s Roll'] = {
        effect_values = {10, 11, 11, 12, 20, 13, 15, 16, 8, 17, 24},
        bonus_multiplier = 2,
        job = 'COR',
        job_bonus = 5
    },
    ['Dancer\'s Roll'] = {
        effect_values = {3, 4, 12, 5, 6, 7, 1, 8, 9, 10, 16},
        bonus_multiplier = 2,
        job = 'DNC',
        job_bonus = 4
    }, -- Confirmed
    ['Drachen Roll'] = {
        effect_values = {10, 13, 15, 40, 18, 20, 25, 5, 28, 30, 50},
        bonus_multiplier = 5,
        job = 'DRG',
        job_bonus = 15
    }, -- Confirmed
    ['Evoker\'s Roll'] = {
        effect_values = {1, 1, 1, 1, 3, 2, 2, 2, 1, 3, 4},
        bonus_multiplier = 1,
        job = 'SMN',
        job_bonus = 1
    }, -- Confirmed
    ['Fighter\'s Roll'] = {
        effect_values = {2, 2, 3, 4, 12, 5, 6, 7, 1, 9, 18},
        bonus_multiplier = 1,
        job = 'WAR',
        job_bonus = 5
    },
    ['Gallant\'s Roll'] = {
        effect_values = {48, 60, 200, 72, 88, 104, 32, 120, 140, 160, 240},
        bonus_multiplier = 24,
        job = 'PLD',
        job_bonus = 120
    }, -- /1024 Confirmed
    ['Healer\'s Roll'] = {
        effect_values = {3, 4, 12, 5, 6, 7, 1, 8, 9, 10, 16},
        bonus_multiplier = 1,
        job = 'WHM',
        job_bonus = 4
    }, -- Confirmed
    ['Hunter\'s Roll'] = {
        effect_values = {10, 13, 15, 40, 18, 20, 25, 5, 28, 30, 50},
        bonus_multiplier = 5,
        job = 'RNG',
        job_bonus = 15
    }, -- Confirmed
    ['Magus\'s Roll'] = {
        effect_values = {5, 20, 6, 8, 9, 3, 10, 13, 14, 15, 25},
        bonus_multiplier = 2,
        job = 'BLU',
        job_bonus = 8
    },
    ['Miser\'s Roll'] = {
        effect_values = {30, 50, 70, 90, 200, 110, 20, 130, 150, 170, 250},
        bonus_multiplier = 15
    },
    ['Monk\'s Roll'] = {
        effect_values = {8, 10, 32, 12, 14, 15, 4, 20, 22, 24, 40},
        bonus_multiplier = 4,
        job = 'MNK',
        job_bonus = 10
    },
    ['Naturalist\'s Roll'] = {
        effect_values = {6, 7, 15, 8, 9, 10, 5, 11, 12, 13, 20},
        bonus_multiplier = 1,
        job = 'GEO',
        job_bonus = 5
    }, -- Confirmed
    ['Ninja Roll'] = {
        effect_values = {10, 13, 15, 40, 18, 20, 25, 5, 28, 30, 50},
        bonus_multiplier = 5,
        job = 'NIN',
        job_bonus = 15
    }, -- Confirmed
    ['Puppet Roll'] = {
        effect_values = {5, 8, 35, 11, 14, 18, 2, 22, 26, 30, 40},
        bonus_multiplier = 3,
        job = 'PUP',
        job_bonus = 12
    },
    ['Rogue\'s Roll'] = {
        effect_values = {2, 2, 3, 4, 12, 5, 6, 6, 1, 8, 14},
        bonus_multiplier = 1,
        1,
        job = 'THF',
        job_bonus = 5
    },
    ['Runeist\'s Roll'] = {
        effect_values = {10, 13, 15, 40, 18, 20, 25, 5, 28, 30, 50},
        bonus_multiplier = 5,
        job = 'RUN',
        job_bonus = 15
    }, -- Needs Eval
    ['Samurai Roll'] = {
        effect_values = {8, 32, 10, 12, 14, 4, 16, 20, 22, 24, 40},
        bonus_multiplier = 4,
        job = 'SAM',
        job_bonus = 10
    }, -- Confirmed 1(Was bad),2,3,4,5,6,7,8,11 (I Wing Test)
    ['Scholar\'s Roll'] = {
        effect_values = {2, 10, 3, 4, 4, 1, 5, 6, 7, 7, 12},
        bonus_multiplier = 1,
        job = 'SCH',
        job_bonus = 3
    }, -- Needs Eval Source ATM: JP Wiki
    ['Tactician\'s Roll'] = {
        effect_values = {10, 10, 10, 10, 30, 10, 10, 0, 20, 20, 40},
        bonus_multiplier = 2,
        gear_bonus = 10
    }, -- Confirmed
    ['Warlock\'s Roll'] = {
        effect_values = {10, 13, 15, 40, 18, 20, 25, 5, 28, 30, 50},
        bonus_multiplier = 5,
        job = 'RDM',
        job_bonus = 15
    }, --
    ['Wizard\'s Roll'] = {
        effect_values = {4, 6, 8, 10, 25, 12, 14, 17, 2, 20, 30},
        bonus_multiplier = 2,
        job = 'BLM',
        job_bonus = 10
    }
}

roll_info = setmetatable(roll_info,
                         {__index = function(t, k) return t.default end})

return setmetatable(settings, {
    __index = function(t, roll_name)
        if not (buffactive[roll_name] and rolls[roll_name]) then
            return {value = 0, effect_value = 0}
        end
        local roll = rolls[roll_name]
        local roll_data = roll_info[roll_name]

        print('roll value: ', roll.value)
        print('roll bonus: ', roll.roll_bonus)
        print('bonus multiplier: ', roll_data.bonus_multiplier)
        print('gear bonus: ', roll_data.gear_bonus)
        print('job_bonus: ', roll.job_bonus_active and roll_data.job_bonus or 0)
        print('crooked cards: ', roll.crooked_cards)

        -- ! Crooked cards not detecting properly

        local effect = (roll_data.effect_values[roll.value] + roll.roll_bonus *
                           roll_data.bonus_multiplier +
                           (roll_data.gear_bonus or 0) +
                           (roll.job_bonus_active and roll_data.job_bonus or 0)) *
                           (1 + (roll.crooked_cards and 0.2 or 0))

        print('effect: ', effect)

        return {value = roll.value, effect_value = effect}
    end
})
