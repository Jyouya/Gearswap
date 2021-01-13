require('J-Swap')
local M = require('J-Mode')
require('GUI')
local command = require('J-Swap-Command')
local events = require('J-Swap-Events')
local bind_key = require('J-Bind')
-- rolls = rolls or require('J-Rolltracker')
local haste = require('J-Haste')
local pred_factory = require('J-Predicates')

local gear = require('Pokecenter-gear')

spell_map = spell_map:update(require('RDM-Map'))

-- TODO Keybinds go here
-- ex: bind_key('numpad0', 'input /ra <t>')

settings.main = M {
    ['description'] = 'Main Hand',
    gear.CroceaMors.PathC,
    'Murgleis',
    'Naegling',
    'Almace',
    'Maxentius',
    'Esikuva'
}

local subs = T {
    'Daybreak', 'Thibron', 'Almace', 'Tauret', 'Ternion Dagger +1', 'Vampirism',
    'Aern Dagger', 'Ammurapi Shield', 'Genmei Shield', gear.CroceaMors.PathC
}

local item_id_memo = setmetatable({}, {
    __index = function(t, k)
        t[k] = res.items:with('en', k).id
        return t[k]
    end
})
local function item_type(item)
    local item_table = res.items[item_id_memo[type(item) == 'table' and
                           item.name or item]]
    local item_slots = item_table.slots
    if item_table.skill == 1 then
        return 'h2h'
    elseif item_slots:contains(0) and item_slots:contains(1) then
        return '1h'
    elseif item_slots:contains(0) and not item_slots:contains(1) then
        return '2h'
    elseif item_slots:contains(1) and not item_slots:contains(0) then
        return item_table.type == 5 and 'shield' or 'grip'
    end
end

local function pack_sub()
    local final_subs
    if player.sub_job == 'NIN' or player.sub_job == 'DNC' then
        final_subs = subs
    else
        final_subs = T {}
        for _, item in ipairs(subs) do
            if item_type(item) == 'shield' then
                final_subs:append(item)
            end
        end
    end
    settings.sub = M {['description'] = 'Off Hand', final_subs:unpack()}
end

pack_sub()
events.sub_job_change:register(pack_sub)

local function update_if_not_midaction()
    if not midaction() then windower.send_command('gs c update') end
end

settings.ullr = M(false, 'Use Ullr')

settings.main.on_change:register(update_if_not_midaction)
settings.sub.on_change:register(update_if_not_midaction)
settings.ullr.on_change:register(update_if_not_midaction)

-- settings.magic_burst = M(false, 'Magic Burst Override')

settings.engaged = M {
    ['description'] = 'Engaged Mode',
    'Normal',
    'Enspell',
    'Subtle Blow'
}
settings.engaged.on_change:register(update_if_not_midaction)

settings.WeaponSkill = M {'Normal', 'Subtle Blow'}
settings.engaged.on_change:register(function(m)
    if m.value == 'Subtle Blow' then
        settings.WeaponSkill:set('Subtle Blow')
    elseif settings.WeaponSkill.value == 'Subtle Blow' then
        settings.WeaponSkill:set('Normal')
    end
end)

settings.magic_burst = M {
    ['description'] = 'Magic Burst Mode',
    'Auto',
    'Always',
    'Never'
}

-- potency for spells that have scalable effects, duration for spells with flat effects
settings.enfeebling = M {
    ['description'] = 'Enfeebling Mode',
    'Potency/Duration',
    'Accuracy'
}

rules.midcast:append({
    test = function(equip_set, spell) return spell.skill == 'Enfeebling Magic' end,
    key = function() return settings.enfeebling.value end
})

settings.dual_wield_mode = M {
    ['description'] = 'Dual Wield Mode',
    'Auto',
    'Manual'
}
settings.dual_wield_level = M {
    ['description'] = 'Dual Wield Level',
    '11',
    '21',
    '31'
}

do -- Dual Wield rule
    local function dw_test()
        return (player.sub_job == 'NIN' or player.sub_job == 'DNC')

    end
    local function dw_level()
        if settings.dual_wield_mode.value == 'Auto' then
            local dw_needed = haste.dw_needed
            local dw_level = math.max(unpack(settings.dual_wield_level))
            for _, dw in ipairs(settings.dual_wield_level) do
                local dw_number = tonumber(dw)
                if dw_number < dw_level and dw_number >= dw_needed then
                    dw_level = dw_number
                end
            end
            settings.dual_wield_level:set(tostring(dw_level))
        end
        return 'DW' .. tostring(settings.dual_wield_level.value)
    end
    rules.engaged:append({test = dw_test, key = dw_level})
    rules.idle:append({test = dw_test, key = dw_level})
end

local lock_ammo = {
    test = function(equip_set)
        if settings.ullr.value then
            if player.tp > 500 or buffactive['Aftermath: Lv.3'] then
                equip_set.ammo = 'Empty'
            end
        end
    end
}

rules.precast:append(lock_ammo)
rules.midcast:append(lock_ammo)
rules.idle:append(lock_ammo)
rules.engaged:append(lock_ammo)

rules.midcast:append({
    test = function(_, spell) return spell.target.type == 'SELF' end,
    key = 'Self'
})

local always_swap = function() return true end
local swap_if_low_tp = function()
    return player.tp < 400 and not buffactive['Aftermath: Lv.3']
end
local can_dw = function()
    return player.sub_job == 'NIN' or player.sub_job == 'DNC'
end
local composure = function(spell) -- !
    return buffactive['Composure'] and spell.target.type ~= 'SELF'
end
local saboteur = pred_factory.buff_active('Saboteur')

