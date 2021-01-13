require('J-Swap')
require('GUI')
res = require('resources')

local M = require('J-Mode')
local events = require('J-Swap-Events')
local haste = require('J-Haste')
local pred_factory = require('J-Predicates')
local command = require('J-Swap-Command')
local bind_key = require('J-Bind')

local gear = require('Pokecenter-Gear')

settings.lock_weapons = M(false, 'Lock Weapons')
settings.main = M {
    ['description'] = 'Main Hand',
    'Yagrush',
    'Mjollnir',
    'Maxentius',
    'Tishtrya',
    'Daybreak',
    'Xoanon',
    gear.Grioavolr.MAB
}

local item_id_memo = setmetatable({}, {
    __index = function(t, k)
        t[k] = res.items:with('en', k).id
        return t[k]
    end
})
do
    settings.sub = M {['description'] = 'Off Hand', 'Genmei Shield'}
    local subs = T {
        'Magesmasher +1', 'Ukaldi', 'Sindri', 'Izcalli', 'Daybreak', 'Kraken Club',
        'Genmei Shield', 'Ammurapi Shield', 'Bloodrain Strap'
    }
    local function pack_sub()
        local player = windower.ffxi.get_player()
        local main = settings.main.value
        local main_slots = res.items[item_id_memo[type(main) == 'table' and
                               main.name or main]].slots

        local options = T {}

        local can_dw = player.sub_job == 'NIN' or player.sub_job == 'DNC'

        if main_slots:contains(0) and not main_slots:contains(1) then -- 2h
            subs:map(function(gear)
                local gear_id =
                    item_id_memo[type(gear) == 'table' and gear.name or gear]
                local gear_table = res.items[gear_id]
                if gear_table.type == 4 and gear_table.slots:contains(1) and
                    not gear_table.slots:contains(0) then
                    options:append(gear)
                end
            end)
        elseif main_slots:contains(0) and main_slots:contains(1) then -- 1h
            if can_dw then
                subs:map(function(gear)
                    local gear_id = item_id_memo[type(gear) == 'table' and
                                        gear.name or gear]
                    local gear_table = res.items[gear_id]
                    if gear_table.slots:contains(0) and
                        gear_table.slots:contains(1) then
                        options:append(gear)
                    end
                end)
            end
            subs:map(function(gear)
                local gear_id =
                    item_id_memo[type(gear) == 'table' and gear.name or gear]
                local gear_table = res.items[gear_id]
                if gear_table.type == 5 and gear_table.slots:contains(1) and
                    not gear_table.slots:contains(0) then
                    options:append(gear)
                end
            end)
        end

        settings.sub:options(options:unpack())
    end
    -- events.load:register(pack_sub)
    events.sub_job_change:register(pack_sub)
    settings.sub.on_change:register(function()
        windower.send_command('gs c update')
    end)

    local prev_slots = T {}
    settings.main.on_change:register(function(m)
        local gear_id =
            item_id_memo[type(m.value) == 'table' and m.value.name or m.value]
        local gear_table = res.items[gear_id]
        if not prev_slots:equals(gear_table.slots) then
            pack_sub()
            prev_slots = gear_table.slots
        end
        settings.lock_weapons:set()
        windower.send_command('gs c update')
    end)
end

settings.accuracy = M {
    ['description'] = 'Accuracy Mode',
    'Normal',
    'Mid',
    'High'
}

settings.accuracy.on_change:register(function()
    windower.send_command('gs c update')
end)

settings.Cursna = M {['description'] = 'Cursna Mode', 'AoE', 'Single Target'}
settings.Regen = M {['description'] = 'Regen Mode', 'Potency', 'Duration'}
settings.BarElement = M {
    ['description'] = 'Barspell Mode',
    'Potency',
    'Duration'
}
settings.Raise = M {
    ['description'] = 'Raise Mode',
    'Recast',
    'Conserve MP',
    'SIRD'
}

settings.dual_wield_mode = M {
    ['description'] = 'Dual Wield Mode',
    'Auto',
    'Manual'
}

settings.dual_wield_level = M {
    ['description'] = 'Dual Wield Level',
    '0', -- /nin haste samba
    '9', -- /dnc haste samba
    '11', -- /nin capped ma haste
    '21', -- /dnc capped ma haste
    '25' -- /nin mid ma haste
}

haste.change:register(function(gearswap_vars_loaded)
    if not midaction() then
        if gearswap_vars_loaded then
            events.update:trigger()
        else
            windower.send_command('gs c update')
        end
    end
end)

-- Weaponskill accuracy
rules.precast:append({
    test = function(equip_set, spell) return spell.type == 'WeaponSkill' end,
    key = function(equip_set, spell)
        for i = settings.accuracy.index, 1, -1 do
            if equip_set[settings.accuracy[i]] then
                return settings.accuracy[i]
            end
        end
    end
})

-- Dual Wield sets and auto DW detection
local function dw_test()
    local main = settings.main.value
    local sub = settings.sub.value

    local main_id = item_id_memo[type(main) == 'table' and main.name or main]
    local sub_id = item_id_memo[type(sub) == 'table' and sub.name or sub]
    return (player.sub_job == 'NIN' or player.sub_job == 'DNC') and
               res.items[main_id].slots:contains(0) and
               res.items[main_id].slots:contains(1) and
               res.items[sub_id].slots:contains(0) and
               res.items[sub_id].slots:contains(1)
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

-- Engaged Accuracy
rules.engaged:append({
    test = function() return true end,
    key = function(equip_set)
        for i = settings.accuracy.index, 1, -1 do
            if equip_set[settings.accuracy[i]] then
                return settings.accuracy[i]
            end
        end
    end
})

do
    -- Weapon lock rule
    local function return_true() return true end
    local function lock_weapons_test(equip_set, spell)
        if not settings.lock_weapons.value then
            equip_set.swap_managed_weapon = return_true
        end
    end
    rules.idle:append({test = lock_weapons_test})
    rules.engaged:append({test = lock_weapons_test})
    rules.precast:append({test = lock_weapons_test})
    rules.midcast:append({test = lock_weapons_test})
end

-- Enfeebling rules
rules.midcast:append({
    test = function(equipset, spell)
        return spell.skill == 'Enfeebling Magic' and spell.type == 'WhiteMagic'
    end,
    key = 'MndEnfeebles'
})

-- rules.midcast:append({
--     test = function(equipset, spell)
--         return spell.skill == 'Enfeebling Magic' and spell.type ~= 'WhiteMagic'
--     end,
--     key = 'IntEnfeebles'
-- })

local function dw_sub_job()
    return player.sub_job == 'NIN' or player.sub_job == 'DNC'
end