events.load:register(function()
    sets.idle = {
        ammo = 'Homiliary',
        head = 'Vitiation Chapeau +3',
        body = 'Shamash Robe',
        hands = 'Malignance Gloves',
        legs = 'Malignance Tights',
        feet = 'Malignance Boots',
        neck = 'Loricate Torque +1',
        waist = 'Flume Belt +1',
        ear1 = 'Odnowa Earring +1',
        ear2 = 'Etiolation Earring',
        ring1 = 'Gelatinous Ring +1',
        ring2 = gear.StikiniRing2,
        back = gear.Sucello.Cure
    }

    sets.JA.Convert = set_combine(sets.idle, {main = 'Murgleis'})

    sets.JA.Chainspell = set_combine(sets.idle, {body = 'Vitiation Tabard +3'})

    sets.JA.Saboteur = set_combine(sets.idle, {hands = 'Leth. Gantherots +1'})

    sets.precast = { -- 38
        ammo = 'Impatiens',
        head = 'Vitiation Chapeau +3', -- 16 - 54
        body = 'Vitiation Tabard +3', -- 15 - 69
        waist = 'Witful Belt',
        ear1 = 'Eabani Earring',
        ear2 = 'Etiolation Earring', -- 2 - 71
        ring1 = 'Weatherspoon Ring',
        ring2 = 'Lebeche Ring',
        back = gear.Sucello.FC -- 10
    }

    sets.precast.Dispelga = set_combine(sets.precast, {
        main = 'Daybreak',
        swap_managed_weapon = always_swap
    })

    sets.precast.Impact = set_combine(sets.precast,
                                      {head = '', body = 'Twilight Cloak'})

    sets.precast.RA = {
        ammo = 'Raetic Arrow',
        head = gear.Taeon.Head.Snapshot,
        body = gear.Taeon.Body.Snapshot,
        hands = 'Carmine Finger Gauntlets +1',
        legs = gear.Taeon.Legs.Snapshot,
        feet = gear.Taeon.Feet.Snapshot,
        waist = 'Yemaya Belt',
        back = gear.Sucello.Snapshot
    }

    sets.midcast.Temper = {
        ammo = 'Staunch Tathlum +1',
        main = 'Pukulatmuj +1',
        sub = 'Pukulatmuj',
        head = 'Befouled Crown',
        body = 'Viti. Tabard +3',
        hands = 'Viti. Gloves +3',
        legs = 'Atrophy Tights +3',
        feet = 'Leth. Houseaux +1',
        neck = 'Incanter\'s Torque',
        waist = 'Olympus Sash',
        ear1 = 'Mimir Earring',
        ear2 = 'Andoaa Earring',
        ring1 = gear.StikiniRing1,
        ring2 = gear.StikiniRing2,
        back = 'Ghostfyre Cape',
        swap_managed_weapon = always_swap
    }

    sets.midcast.EnspellTierOne = set_combine(sets.midcast.Temper, {})

    -- ! This set is unused, it exists for combining
    sets.midcast['Enhancing Magic'] = {
        main = gear.Colada.Enhancing,
        sub = 'Ammurapi Shield',
        head = gear.Telchine.Head.Enhancing,
        body = 'Viti. Tabard +3',
        hands = 'Atrophy Gloves +3',
        legs = gear.Telchine.Legs.Enhancing,
        feet = 'Leth. Houseaux +1',
        neck = 'Duelist\'s Torque +2',
        waist = 'Embla Sash',
        ear1 = 'Malignance Earring',
        ear2 = 'Loquacious Earring',
        ring1 = 'Kishar Ring',
        ring2 = 'Weatherspoon Ring',
        back = 'Ghostfyre Cape',
        swaps = {
            {
                test = composure,
                head = "Leth. Chappel +1",
                body = "Lethargy Sayon +1",
                legs = "Leth. Fuseau +1"
            }
        }
    }

    sets.midcast.Phalanx = set_combine(sets.midcast['Enhancing Magic'], {
        swap_managed_weapon = swap_if_low_tp,
        swaps = {
            {
                test = composure,
                head = "Leth. Chappel +1",
                body = "Lethargy Sayon +1",
                hands = 'Vitiation Gloves +3',
                legs = "Leth. Fuseau +1"
            }, { -- if we're swapping weapons, use a skill weapon
                test = pred_factory.p_and(composure, swap_if_low_tp),
                main = 'Pukulatmuj +1',
                hands = 'Atrophy Gloves +3',
                ear2 = 'Mimir Earring'
            }

        }
    })

    sets.midcast.Phalanx.Self = {
        ammo = 'Staunch Tathlum +1',
        main = "Egeking",
        sub = 'Ammurapi Shield',
        head = gear.Taeon.Head.Phalanx,
        body = gear.Chironic.Body.Phalanx,
        hands = gear.Taeon.Hands.Phalanx,
        legs = gear.Taeon.Legs.Phalanx,
        feet = gear.Taeon.Feet.Phalanx,
        neck = 'Duelist\'s Torque +2',
        waist = 'Olympus Sash', -- 5
        ear1 = 'Mimir Earring', -- 10
        ear2 = 'Andoaa Earring', -- 5
        ring1 = gear.StikiniRing1, -- 8
        ring2 = gear.StikiniRing2, -- 8
        back = 'Ghostfyre Cape',
        swap_managed_weapon = always_swap,
        swaps = {{test = can_dw, sub = 'Pukulatmuj +1'}}
    }

    sets.midcast.Aquaveil = set_combine(sets.midcast['Enhancing Magic'], {
        head = 'Amalric Coif +1',
        hands = 'Regal Cuffs',
        legs = 'Shedir Seraweels',
        waist = 'Emphatikos Rope',
        swap_managed_weapon = swap_if_low_tp
    })

    sets.midcast.Refresh = set_combine(sets.midcast['Enhancing Magic'], {
        head = 'Amalric Coif +1',
        body = 'Atrophy Tabard +3',
        legs = 'Leth. Fuseau +1',
        swaps = {}, -- Prevent composure from swapping any slots
        swap_managed_weapon = swap_if_low_tp

    })

    sets.midcast.Refresh.Self = set_combine(sets.midcast.Refresh, {
        back = 'Grapevine Cape',
        waist = 'Gishdubar Sash',
        swap_managed_weapon = swap_if_low_tp
    })

    sets.midcast.Regen = set_combine(sets.midcast['Enhancing Magic'], {
        head = gear.Telchine.Head.Regen,
        body = gear.Telchine.Body.Regen,
        legs = gear.Telchine.Legs.Regen,
        swap_managed_weapon = swap_if_low_tp
    })

    sets.midcast.GainSpell = set_combine(sets.midcast['Enhancing Magic'], {
        hands = 'Viti. Gloves +3',
        swap_managed_weapon = swap_if_low_tp
    })

    sets.midcast.Barspell = set_combine(sets.midcast['Enhancing Magic'], {
        legs = 'Shedir Seraweels',
        swap_managed_weapon = swap_if_low_tp
    })

    sets.midcast.Utsusemi = {
        ammo = 'Staunch Tathlum +1',
        head = 'Atrophy Chapeau +3',
        body = 'Viti. Tabard +3',
        hands = 'Malignance Gloves',
        legs = 'Malignance Tights',
        feet = 'Malignance Boots',
        neck = 'Loricate Torque +1',
        waist = 'Flume Belt +1',
        ear1 = 'Malignance Earring',
        ear2 = 'Genmei Earring',
        ring1 = 'Defending Ring',
        ring2 = 'Gelatinous Ring',
        back = gear.Sucello.FC
    }

    sets.midcast.Cure = {
        main = 'Daybreak',
        sub = 'Ammurapi Shield',
        ammo = 'Regal Gem',
        head = gear.Kaykaus.Head.PathC,
        body = gear.Kaykaus.Body.PathC,
        hands = gear.Kaykaus.Hands.PathC,
        legs = gear.Kaykaus.Legs.PathC,
        feet = gear.Kaykaus.Feet.PathC,
        neck = 'Incanter\'s Torque',
        waist = 'Luminary Sash',
        ear1 = 'Beatific Earring',
        ear2 = 'Meili Earring',
        ring1 = 'Sirona\'s Ring',
        ring2 = 'Haoma\'s Ring',
        back = gear.Sucello.Cure,
        swap_managed_weapon = swap_if_low_tp,
        swaps = {
            {
                test = pred_factory.elemental_obi_bonus(1),
                main = 'Chatoyant Staff',
                sub = 'Enki Strap',
                waist = 'Korin Obi'
            }
        }
    }

    sets.midcast.Cure.Self = set_combine(sets.midcast.Cure, {
        neck = 'Phalaina Locket',
        waist = 'Gishdubar Sash',
        ring2 = 'Kunaji Ring'
    })

    sets.midcast.Curaga = sets.midcast.Cure

    sets.midcast.Cursna = {
        main = 'Prelatic Pole',
        sub = 'Curatio Grip',
        ammo = 'Staunch Tathlum +1',
        head = gear.Vanya.Head.PathB,
        body = 'Viti. Tabard +3',
        hands = 'Hieros Mittens',
        legs = gear.Vanya.Legs.PathB,
        feet = 'Gende. Galosh. +1',
        neck = 'Debilis Medallion',
        waist = 'Bishop\'s Sash',
        ear1 = 'Beatific Earring',
        ear2 = 'Meili Earring',
        ring1 = 'Menelaus\'s Ring',
        ring2 = 'Haoma\'s Ring',
        back = 'Oretan. Cape +1',
        swap_managed_weapon = always_swap
    }

    sets.midcast.Cursna.Self = set_combine(sets.Cursna, {
        neck = 'Nicander\'s Necklace',
        waist = 'Gishdubar Sash'
    })

    sets.midcast.Raise = { --                           SIRD    FC
        ammo = 'Staunch Tathlum +1', -- 10 SIRD         20      38
        head = 'Atrophy Chapeau +3', -- 16 FC                   54
        body = 'Vit. Tabard +3', -- 15 FC                       69
        hands = gear.Kaykaus.Hands.PathC, -- 12 SIRD    32
        legs = gear.Carmine.Legs.PathD, -- 20 SIRD      52
        feet = 'Amalric Nails +1', -- 16 SIRD           68
        neck = 'Loricate Torque +1',
        waist = 'Emphatikos Rope', -- 12 SIRD           80
        ear1 = 'Etiolation Earring', -- 2 FC                    71
        ear2 = 'Genmei Earring',
        ring1 = 'Freke Ring', -- 10 SIRD                90
        ring2 = 'Evanescence Ring', -- 5 SIRD           95
        back = gear.Sucello.FC -- 10 SIRD, 10 FC       105     81
    }

    -- Enfeebling

    sets.midcast.Dia = {
        main = 'Daybreak',
        sub = 'Sacro Bulwark',
        ammo = 'Regal Gem',
        head = 'Vitiation Chapeau +3',
        body = 'Lethargy Sayon +1',
        hands = 'Regal Cuffs',
        legs = 'Malignance Tights',
        feet = 'Vitiation Boots +3',
        neck = 'Duelist\'s Torque +2',
        waist = 'Orpheus\'s Sash',
        ear1 = 'Snotra Earring',
        ear2 = 'Regal Earring',
        ring1 = 'Kishar Ring',
        ring2 = 'Weatherspoon Ring',
        back = gear.Sucello.FC,
        swaps = {
            {
                test = composure,
                head = 'Lethargy Chappel +1',
                legs = 'Lethargy Fuseau +1'
            }, {
                test = pred_factory.p_and(composure, saboteur),
                hands = 'Lethargy Gantherots +1'
            }
        },
        -- Swap weapons if we're low tp, and not already wearing daybreak
        swap_managed_weapon = pred_factory.p_and(swap_if_low_tp, function()
            return settings.main ~= 'Daybreak' and settings.sub ~= 'Daybreak'
        end)
    }

    sets.midcast.Distract = { -- need 134 skill for distract, 149 for frazzle
        main = 'Contemplator +1', -- 20                 20
        sub = 'Mephitis Grip', -- 5                     25
        ammo = 'Regal Gem',
        head = 'Viti. Chapeau +3', -- 26                51
        body = 'Lethargy Sayon +1',
        hands = gear.Kaykaus.Hands.PathA, -- 16         67
        legs = gear.Psycloth.Legs.PathB, -- 18          85
        feet = 'Vitiation Boots +3', -- 16              101
        neck = 'Duelist\'s Torque +2',
        waist = 'Rumination Sash', -- 7                 108
        ear1 = 'Snotra Earring', -- 0                   108
        ear2 = 'Vor Earring', -- 10                     118
        ring1 = gear.StikiniRing1, -- 8                 126
        ring2 = gear.StikiniRing2, -- 8                 134
        back = gear.Sucello.FC,
        swaps = {
            {
                test = saboteur,
                hands = 'Lethargy Gantherots +1' -- 3  137
            },
            {
                test = swap_if_low_tp, -- If we're not using contemplator, this pushes us up one tier
                ear1 = 'Enfeebling Earring' -- -17    120

            }
        },
        swap_managed_weapon = swap_if_low_tp
    }

    sets.midcast.Frazzle = set_combine(sets.midcast.Distract, {
        ear1 = 'Enfeebling Earring',
        swaps = {
            {
                test = saboteur,
                hands = 'Lethargy Gantherots +1' -- 3  137
            }
        },
    })

    sets.midcast['Frazzle II'] = {
        main = 'Murgleis',
        sub = 'Ammurapi Shield',
        ammo = 'Regal Gem',
        head = 'Vitiation Chapeau +3',
        body = 'Atrophy Tabard +3',
        hands = gear.Kaykaus.Hands.PathA,
        legs = gear.Chironic.Legs.INT_Enfeeble,
        feet = 'Vitiation Boots +3',
        neck = 'Duelist\'s Torque +2',
        waist = 'Acuity Belt +1',
        ear1 = 'Snotra Earring',
        ear2 = 'Regal Earring',
        ring1 = gear.StikiniRing1,
        ring2 = 'Metamorph Ring +1',
        back = gear.Sucello.INT_MAB,
        swaps = {
            {test = saboteur, hands = 'Lethargy Gantherots +1'},
            {test = can_dw, sub = gear.CroceaMors.PathC}
        },
        swap_managed_weapon = swap_if_low_tp
    }

    sets.midcast.Bio = { -- need 84 dark magic skill to cap
        ammo = 'Pemphredo Tathlum',
        head = 'Pixie Hairpin +1',
        body = 'Shango Robe', -- 15                 15
        hands = gear.Amalric.Hands.PathC, -- 20     35
        legs = gear.Amalric.Legs.PathC, -- 20       55
        feet = gear.Amalric.Feet.PathC, -- 20       75
        neck = 'Erra Pendant', -- 10                85
        waist = 'Sacro Cord',
        ear1 = 'Malignance Earring',
        ear2 = 'Mani Earring',
        ring1 = 'Archon Ring',
        ring2 = 'Evanescence Ring',
        back = gear.Sucello.INT_MAB
    }

    -- Spells with a fixed effect that either hits or misses
    sets.midcast.IntEnfeeble = {}

    sets.midcast.IntEnfeeble['Potency/Duration'] =
        {
            main = 'Murgleis',
            sub = 'Ammurapi Shield',
            ammo = 'Regal Gem',
            head = 'Atrophy Chapeau +3',
            body = 'Lethargy Sayon +1',
            hands = 'Regal Cuffs',
            legs = gear.Chironic.Legs.INT_Enfeeble,
            feet = 'Vitiation Boots +3',
            neck = 'Duelist\'s Torque +2',
            waist = 'Acuity Belt +1',
            ear1 = 'Snotra Earring',
            ear2 = 'Regal Earring',
            ring1 = 'Kishar Ring',
            ring2 = 'Metamorph Ring +1',
            back = gear.Sucello.INT_MAB,
            swaps = {{test = can_dw, sub = gear.CroceaMors.PathB}},
            swap_managed_weapon = swap_if_low_tp
        }

    sets.midcast.IntEnfeeble.Accuracy = {
        main = 'Murgleis',
        sub = 'Ammurapi Shield',
        ammo = 'Regal Gem',
        head = 'Atrophy Chapeau +3',
        body = 'Atrophy Tabard +3',
        hands = gear.Kaykaus.Hands.PathA,
        legs = gear.Chironic.Legs.INT_Enfeeble,
        feet = 'Vitiation Boots +3',
        neck = 'Duelist\'s Torque +2',
        waist = 'Acuity Belt +1',
        ear1 = 'Malignance Earring',
        ear2 = 'Regal Earring',
        ring1 = gear.StikiniRing1,
        ring2 = 'Metamorph Ring +1',
        back = gear.Sucello.INT_MAB,
        swaps = {{test = can_dw, sub = gear.CroceaMors.PathB}},
        swap_managed_weapon = swap_if_low_tp
    }

    sets.midcast.Dispelga = set_combine(sets.midcast.IntEnfeeble.Accuracy, {
        main = 'Daybreak',
        swap_managed_weapon = always_swap
    })

    sets.midcast.MndEnfeeble = {}

    sets.midcast.MndEnfeeble['Potency/Duration'] =
        set_combine(sets.midcast.IntEnfeeble.Duration, {
            head = 'Vitiation Chapeau +3',
            legs = gear.Chironic.Legs.MND_Enfeeble,
            waist = 'Luminary Sash',
            back = gear.Sucello.FC,
            swaps = {
                {test = can_dw, sub = gear.CroceaMors.PathB}, {
                    test = pred_factory.p_and(composure, saboteur),
                    hands = 'Lethargy Gantherots +1'
                }
            }
        })

    sets.midcast.MndEnfeeble.Accuracy = set_combine(
                                            sets.midcast.MndEnfeeble.Accuracy, {
            head = 'Vitiation Chapeau +3',
            legs = gear.Chironic.Legs.MND_Enfeeble,
            waist = 'Luminary Sash',
            back = gear.Sucello.FC,
            swaps = {
                {test = can_dw, sub = gear.CroceaMors.PathB}, {
                    test = pred_factory.p_and(composure, saboteur),
                    hands = 'Lethargy Gantherots +1'
                }
            }
        })

    -- Spells with scalable effects
    sets.midcast.IntEnfeebleScaling = {}

    -- layer potency, and Int
    sets.midcast.IntEnfeebleScaling['Potency/Duration'] =
        {
            ammo = 'Regal Gem',
            head = 'Atrophy Chapeau +3',
            body = 'Lethargy Sayon +1',
            hands = 'Regal Cuffs',
            legs = gear.Chironic.Legs.INT_Enfeeble,
            feet = 'Vitiation Boots +3',
            neck = 'Duelist\'s Torque +2',
            waist = 'Acuity Belt +1',
            ear1 = 'Snotra Earring',
            ear2 = 'Regal Earring',
            ring1 = 'Kishar Ring',
            ring2 = 'Metamorph Ring +1',
            back = gear.Sucello.INT_MAB,
            swaps = {{test = saboteur, hands = 'Lethargy Gantherots +1'}}
        }

    sets.midcast.IntEnfeebleScaling.Accuracy =
        set_combine(sets.midcast.IntEnfeebleScaling['Potency/Duration'], {
            main = 'Murgleis',
            sub = 'Ammurapi Shield',
            body = 'Atrophy Tabard +3',
            ring1 = gear.StikiniRing1,
            swaps = {
                {test = saboteur, hands = 'Lethargy Gantherots +1'},
                {test = can_dw, sub = gear.CroceaMors.PathC}
            },
            swap_managed_weapon = swap_if_low_tp
        })

    sets.midcast.Poison = {
        main = 'Contemplator +1', -- 20   
        ammo = 'Regal Gem',
        head = 'Vitiation Chapeau +3', -- 25            
        body = 'Lethargy Sayon +1',
        hands = gear.Kaykaus.Hands.PathA, -- 16       
        legs = gear.Psycloth.Legs.PathB, -- 18    
        feet = 'Vitiation Boots +3', -- 16             
        neck = 'Duelist\'s Torque +2',
        waist = 'Rumination Sash', -- 7                
        ear1 = 'Snotra Earring',
        ear2 = 'Vor Earring', -- 10                     
        ring1 = gear.StikiniRing1, -- 8                 
        ring2 = gear.StikiniRing2, -- 8                 
        back = gear.Sucello.INT_MAB,
        swaps = {
            {
                test = saboteur,
                hands = 'Lethargy Gantherots +1' -- 3
            }
        },
        swap_managed_weapon = swap_if_low_tp
    }

    sets.midcast.Poison.Accuracy = set_combine(sets.midcast.Poison,
                                               {body = 'Atrophy Tabard +3'})

    sets.midcast.ElementalEnfeeble = {
        main = 'Murgleis',
        sub = 'Ammurapi Shield',
        ammo = 'Regal Gem',
        head = 'Vitiation Chapeau +3',
        body = 'Atrophy Tabard +3',
        hands = gear.Kaykaus.Hands.PathA,
        legs = gear.Chironic.Legs.INT_Enfeeble,
        feet = 'Vitiation Boots +3',
        neck = 'Duelist\'s Torque +2',
        waist = 'Acuity Belt +1',
        ear1 = 'Malignance Earring',
        ear2 = 'Regal Earring',
        ring1 = gear.StikiniRing1,
        ring2 = 'Metamorph Ring +1',
        back = 'Aurist\'s Cape +1',
        swaps = {{test = can_dw, sub = gear.CroceaMors.PathC}},
        swap_managed_weapon = swap_if_low_tp
    }

    local function magic_burst_test(spell)
        if settings.magic_burst.value ~= 'Auto' then
            return settings.magic_burst.value == 'Always'
        end

        -- Once the api has skillchain detection, determine if the spell would burst here
    end

    sets.midcast['Elemental Magic'] = {
        main = 'Daybreak',
        sub = 'Ammurapi Shield',
        ammo = 'Pemphredo Tathlum',
        head = 'Ea Hat +1',
        body = gear.Amalric.Body.PathA,
        hands = gear.Amalric.Hands.PathD,
        legs = gear.Amalric.Legs.PathA,
        feet = gear.Amalric.Feet.PathA,
        neck = 'Baetyl Pendant',
        waist = 'Sacro Cord',
        ear1 = 'Malignance Earring',
        ear2 = 'Regal Earring',
        ring1 = 'Freke Ring',
        ring2 = 'Shiva Ring +1',
        back = gear.Sucello.INT_MAB,
        swap_managed_weapon = swap_if_low_tp,
        swaps = {
            {
                test = magic_burst_test,
                body = 'Ea Houppe. +1',
                legs = 'Ea Slops +1',
                feet = 'Ea Pigaches +1',
                neck = 'Mizu. Kubikazari',
                ring2 = 'Mujin Band'
            }, {test = pred_factory.orpheus, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.hachirin, waist = 'Hachirin-no-Obi'}
        }
    }

    sets.midcast.Impact = {
        main = 'Murgleis',
        sub = 'Ammurapi Shield',
        ammo = 'Pemphredo Tathlum',
        body = 'Twilight Cloak',
        hands = 'Regal Cuffs',
        legs = gear.Chironic.Legs.INT_Enfeeble,
        feet = 'Vitiation Boots +3',
        neck = 'Duelist\'s Torque +2',
        waist = 'Acuity Belt +1',
        ear1 = 'Malignance Earring',
        ear2 = 'Snotra Earring',
        ring1 = gear.StikiniRing1,
        ring2 = 'Metamorph Ring +1',
        back = gear.Sucello.INT_MAB,
        swap_managed_weapon = swap_if_low_tp,
        swaps = {
            {test = can_dw, sub = gear.CroceaMors.PathC},
            {test = swap_if_low_tp, range = 'Ullr'}
        }
    }

    -- Get some drain/aspir augs on merlinic for this
    sets.midcast.Drain = {
        main = 'Murgleis',
        sub = 'Ammurapi Shield',
        ammo = 'Regal Gem',
        head = 'Pixie Hairpin +1',
        body = 'Atrophy Tabard +3',
        hands = gear.Kaykaus.Hands.PathA,
        legs = gear.Chironic.Legs.MND_Enfeeble,
        feet = 'Vitiation Boots +3',
        neck = 'Erra Pendant',
        waist = 'Fucho-no-Obi',
        ear1 = 'Malignance Earring',
        ear2 = 'Mani Earring',
        ring1 = 'Archon Ring',
        ring2 = 'Evanescence Ring',
        back = 'Aurist\'s Cape +1',
        swap_managed_weapon = swap_if_low_tp,
        swaps = {
            {test = can_dw, sub = gear.CroceaMors.PathC},
            {test = swap_if_low_tp, range = 'Ullr'},
            {test = pred_factory.orpheus, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.hachirin, waist = 'Hachirin-no-Obi'}
        }
    }

    sets.midcast.Aspir = sets.midcast.Drain

    sets.midcast['Divine Magic'] = sets.midcast['Elemental Magic']
    sets.midcast.Flash = {
        main = 'Murgleis',
        sub = 'Ammurapi Shield',
        ammo = 'Regal Gem',
        head = 'Vitiation Chapeau +3',
        body = 'Atrophy Tabard +3',
        hands = gear.Kaykaus.Hands.PathA,
        legs = gear.Chironic.Legs.MND_Enfeeble,
        feet = 'Vitiation Boots +3',
        neck = 'Duelist\'s Torque +2',
        waist = 'Luminary Sash',
        ear1 = 'Malignance Earring',
        ear2 = 'Regal Earring',
        ring1 = gear.StikiniRing1,
        ring2 = 'Metamorph Ring +1',
        back = 'Aurist\'s Cape +1',
        swap_managed_weapon = swap_if_low_tp,
        swaps = {
            {test = can_dw, sub = gear.CroceaMors.PathC},
            {test = swap_if_low_tp, range = 'Ullr'}
        }
    }

    sets.midcast.RA = {
        ammo = 'Raetic Arrow',
        head = 'Malignance Chapeau',
        body = 'Malignance Tabard',
        hands = 'Malignance Gloves',
        legs = 'Malignance Tights',
        feet = 'Malignance Boots',
        neck = 'Marked Gorget',
        waist = 'Yemaya Belt',
        ear1 = 'Telos Earring',
        ear2 = 'Enervating Earring',
        ring1 = gear.HajdukRing1,
        ring2 = gear.HajdukRing2,
        back = gear.Sucello.AGI_STP
    }

    sets.engaged = {
        ammo = 'Aurgelmir Orb +1',
        head = 'Malignance Chapeau',
        body = 'Malignance Tabard',
        hands = 'Malignance Gloves',
        legs = 'Malignance Tights',
        feet = 'Malignance Boots',
        neck = 'Anu Torque',
        waist = 'Windbuffet Belt +1',
        ear1 = 'Dedition Earring',
        ear2 = 'Sherida Earring',
        ring1 = gear.Chirich1,
        ring2 = gear.Chirich2,
        back = gear.Sucello.DEX_DA,
        swaps = {
            {
                test = function()
                    return settings.engaged.value == 'Subtle Blow'
                end,
                -- body = 'Volte Harness'
                neck = 'Bathy Choker +1'
            }
        }
    }

    sets.engaged.DW11 = set_combine(sets.engaged, {
        waist = 'Reiki Yotai',
        ear1 = 'Eabani Earring'
    })

    sets.engaged.DW21 = set_combine(sets.engaged.DW11,
                                    {back = gear.Sucello.DEX_DW})

    sets.engaged.DW31 = set_combine(sets.engaged.DW21, {
        ear1 = 'Suppanomimi',
        feet = gear.Taeon.Feet.DW
    })

    sets.engaged.Enspell = set_combine(sets.engaged, {
        hands = 'Ayanmo Manopolas +2',
        neck = 'Sanctity Necklace',
        waist = 'Orpheus\'s Sash',
        back = 'Ghostfyre Cape'
    })

    sets.engaged.Enspell.DW11 = set_combine(sets.engaged.Enspell, {
        legs = gear.Carmine.Legs.PathD,
        feet = gear.Carmine.Feet.PathB,
        ear1 = 'Suppanomimi'
    })

    -- set has only 20 DW, can use DM DW augs to make a slightly better 21 DW set
    sets.engaged.Enspell.DW21 = set_combine(sets.engaged.Enspell.DW11,
                                            {feet = gear.Taeon.Feet.DW})

    sets.engaged.Enspell.DW31 = set_combine(sets.engaged.Enspell.DW21, {})

    sets.engaged.Murgleis = {}

    sets.engaged.Murgleis.AM3 = set_combine(sets.engaged,
                                            {back = gear.Sucello.DEX_STP})

    sets.engaged.Murgleis.AM3.DW11 = set_combine(sets.engaged.DW11,
                                                 {back = gear.Sucello.DEX_STP})

    sets.engaged.Murgleis.AM3.DW21 = set_combine(sets.engaged.DW21, {})

    sets.engaged.Murgleis.AM3.DW31 = set_combine(sets.engaged.DW31, {})

    sets.engaged.Almace = {}

    sets.engaged.Almace.AM3 = set_combine(sets.engaged, {
        waist = 'Sailfi Belt +1',
        ring1 = 'Ilabrat Ring',
        ring2 = 'Hetairoi Ring',
        swaps = {
            {
                test = function()
                    return settings.engaged.value == 'Subtle Blow'
                end,
                -- body = 'Volte Harness'
                neck = 'Bathy Choker +1',
                ring1 = gear.Chirich1,
                ring2 = gear.Chirich2
            }
        }
    })

    sets.engaged.Almace.AM3.DW11 = set_combine(sets.engaged.Almace.AM3,
                                               {back = gear.Sucello.DEX_DW})

    sets.engaged.Almace.AM3.DW21 = set_combine(sets.engaged.Almace.AM3.DW11, {
        legs = gear.Carmine.Legs.PathD,
        ear1 = 'Suppanomimi'
    })

    sets.engaged.Almace.AM3.DW31 = set_combine(sets.engaged.Almace.AM3.DW21, {
        legs = 'Malignance Tights',
        waist = 'Reiki Yotai',
        feet = gear.Taeon.Feet.DW
    })

    sets.engaged['Hand-to-Hand'] = set_combine(sets.engaged, {
        ear1 = gear.MacheEarring1,
        ear2 = gear.MacheEarring2
    })

    local subtle_blow_swaps = {
        test = function() return settings.WeaponSkill.value end,
        neck = 'Bathy Choker +1',
        ring1 = gear.Chirich1,
        ring2 = gear.Chirich2
    }

    sets.WS = {
        ammo = 'Aurgelmir Orb +1',
        head = 'Vitiation Chapeau +3',
        body = 'Jhakri Robe +2',
        hands = 'Atrophy Gloves +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Jhakri Pigaches +2',
        neck = 'Fotia Gorget',
        waist = 'Sailfi Belt +1',
        ear1 = 'Moonshade Earring',
        ear2 = 'Sherida Earring',
        ring1 = 'Rufescent Ring',
        ring2 = 'Epaminondas\'s Ring',
        back = gear.Sucello.STR_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), ear1 = 'Ishvara Earring'},
            subtle_blow_swaps
        }
    }

    -- Sword Weaponskills
    sets.WS['Vorpal Blade'] = {
        ammo = 'Yetshila +1',
        head = 'Blistering Sallet +1',
        body = 'Ayanmo Corazza +2',
        hands = 'Malignance Gloves',
        legs = 'Zoar Subligar +1',
        feet = 'Thereoid Greaves',
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        ear1 = 'Moonshade Earring',
        ear2 = 'Sherida Earring',
        ring1 = 'Begrudging Ring',
        ring2 = 'Shukuyu Ring',
        back = gear.Sucello.DEX_CRIT,
        swaps = {
            {test = pred_factory.etp_gt(2750), ear1 = 'Brutal Earring'},
            subtle_blow_swaps
        }
    }

    sets.WS['Savage Blade'] = set_combine(sets.WS, {
        body = 'Vitiation Tabard +3',
        feet = gear.Chironic.Feet.WSD,
        neck = 'Duelist\'s Torque +2',
        ear2 = 'Regal Earring'
    })

    sets.WS['Knights of Round'] = set_combine(sets.WS['Savage Blade'], {})

    sets.WS['Death Blossom'] = set_combine(sets.WS['Savage Blade'], {
        ring1 = 'Metamorph Ring +1',
        back = gear.Sucello.MND_WSD
    })

    sets.WS['Chant Du Cygne'] = set_combine(sets.WS['Vorpal Blade'], {})

    sets.WS.Requiescat = set_combine(sets.WS, {
        ammo = 'Regal Gem',
        body = 'Vitiation Tabard +3',
        ear2 = 'Regal Earring',
        ring2 = 'Metamorph Ring +1',
        back = gear.Sucello.MND_WSD
    })

    -- Sword Elemental Weaponskills
    sets.WS.Elemental =
        { -- This set is never equipped, just used for set_combines
            ammo = 'Pemphredo Tathlum',
            head = 'C. Palug Crown',
            body = gear.Amalric.Body.PathA,
            hands = 'Jhakri Cuffs +2',
            legs = gear.Amalric.Legs.PathA,
            feet = gear.Amalric.Feet.PathA,
            neck = 'Baetyl Pendant',
            waist = 'Orpheus\'s Sash',
            ear1 = 'Regal Earring',
            ear2 = 'Malignance Earring',
            ring1 = 'Epaminondas\'s Ring',
            ring2 = 'Freke Ring',
            back = gear.Sucello.MND_WSD,
            swaps = {
                {
                    test = pred_factory.hachirin_bonus(2),
                    waist = 'Hachirin-no-Obi'
                }
            }
        }

    sets.WS['Shining Blade'] = set_combine(sets.WS.Elemental, {
        ring1 = 'Weatherspoon Ring',
        swaps = {
            {test = pred_factory.etp_lte(2750), ear1 = 'Moonshade Earring'}
        }
    })

    sets.WS['Seraph Blade'] = set_combine(sets.WS['Shining Blade'], {})

    sets.WS['Uriel Blade'] = set_combine(sets.WS['Shining Blade'], {})

    sets.WS['Sanguine Blade'] = set_combine(sets.WS.Elemental, {
        head = 'Pixie Hairpin +1',
        ring2 = 'Archon Ring'
    })

    -- Dagger Weaponskills
    sets.WS.Evisceration = set_combine(sets.WS['Vorpal Blade'])

    sets.WS.Exenterator = {
        ammo = 'Aurgelmir Orb +1',
        head = 'Malignance Chapeau',
        body = 'Malignance Tabard',
        hands = 'Malignance Gloves',
        legs = 'Malignance Tights',
        feet = 'Malignance Boots',
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        ear1 = 'Ishvara Earring',
        ear2 = 'Moonshade Earring',
        ring1 = 'Ilabrat Ring',
        ring2 = 'Apate Ring',
        back = gear.Sucello.AGI_WSD_ACC,
        swaps = {
            {test = pred_factory.etp_gt(2750), ear2 = 'Telos Earring'},
            subtle_blow_swaps
        }
    }
    sets.WS['Mercy Stroke'] = set_combine(sets.WS, {
        neck = 'Caro Necklace',
        ear1 = 'Ishvara Earring'
    })

    sets.WS['Aeolian Edge'] = set_combine(sets.WS.Elemental,
                                          {back = gear.Sucello.INT_WSD})

    -- Club Weaponskills
    sets.WS['Black Halo'] = {
        ammo = 'Aurgelmir Orb +1',
        head = 'Vitiation Chapeau +3',
        body = 'Vitiation Tabard +3',
        hands = 'Atrophy Gloves +3',
        legs = 'Jhakri Pigaches +2',
        feet = gear.Chironic.Feet.WSD,
        neck = 'Duelist\'s Torque +2',
        waist = 'Sailfi Belt +1',
        ear1 = 'Regal Earring',
        ear2 = 'Moonshade Earring',
        ring1 = 'Epaminondas\'s Ring',
        ring2 = 'Metamorph Ring +1',
        back = gear.Sucello.MND_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), ear2 = 'Sherida Earring'},
            subtle_blow_swaps
        }
    }

    -- Bow Weaponskills
    sets.WS['Empyreal Arrow'] = {
        ammo = 'Raetic Arrow',
        head = 'Malignance Chapeau',
        body = 'Malignance Tabard',
        hands = 'Malignance Gloves',
        legs = 'Malignance Tights',
        feet = 'Malignance Boots',
        neck = 'Marked Gorget',
        waist = 'Yemaya Belt',
        ear1 = 'Telos Earring',
        ear2 = 'Enervating Earring',
        ring1 = 'Cacoethic Ring +1',
        ring2 = 'Garuda Ring +1',
        back = gear.Sucello.AGI_WSD_RACC
    }

    -- H2H Weaponskills
    sets.WS['Asuran Fists'] = {
        ammo = 'Aurgelmir Orb +1',
        head = 'Vitiation Chapeau +3',
        body = 'Vitiation Tabard +3',
        hands = 'Atrophy Gloves +3',
        legs = 'Vitiation Tights +3',
        feet = 'Atrophy Boots +3',
        neck = 'Combatant\'s Torque',
        waist = 'Sailfi Belt +1',
        ear1 = gear.MacheEarring1,
        ear2 = gear.MacheEarring2,
        ring1 = 'Shukuyu Ring',
        ring2 = 'Rufescent Ring',
        back = gear.Sucello.STR_WSD,
        swaps = {subtle_blow_swaps}
    }
    -- Maybe voluspa tathlum as an acc swap for this?

    sets.item['Holy Water'] = {
        neck = 'Nicander\'s Necklace',
        ring1 = 'Purity Ring',
        ring2 = 'Blenmot\'s Ring +1'
    }