events.load:register(function()
    do
        local cities = S {
            'Ru\'Lude Gardens', 'Upper Jeuno', 'Lower Jeuno', 'Port Jeuno',
            'Port Windurst', 'Windurst Waters', 'Windurst Woods',
            'Windurst Walls', 'Heavens Tower', 'Port San d\'Oria',
            'Northern San d\'Oria', 'Southern San d\'Oria',
            'Chateau d\'Oraguille', 'Port Bastok', 'Bastok Markets',
            'Bastok Mines', 'Metalworks', 'Aht Urhgan Whitegate',
            'The Colosseum', 'Tavanazian Safehold', 'Nashmau', 'Selbina',
            'Mhaura', 'Rabao', 'Norg', 'Kazham', 'Eastern Adoulin',
            'Western Adoulin', 'Celennia Memorial Library', 'Mog Garden',
            'Leafallia'
        }
        sets.idle = {
            main = 'Malignance Pole',
            sub = 'Mensch Strap +1',
            ammo = 'Staunch Tathlum +1',
            head = 'Inyanga Tiara +2',
            body = 'Piety Briault +3',
            hands = 'Inyan. Dastanas +2',
            legs = 'Assiduity Pants +1', -- 'Inyanga Shalwar +2',
            feet = 'Inyan. Crackows +2',
            neck = 'Loricate Torque +1',
            waist = 'Fucho-no-Obi',
            left_ear = 'Thureous Earring',
            right_ear = 'Etiolation Earring',
            left_ring = 'Inyanga Ring',
            right_ring = 'Gelatinous Ring',
            back = gear.Alaunus.Meva,

            swap_managed_weapon = function()
                return cities[world.area]
            end,
            swaps = {
                {
                    test = pred_factory.mp_lt(500),
                    ammo = 'Homilary',
                    legs = 'Assiduity Pants +1',
                    right_ring = 'Stikini Ring +1'
                }, {
                    test = pred_factory.buff_active('Sublimation: Activated'),
                    waist = 'Embla Sash'
                }, {
                    test = function()
                        return cities[world.area]
                    end,
                    main = 'Yagrush',
                    sub = 'Mjollnir',
                    ammo = 'Homiliary',
                    head = 'Piety Cap +3',
                    body = 'Piety Briault +3',
                    hands = 'Piety Mitts +3',
                    legs = 'Piety Pantaln. +3',
                    feet = 'Piety Duckbills +3',
                    neck = 'Cleric\'s Torque +2',
                    waist = 'Prosilio Belt +1',
                    left_ear = 'Regal Earring',
                    right_ear = 'Etiolation Earring',
                    right_ring = "Stikini Ring +1"
                }
            }
        }
    end

    sets.precast = {
        main = gear.Grioavolr.FC,
        sub = 'Clerisy Strap',
        ammo = 'Impatiens',
        head = gear.Vanya.Head.PathD,
        body = 'Inyanga Jubbah +2',
        hands = gear.Chironic.Hands.FC,
        legs = 'Aya. Cosciales +2',
        feet = 'Regal Pumps +1',
        neck = 'Cleric\'s Torque +2',
        waist = 'Witful Belt',
        left_ear = 'Etiolation earring',
        right_ear = 'Malignance Earring',
        left_ring = 'Kishar Ring',
        right_ring = 'Prolix Ring',
        back = gear.Alaunus.FC
    }

    sets.precast.Cure = set_combine(sets.precast, {
        head = 'Piety Cap +3',
        legs = 'Ebers Pantaloons +1',
        feet = gear.Vanya.Feet.PathB,
        left_ear = 'Nourishing Earring +1'
    })

    sets.precast.StatusRemoval = set_combine(sets.precast,
                                             {legs = 'Ebers Pantaloons +1'})

    sets.precast['Enhancing Magic'] = set_combine(sets.precast,
                                                  {waist = 'Siegal Sash'})

    sets.precast.Stoneskin = set_combine(sets.precast, {
        head = 'Umuthi Hat',
        waist = 'Siegal Sash'
    })

    sets.precast.Utsusemi = set_combine(sets.precast, {neck = 'Magoraga Beads'})

    sets.precast.Dispelga = set_combine(sets.precast, {
        main = 'Daybreak',
        sub = 'C. Palug Hammer',
        swap_managed_weapon = function() return true end
    })

    sets.JA = {}
    sets.JA.Benediction = {body = 'Piety Briault +3'}
    sets.JA.Devotion = {head = 'Piety Cap +3'}
    sets.JA.Martyr = {hands = 'Piety Mitts +3'}

    sets.JA.step = {
        head = 'Aya. Zucchetto +2',
        body = 'Ayanmo Corazza +2',
        hands = 'Aya. Manopolas +2',
        legs = 'Aya. Cosciales +2',
        feet = 'Aya. Gambieras +2',
        neck = 'Sanctity Necklace',
        waist = 'Eschan Stone',
        left_ear = 'Telos Earring',
        left_ring = 'Ayanmo Ring',
        back = gear.Alaunus.DEX_DA
    }

    sets.midcast = {
        main = 'Malignance Pole',
        sub = 'Clerisy Strap',
        ammo = 'Staunch Tathlum +1',
        head = gear.Vanya.Head.PathD,
        body = 'Inyanga Jubbah +2',
        hands = gear.Chironic.Hands.FC,
        legs = 'Aya. Cosciales +2',
        feet = 'Regal Pumps +1',
        neck = 'Cleric\'s Torque +2',
        waist = 'Embla Sash',
        left_ear = 'Nourishing Earring +1',
        right_ear = 'Etiolation Earring',
        left_ring = 'Kishar Ring',
        right_ring = 'Prolix Ring',
        back = gear.Alaunus.FC
    }

    local cure_weapons = S {'Mjollnir', 'Izcalli', 'Daybreak'}
    sets.midcast.Cure = {
        main = gear.RaeticRod1,
        sub = 'Genmei Shield',
        ammo = 'Hydrocera',
        head = gear.Kaykaus.Head.PathC,
        body = gear.Kaykaus.Body.PathC,
        hands = 'Theophany Mitts +3',
        legs = 'Ebers Pantaloons +1',
        feet = gear.Kaykaus.Feet.PathC,
        neck = 'Cleric\'s Torque +2',
        waist = 'Luminary Sash',
        left_ear = 'Glorious Earring',
        right_ear = 'Nourish. Earring +1',
        left_ring = 'Kishar Ring',
        right_ring = 'Gelatinous Ring +1',
        back = gear.Alaunus.Meva,
        swaps = {
            {test = pred_factory.elemental_obi_bonus(1), waist = 'Korin Obi'},
            {
                test = function()
                    return settings.lock_weapons.value and
                               buffactive['Aflatus Solace'] and
                               (cure_weapons[settings.main.value] or
                                   cure_weapons[settings.sub.value])
                end,
                hands = gear.Kaykaus.Hands.PathC
            }, {test = dw_sub_job, sub = gear.RaeticRod2},
            {
                test = pred_factory.buff_active('Afflatus Solace'),
                body = 'Ebers Bliaud +1'
            }
        }
    }

    sets.midcast['Full Cure'] = set_combine(sets.midcast.Cure, {
        head = gear.Vanya.Head.PathD,
        legs = 'Aya. Cosciales +2',
        waist = 'Embla Sash',
        back = gear.Alaunus.FC
    })

    sets.midcast.Curaga = set_combine(sets.midcast.Cure, {})

    sets.midcast.StatusRemoval = set_combine(sets.midcast, {
        main = 'Yagrush',
        head = 'Ebers Cap +1',
        legs = 'Ebers Pantaloons +1',
        neck = 'Cleric\'s Torque +2',
        swaps = {
            {
                test = pred_factory.buff_active('Divine Caress'),
                hands = 'Ebers Mitts +1',
                back = 'Mending Cape'
            }
        }
    })

    sets.midcast.Cursna = {
        sub = 'Genmei Shield',
        ammo = 'Impatiens',
        head = gear.Vanya.Head.PathB,
        body = 'Ebers Bliaud +1',
        hands = 'Fanatic Gloves',
        legs = 'Th. Pantaloons +3',
        feet = gear.Vanya.Feet.PathB,
        neck = 'Debilis Medallion',
        waist = 'Luminary Sash',
        left_ear = 'Andoaa Earring',
        right_ear = 'Malignance Earring',
        left_ring = 'Haoma\'s Ring',
        right_ring = 'Menelaus\'s Ring',
        back = gear.Alaunus.Meva,
        swaps = {
            {
                test = pred_factory.buff_active('Divine Caress'),
                hands = 'Ebers Mitts +1',
                back = 'Mending Cape'
            }
        }
    }

    sets.midcast.Cursna.AoE = set_combine(sets.midcast.Cursna, {
        main = 'Yagrush',
        swaps = {
            {test = dw_sub_job, sub = 'Gambanteinn'}, {
                test = pred_factory.buff_active('Divine Caress'),
                hands = 'Ebers Mitts +1',
                back = 'Mending Cape'
            }, {
                test = function()
                    return
                        settings.lock_weapons.value and settings.main.value ~=
                            'Yagrush'
                end,
                head = 'Ebers Cap +1'
            }

        }
    })

    sets.midcast.Cursna['Single Target'] =
        set_combine(sets.midcast.Cursna, {
            main = 'Gambanteinn',
            swaps = {{test = dw_sub_job, main = 'Yagrush', sub = 'Gambanteinn'}}
        })

    local function enhancing_weapon_swap_test()
        return player.tp < 500 and not buffactive['Aftermath: Lv.3']
    end
    sets.midcast['Enhancing Magic'] = {
        main = 'Gada',
        sub = 'Ammurapi Shield',
        head = gear.Telchine.Head.Enhancing,
        body = gear.Telchine.Body.Enhancing,
        hands = gear.Telchine.Hands.Enhancing,
        legs = gear.Telchine.Legs.Enhancing,
        feet = 'Theo. Duckbills +3',
        neck = 'Melic Torque', -- Incanter's Torque
        waist = 'Embla Sash',
        right_ring = 'Stikini Ring +1',
        left_ear = 'Andoaa Earring',
        right_ear = 'Malignance Earring',
        back = gear.Alaunus.Meva,
        swap_managed_weapon = enhancing_weapon_swap_test
    }

    sets.midcast.BoostSpell = {
        main = 'Gada',
        sub = 'Ammurapi Shield',
        ammo = 'Staunch Tathlum +1',
        head = gear.Telchine.Head.Enhancing,
        body = gear.Telchine.Body.Enhancing,
        hands = 'Inyan. Dastanas +2',
        legs = 'Piety Pantaloons +3',
        feet = 'Theo. Duckbills +3',
        neck = 'Melic Torque', -- Incanters
        waist = 'Embla Sash',
        left_ear = 'Andoaa Earring',
        right_ear = 'Gwati Earring',
        left_ring = 'Inyanga Ring',
        right_ring = 'Stikini Ring +1',
        back = gear.Alaunus.Meva,
        swap_managed_weapon = enhancing_weapon_swap_test,
        swaps = {
            {
                test = pred_factory.buff_active('Light Arts'),
                legs = gear.Telchine.Legs.Enhancing
            }, { -- If we're not swapping weapons, cap skill through belt
                test = function()
                    return settings.lock_weapons.value and
                               not enhancing_weapon_swap_test()

                end,
                waist = 'Olympus Sash'
            }, {
                test = function()
                    return settings.lock_weapons.value and
                               not enhancing_weapon_swap_test() and
                               buffactive['Light Arts']
                end,
                waist = 'Fucho-no-Obi', -- Embala Sash
                legs = 'Piety Pantaloons +3'
            }
        }
    }

    sets.midcast.Shellra = set_combine(sets.midcast['Enhancing Magic'],
                                       {left_ring = 'Sheltered Ring'})

    sets.midcast.Protectra = set_combine(sets.midcast['Enhancing Magic'],
                                         {left_ring = 'Sheltered Ring'})

    sets.midcast.BarElement = {
        main = 'Gada',
        sub = 'Ammurapi Shield',
        head = 'Befouled Crown',
        body = 'Ebers Bliaud +1',
        hands = 'Inyan. Dastanas +2',
        legs = 'Piety Pantaloons +3',
        feet = 'Ebers Duckbills +1',
        neck = 'Melic Torque',
        waist = 'Olympus Sash',
        left_ear = 'Thureous Earring',
        right_ear = 'Nourish. Earring +1',
        left_ring = 'Sheltered Ring',
        right_ring = 'Stikini Ring +1',
        back = gear.Alaunus.Meva,
        swap_managed_weapon = enhancing_weapon_swap_test
    }

    sets.midcast.BarElement.Potency = set_combine(sets.midcast.BarElement, {
        swaps = {
            {
                test = pred_factory.buff_active('Light Arts'),
                main = 'Beneficus',
                ammo = 'Homilary',
                head = 'Ebers Cap +1',
                body = 'Ebers Bliaud +1',
                hands = 'Ebers Mitts +1',
                legs = 'Piety Pantaloons +3',
                feet = 'Ebers Duckbills +1'
            }, {
                test = function()
                    return settings.lock_weapons.value and
                               not enhancing_weapon_swap_test()
                end,
                head = 'Befouled Crown'
            }
        }
    })

    sets.midcast.BarElement.Duration = table.copy(
                                           sets.midcast['Enhancing Magic'])

    sets.midcast.Regen = {
        main = 'Bolelabunga',
        sub = 'Ammurapi Shield',
        head = 'Inyanga Tiara +2',
        body = 'Piety Briault +3',
        hands = 'Ebers Mitts +1',
        legs = 'Th. Pantaloons +3',
        feet = gear.Telchine.Feet.Regen,
        waist = 'Embla Sash',
        back = gear.Alaunus.Meva,
        swap_managed_weapon = enhancing_weapon_swap_test
    }

    sets.midcast.Regen.Potency = set_combine(sets.midcast.Regen, {})
    sets.midcast.Regen.Duration = {
        main = 'Gada',
        sub = 'Ammurapi Shield',
        head = gear.Telchine.Head.Enhancing,
        body = gear.Telchine.Body.Enhancing,
        hands = 'Ebers Mitts +1',
        legs = 'Th. Pantaloons +3',
        feet = 'Theo. Duckbills +3',
        waist = 'Embla Sash',
        back = gear.Alaunus.Meva,
        swap_managed_weapon = enhancing_weapon_swap_test
    }

    sets.midcast.Stoneskin = set_combine(sets.midcast['Enhancing Magic'], {
        waist = 'Siegal Sash',
        neck = 'Nodens Gorget'
    })

    sets.midcast.Auspice = set_combine(sets.midcast['Enhancing Magic'],
                                       {feet = 'Ebers Duckbills +1'})

    sets.SIRD = {
        ammo = 'Staunch Tathlum +1',
        head = gear.Kaykaus.Head.PathC,
        hands = 'Chironic Gloves',
        feet = 'Theophany Duckbills +3',
        waist = 'Rumination Sash',
        right_ear = 'Nourish. Earring +1',
        right_ring = 'Evanescence Ring'
    }
    sets.ConserveMP = {
        ammo = 'Pemphredo Tathlum',
        head = gear.Vanya.Head.PathD,
        body = 'Chironic Doublet',
        waist = 'Luminary Sash',
        left_ear = 'Gwati Earring',
        back = 'Solemnity Cape'
    }

    sets.midcast.Utsusemi = table.copy(sets.SIRD)
    sets.midcast.Raise = {}
    sets.midcast.Raise.Recast = set_combine(sets.midcast, {
        swap_managed_weapon = enhancing_weapon_swap_test
    })
    sets.midcast['Conserve MP'] = set_combine(sets.midcast, sets.ConserveMP, {
        swap_managed_weapon = enhancing_weapon_swap_test
    })
    sets.midcast.Raise.SIRD = set_combine(sets.midcast, sets.SIRD, {
        swap_managed_weapon = enhancing_weapon_swap_test
    })
    sets.midcast.Reraise = set_combine(sets.midcast, sets.ConserveMP, sets.SIRD,
                                       {
        swap_managed_weapon = enhancing_weapon_swap_test
    })
    sets.midcast.Teleport = set_combine(sets.midcast, sets.SIRD, {
        swap_managed_weapon = enhancing_weapon_swap_test
    })
    sets.midcast.Warp = set_combine(sets.midcast, sets.SIRD, {
        swap_managed_weapon = enhancing_weapon_swap_test
    })

    sets.midcast['Enfeebling Magic'] = {
        main = 'Yagrush',
        sub = 'Ammurapi Shield',
        ammo = 'Pemphredo Tathlum',
        head = 'Theophany Cap +3',
        body = 'Theophany Briault +3',
        hands = 'Theophany Mitts +3',
        legs = gear.Chironic.Legs.INT_Enfeeble,
        feet = 'Theophany Duckbills +3',
        neck = 'Erra Pendant',
        waist = 'Acuity Belt +1',
        left_ear = 'Malignance Earring',
        right_ear = 'Regal Earring',
        left_ring = 'Metamorph Ring +1',
        right_ring = 'Stikini Ring +1',
        back = gear.Alaunus.INT_Enfeeble,
        swap_managed_weapon = enhancing_weapon_swap_test,
        swaps = {{test = dw_sub_job, sub = 'C. Palug Hammer'}}
    }

    sets.midcast['Enfeebling Magic'].MndEnfeebles = set_combine(sets.midcast['Enfeebling Magic'], {
        waist = 'Luminary Sash',
        back = gear.Alaunus.MND_Enfeeble,
        swaps = {{test = dw_sub_job, sub = 'Daybreak'}}
    })

    sets.midcast.Paralyze = set_combine(sets.midcast['Enfeebling Magic'].MndEnfeebles, {
        main = 'Daybreak',
        swaps = {{test = dw_sub_job, sub = 'C. Palug Hammer'}}
    })

    sets.midcast.Slow = set_combine(sets.midcast['Enfeebling Magic'].MndEnfeebles, {
        main = 'Daybreak',
        swaps = {{test = dw_sub_job, sub = 'C. Palug Hammer'}}
    })

    sets.midcast.Repose = table.copy(sets.midcast['Enfeebling Magic'].MndEnfeebles)
    sets.midcast.Stun = table.copy(sets.midcast['Enfeebling Magic'].MndEnfeebles)

    sets.midcast.Dispelga = set_combine(sets.midcast['Enfeebling Magic'], {
        main = 'Daybreak',
        sub = 'Ammurapi Shield',
        swaps = {{test = dw_sub_job, sub = 'C. Palug Hammer'}},
        swap_managed_weapon = function() return true end
    })

    sets.midcast['Divine Magic'] = table.copy(sets.midcast['Enfeebling Magic'])
    sets.midcast['Dark Magic'] = set_combine(sets.midcast['Divine Magic'], {
        waist = 'Fucho-no-Obi',
        left_ring = 'Evanescence Ring',
        right_ring = 'Excelsis Ring'
    })
    sets.midcast['Elemental Magic'] = table.copy(sets.midcast['Divine Magic'])

    sets.midcast.Holy = {
        ammo = 'Pemphredo Tathlum',
        head = 'C. Palug Crown',
        body = gear.Chironic.Body.MAB,
        hands = gear.Chironic.Hands.MAB,
        legs = gear.Kaykaus.Legs.PathD,
        feet = gear.Chironic.Feet.MAB,
        neck = 'Saevus Pendant +1',
        waist = 'Refolccilation Stone',
        left_ear = 'Friomisi Earring',
        right_ear = 'Malignance Earring',
        left_ring = 'Weatherspoon Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.MND_Enfeeble,
        swaps = {
            {test = pred_factory.orpheus_ele, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.elemental_obi, waist = 'Korin Obi'}
        }
    }

    -- Engaged Sets
    sets.engaged = {
        ammo = 'Amar Cluster',
        head = 'Ayanmo Zucchetto +2',
        body = 'Ayanmo Corazza +2',
        hands = 'Gazu Bracelet +1',
        legs = gear.Telchine.Legs.STP_WSD, -- ? Re-enchant to STP_DEX
        feet = 'Ayanmo Gambieras +2',
        neck = 'Combatant\'s Torque',
        waist = 'Windbuffet Belt +1',
        left_ear = 'Telos Earring',
        right_ear = 'Cessance Earring',
        left_ring = gear.Chirich1,
        right_ring = gear.Chirich2,
        back = gear.Alaunus.DEX_DA,
        swaps = {
            {
                test = pred_factory.buff_active('Aftermath: Lv.3'),
                back = gear.Alaunus.STP
            }
        }
    }

    sets.engaged.DW9 = set_combine(sets.engaged, {
        back = gear.Alaunus.DW, -- Make a 9 DW cape
        swaps = {
            {
                test = pred_factory.buff_active('Aftermath: Lv.3')
                -- back = gear.Alaunus.STP,
                -- left_ear = 'Eabani Earring',
                -- right_ear = 'Suppanomimi'
            }
        }
    })

    sets.engaged.DW11 = set_combine(sets.engaged, {
        waist = 'Shetal Stone',
        right_ear = 'Suppanomimi'
    })

    sets.engaged.DW15 = set_combine(sets.engaged, {
        back = gear.Alaunus.DW, -- 10 DW cape
        right_ear = 'Suppanomimi'
    })

    sets.engaged.DW21 = set_combine(sets.engaged.DW11, {back = gear.Alaunus.DW})

    sets.engaged.DW25 = set_combine(sets.engaged.DW21, {
        -- left_ear = 'Eabani Earring'
    })

    sets.WS = {
        ammo = 'Amar Cluster',
        head = 'Piety Cap +3',
        body = 'Piety Briault +3',
        hands = 'Piety Mitts +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Cleric\'s Torque +2',
        waist = 'Prosilio Belt +1',
        left_ear = 'Moonshade Earring',
        right_ear = 'Ishvara Earring',
        left_ring = 'Iliabrat Ring',
        right_ring = 'Epaminondas\'s Ring',
        back = gear.Alaunus.STR_WSD,
        swaps = {{test = pred_factory.etp_gt(2750), left_ear = 'Regal Earring'}}
    }

    sets.WS['Black Halo'] = {
        ammo = 'Hydrocera',
        head = 'Piety Cap +3',
        body = 'Ayanmo Corazza +2',
        hands = 'Piety Mitts +3',
        legs = gear.Telchine.Legs.STP_WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Cleric\'s Torque +2',
        waist = 'Windbuffet Belt +1',
        ring1 = 'Ayanmo Ring',
        ring2 = 'Metamorph Ring +1',
        left_ear = 'Moonshade Earring',
        right_ear = 'Regal Earring',
        back = gear.Alaunus.MND_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), left_ear = 'Ishvara Earring'}
        }
    }

    sets.WS['Black Halo'].mid = set_combine(sets.WS['Black Halo'],
                                            {legs = 'Piety Pantaloons +3'})

    sets.WS['Mystic Boon'] = {
        ammo = 'Hydrocera',
        head = 'Piety Cap +3',
        body = 'Piety Briault +3',
        hands = 'Piety Mitts +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Cleric\'s Torque +2',
        waist = 'Luminary Sash',
        ring1 = 'Epaminondas\'s Ring',
        ring2 = 'Metamorph Ring +1',
        left_ear = 'Moonshade Earring',
        right_ear = 'Regal Earring',
        back = gear.Alaunus.MND_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), left_ear = 'Ishvara Earring'}
        }
    }

    sets.WS['Mystic Boon'].Mid = set_combine(sets.WS['Mystic Boon'],
                                             {legs = 'Piety Pantaloons +3'})

    sets.WS.Judgment = {
        ammo = 'Amar Cluster',
        head = 'Piety Cap +3',
        body = 'Piety Briault +3',
        hands = 'Piety Mitts +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Cleric\'s Torque',
        waist = 'Prosilio Belt +1',
        left_ear = 'Moonshade Earring',
        right_ear = 'Regal Earring',
        left_ring = 'Epaminondas\'s Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.STR_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), left_ear = 'Ishvara Earring'}
        }
    }

    sets.WS.Judgment.Mid = set_combine(sets.WS.Judgment,
                                       {legs = 'Piety Pantaloons +3'})

    -- Quick math suggests we want between 16 and 40% DA
    sets.WS['Hexa Strike'] = {
        ammo = 'Yetshila +1',
        head = 'Blistering Sallet +1',
        body = 'Ayanmo Corazza +2',
        hands = 'Piety Mitts +3',
        legs = 'Piety Pantaloons +3',
        feet = 'Ayanmo Gambieras +2',
        neck = 'Flame Gorget',
        waist = 'Flame Belt',
        left_ear = 'Brutal Earring',
        right_ear = 'Moonshade Earring',
        left_ring = 'Ilabrat Ring',
        right_ring = 'Begrudging Ring',
        back = gear.Alaunus.STR_Crit,
        swaps = {
            {test = pred_factory.etp_gt(2750), right_ear = 'Cessance Earring'}
        }
    }

    sets.WS.Realmrazer = {
        ammo = 'Hydrocera',
        head = 'Piety Cap +3',
        body = 'Ayanmo Corazza +2',
        hands = 'Piety Mitts +3',
        legs = 'Piety Pantaloons +3',
        feet = 'Piety Duckbills +3',
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        left_ear = 'Moonshade Earring',
        right_ear = 'Regal Earring',
        left_ring = 'Ayanmo Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.MND_DA,
        swaps = {{test = pred_factory.etp_gt(2750), left_ear = 'Telos Earring'}}
    }

    sets.WS.Dagan = {
        ammo = 'Hydrocera',
        head = 'Ebers Cap +1',
        body = 'Ebers Bliaud +1',
        hands = 'Theophany Mitts +3',
        legs = 'Piety Pantaloons +3',
        feet = 'Theophany Duckbills +3',
        neck = 'Cleric\'s Torque +2',
        waist = 'Luminary Sash',
        left_ear = 'Moonshade Earring',
        right_ear = 'Etiolation Earring',
        left_ring = 'Prolix Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.Meva,
        swaps = {{test = pred_factory.etp_gt(2750), left_ear = 'Regal Earring'}}
    }

    sets.WS['Flash Nova'] = {
        ammo = 'Pemphredo Tathlum',
        head = 'C. Palug Crown',
        body = gear.Chironic.Body.MAB,
        hands = gear.Chironic.Hands.MAB,
        legs = gear.Kaykaus.Legs.PathD,
        feet = gear.Chironic.Feet.MAB,
        neck = 'Saevus Pendant +1',
        waist = 'Orpheus\'s Sash',
        left_ear = 'Moonshade Earring',
        right_ear = 'Malignance Earring',
        left_ring = 'Weatherspoon Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.MND_Enfeeble,
        swaps = {
            {test = pred_factory.orpheus_ele, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.elemental_obi, waist = 'Korin Obi'},
            {test = pred_factory.etp_gt(2750), left_ear = 'Friomisi Earring'}
        }
    }

    sets.WS['Seraph Strike'] = set_combine(sets.WS['Flash Nova'], {})

    sets.WS.Randgrith = {
        ammo = 'Amar Cluster',
        head = gear.Chironic.Head.WSD,
        body = 'Piety Briault +3',
        hands = 'Piety Mitts +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Cleric\'s Torque +2',
        waist = 'Prosilio Belt +1',
        left_ear = 'Regal Earring',
        right_ear = 'Ishvara Earring',
        left_ring = 'Epaminondas\'s Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.STR_WSD
    }

    sets.WS.Randgrith.Mid = set_combine(sets.WS.Randgrith,
                                     {legs = 'Piety Pantaloons +3'})

    sets.WS.Brainshaker = {
        ammo = 'Pemphredo Tathlum',
        head = 'Theophany Cap +3',
        body = 'Theophany Briault +3',
        hands = gear.Kaykaus.Hands.PathA,
        legs = 'Theophany Pantaloons +3',
        feet = 'Theophany Duckbills +3',
        neck = 'Erra Pendant',
        waist = 'Acuity Belt +1',
        left_ear = 'Malignance Earring',
        right_ear = 'Regal Earring',
        left_ring = 'Stikini Ring +1',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.MND_Enfeeble
    }

    sets.WS.Shattersoul = {
        ammo = 'Pemphredo Tathlum',
        head = 'Piety Cap +3',
        body = 'Ayanmo Corazza +2',
        hands = 'Piety Mitts +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        left_ear = 'Moonshade Earring',
        right_ear = 'Telos Earring',
        left_ring = 'Ilabrat Ring',
        right_ring = 'Petrov Ring',
        back = gear.Alaunus.INT_DA,
        swaps = {{test = pred_factory.etp_gt(2750), left_ear = 'Regal Earring'}}
    }

    sets.WS.Retribution = {
        ammo = 'Hydrocera',
        head = 'Piety Cap +3',
        body = 'Piety Briault +3',
        hands = 'Piety Mitts +3',
        legs = gear.Chironic.Legs.WSD,
        feet = 'Piety Duckbills +3',
        neck = 'Cleric\'s Torque +2',
        waist = 'Luminary Sash',
        left_ear = 'Moonshade Earring',
        right_ear = 'Regal Earring',
        left_ring = 'Epaminondas\'s Ring',
        right_ring = 'Metamorph Ring +1',
        back = gear.Alaunus.MND_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), left_ear = 'Ishvara Earring'}
        }
    }

    sets.WS.Cataclysm = {
        ammo = 'Pemphredo Tathlum',
        head = 'Pixie Hairpin +1',
        body = gear.Chironic.Body.MAB,
        hands = gear.Chironic.Hands.MAB,
        legs = gear.Kaykaus.Legs.PathD,
        feet = gear.Chironic.Feet.MAB,
        neck = 'Saevus Pendant +1',
        waist = 'Orpheus\'s Sash',
        left_ear = 'Moonshade Earring',
        right_ear = 'Malignance Earring',
        left_ring = 'Freke Ring',
        right_ring = 'Archon Ring',
        back = gear.Alaunus.STR_WSD, -- Make a str macc/matk wsd cape at some point
        swaps = {
            {test = pred_factory.orpheus_ele, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.elemental_obi, waist = 'Anrin Obi'},
            {test = pred_factory.etp_gt(2750), left_ear = 'Friomisi Earring'}
        }
    }

    sets.WS['Shell Crusher'] = table.copy(sets.WS.Brainshaker)
end)

local solace_charge = 0
local misery_charge = 0
local player_id = windower.ffxi.get_player().id
windower.raw_register_event('action', function(act)
    if act.actor_id == player_id and act.category == 4 then
        if act.param < 12 or act.param == 893 then -- cure spells
            for _, target in ipairs(act.targets) do
                solace_charge = solace_charge + target.actions[1].param
            end
        end
    end
end)

-- zero charge when casting associated spells
events.aftercast:register(function(spell)
    if spell.english:contains('Holy') then
        solace_charge = 0
    elseif spell.english:contains('Banish') then
        misery_charge = 0
    end
end)

-- zero out the charges when gaining/losing buffs
events.buff_change:register(function(buff, gain)
    if buff == 'Afflatus Solace' then
        solace_charge = 0
    elseif buff == 'Afflatus Misery' then
        misery_charge = 0
    end
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
            local item_name = type(el) == 'table' and el.name or el
            local value = type(el) == 'table' and el.alias or item_name
            local img
            if windower.file_exists(windower.addon_path .. '/data/graphics/' ..
                                        item_name .. '.png') then
                img = windower.addon_path .. '/data/graphics/' .. item_name ..
                          '.png'
            elseif windower.file_exists(windower.addon_path ..
                                            '/data/graphics/WHM/' .. item_name ..
                                            '.png') then
                img =
                    windower.addon_path .. '/data/graphics/WHM/' .. item_name ..
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

    local sub_button

    local main_proxy = M {'Auto', unpack(settings.main)}
    main_proxy.on_change:register(function(m)
        if m.value == 'Auto' then
            settings.lock_weapons:unset()
            sub_button:hide()
        else
            settings.main:set(m.value)
            sub_button:show()
        end
    end)
    IconButton({
        x = GUI_x,
        y = GUI_y,
        var = main_proxy,
        icons = get_icons(main_proxy)
    }):draw()

    GUI_y = GUI_y + 54

    sub_button = IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.sub,
        icons = get_icons(settings.sub)
    })
    sub_button:draw()
    sub_button:hide()
    settings.sub.on_option_change:register(
        function()
            sub_button:new_icons(get_icons(settings.sub))
            -- if main_proxy.value == 'Auto' then
            --     sub_button:hide() end
        end)

    GUI_y = GUI_y + 54

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.accuracy,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.Regen,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.BarElement,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.Cursna,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.Raise,
        align = 'left',
        width = 112
    }):draw()

    GUI_y = GUI_y + 32

    local show_dw = player.sub_job ~= 'NIN' and player.sub_job ~= 'DNC'
    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_mode,
        align = 'left',
        width = 112,
        start_hidden = show_dw,
        disabled = show_dw
    }):draw()

    GUI_y = GUI_y + 32

    TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_level,
        align = 'left',
        width = 112,
        command = function() settings.dual_wield_mode:set('Manual') end,
        start_hidden = show_dw,
        disabled = show_dw
    }):draw()

    GUI_y = GUI_y + 32

    PassiveText({ -- ? Does passive text let you change the color?
		x = GUI_x,
		y = GUI_y,
		text = 'Afflatus Solace Charge: %s',
		align = 'left'},
        function() 
            return (solace_charge > 1300 and 1300 or solace_charge) / 13
        end):draw()
end