end)

do
    local get_icon
    do
        local path = windower.windower_path .. '/addons/equipviewer/icons/32/'
        get_icon = function(name)
            local item_id = res.items:with('en', name).id
            return path .. tostring(item_id) .. '.png'
        end
    end

    -- Map over only array-like portion of table
    local imap = function(t, fn)
        local res = {}
        for i, v in ipairs(t) do res[i] = fn(v) end

        return setmetatable(res, getmetatable(t))
    end

    local function get_icons(mode)
        return imap(mode, function(el)
            -- TODO: allow for /graphics/JOB/item_name.png to take priority
            local item_name = type(el) == 'table' and el.name or el
            local value = type(el) == 'table' and el.alias or item_name
            local img
            if windower.file_exists(
                windower.addon_path .. '/data/graphics/COR/' .. value .. '.png') then
                img = windower.addon_path .. '/data/graphics/COR/' .. value ..
                          '.png'
            elseif windower.file_exists(
                windower.addon_path .. '/data/graphics/' .. value .. '.png') then
                img = windower.addon_path .. '/data/graphics/' .. value ..
                          '.png'
            elseif windower.file_exists(windower.addon_path ..
                                            '/data/graphics/COR/' .. item_name ..
                                            '.png') then
                img =
                    windower.addon_path .. '/data/graphics/COR/' .. item_name ..
                        '.png'
            elseif windower.file_exists(
                windower.addon_path .. '/data/graphics/' .. item_name .. '.png') then
                img = windower.addon_path .. '/data/graphics/' .. item_name ..
                          '.png'
            else
                img = get_icon(item_name)
            end
            return {img = img, value = tostring(value)}
        end)
    end

    local GUI_x = 1070
    local GUI_y = 100
    GUI.bound.y.lower = 70
    GUI.bound.y.upper = 471

    IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.main,
        icons = get_icons(settings.main)
    }):draw()

    GUI_y = GUI_y + 54

    local sub_button = IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.sub,
        icons = get_icons(settings.sub)
    }):draw()

    settings.sub.on_option_change:register(
        function() sub_button:new_icons(get_icons(settings.sub)) end)

    GUI_y = GUI_y + 54

    ToggleButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.ullr,
        iconUp = 'RDM/Ullr Off.png',
        iconDown = 'RDM/Ullr On.png'
    }):draw()

    GUI_y = GUI_y + 54

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.engaged,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.enfeebling,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.magic_burst,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    local dw_mode_display = TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_mode,
        align = 'left',
        width = 112,
        start_hidden = true,
        disabled = true
    }):draw()

    GUI_y = GUI_y + 32

    local dw_level_display = TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_level,
        align = 'left',
        width = 112,
        start_hidden = true,
        disabled = true
    }):draw()

    settings.sub.on_option_change:register(
        function(m)
            local player = windower.ffxi.get_player()
            if player.sub_job == 'NIN' or player.sub_job == 'DNC' then
                if item_type(settings.main.value) == '1h' then
                    dw_mode_display:enable():show()
                    dw_level_display:enable():show()
                else
                    dw_mode_display:disable():hide()
                    dw_level_display:disable():hide()
                end
            end
        end)

end
