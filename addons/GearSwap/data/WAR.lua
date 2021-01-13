require('J-Swap')
local M = require('J-Mode')
require('GUI')
local command = require('J-Swap-Command')
local events = require('J-Swap-Events')
local bind_key = require('J-Bind')
rolls = rolls or require('J-Rolltracker')
local haste = require('J-Haste')
local pred_factory = require('J-Predicates')

local gear = require('Jyouya-gear')

bind_key('^`', 'input /ja "Provoke" <t>')
bind_key('f10', 'gs c set engaged Hybrid')
bind_key('f12', 'gs c set engaged Normal')

local main_hands = M {
    ['description'] = 'Main Hand',
    'Chango',
    'Ukonvasara',
    'Montante +1',
    'Raetic Algol +1',
    'Shining One',
    'Xoanon',
    'Drepanum',
    'Karambit',
    'Naegling',
    'Tanmogayi +1',
    'Dolichenus',
    'Farsha',
    'Beryllium Mace +1',
    gear.Malevolence1
}

local abyssea_main_hands = M {
    ['description'] = 'Main Hand',
    'Bronze Dagger',
    'Ibushi Shinai',
    'Irradiance Blade',
    'Bronze Zaghnal',
    'Harpoon',
    'Soulflayer\'s Wand',
    'Lamia Staff',
    'Debahocho',
    'Mutsunokami',
    'Quint Spear'
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
    print('something has gone horribly wrong')
end
do
    settings.sub = M {['description'] = 'Off Hand', 'Utu Grip'}
    local subs = T {
        'Zantetsuken', 'Reikiko', 'Barbarity +1', 'Farsha', 'Fernagu', gear.Malevolence2, 'Blurred Shield +1'
    }
    local subs_1h = T {}
    local subs_1h_current = subs_1h[1]
    local function fill_subs_1h()
        if player.sub_job == 'NIN' or player.sub_job == 'DNC' then
            subs_1h = subs
        else
            subs_1h = T {}
            -- Doing this with a loop because table.filter breaks array-like tables 
            for item in table.it(subs) do
                if item_type(item) == 'shield' then
                    subs_1h:append(item)
                end
            end
        end
        subs_1h_current = subs_1h[1]
    end
    fill_subs_1h()
    for k, v in pairs(subs_1h) do print(k, v) end
    events.sub_job_change:register(fill_subs_1h)
    local subs_2h = T {'Utu Grip'}
    local prev_main_type = '2h'
    local function on_main_change(m)
        print('on main change')
        local main_type = item_type(m.value)
        print('main type: ', main_type)
        if prev_main_type ~= main_type then
            if prev_main_type == '1h' then
                subs_1h_current = settings.sub.value
            end
            prev_main_type = main_type
            if main_type == '2h' then
                settings.sub:options(subs_2h:unpack())
            elseif main_type == '1h' then
                settings.sub:options(subs_1h:unpack())
                settings.sub:set(subs_1h_current)
            else -- h2h
                settings.sub:options('Empty')
            end
        end
        windower.send_command('gs c update')
    end
    main_hands.on_change:register(on_main_change)
end

local function update_if_not_midaction()
    if not midaction() then windower.send_command('gs c update') end
end

abyssea_main_hands.on_change:register(update_if_not_midaction)
settings.sub.on_change:register(update_if_not_midaction)

settings.accuracy = M {
    ['description'] = 'Accuracy Mode',
    'Normal',
    'Mid',
    'High'
}
settings.accuracy.on_change:register(update_if_not_midaction)

settings.engaged = M {['description'] = 'Engaged Mode', 'Normal', 'Hybrid'}
settings.engaged.on_change:register(update_if_not_midaction)

do
    settings.WeaponSkill = M {'Normal', 'Abyssea'}
    settings.abyssea = M(false, 'Abyssea Mode')
    settings.abyssea.on_change:register(function(m)
        settings.WeaponSkill:set(m.value and 'Abyssea' or 'Normal')
        settings.main = m.value and abyssea_main_hands or main_hands
        update_if_not_midaction()
    end)
end

settings.main = main_hands

do -- Abyssea Mode
    local abyssea_mode_engaged = {
        test = function(equip_set)
            if settings.abyssea.value then
                equip_set.swaps = equip_set.swaps or {}
                table.append(equip_set.swaps, {
                    test = function() return true end,
                    neck = 'Combatant\'s Torque',
                    head = settings.main.value == 'Mutsunokami' and
                        'Kengo Hachimaki' or nil
                })
            end
        end
    }
    rules.engaged:append(abyssea_mode_engaged)
end

settings.dual_wield_mode = M {
    ['description'] = 'Dual Wield Mode',
    'Auto',
    'Manual'
}
settings.dual_wield_level = M {['description'] = 'Dual Wield Level', '0', '11'}

do -- Dual Wield rule
    local function dw_test()
        local main = settings.main.value
        local sub = settings.sub.value

        return (player.sub_job == 'NIN' or player.sub_job == 'DNC') and
                   item_type(main) == '1h' and item_type(sub) == '1h'

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

do -- Fencer rule
    local function fencer_test()
        local main = settings.main.value
        local sub = settings.sub.value

        return item_type(main) == '1h' and item_type(sub) == 'shield'
    end

    rules.engaged:append({test = fencer_test, key = 'Fencer'})
end

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
    local function abyssea_offhand(equip_set, spell)
        if settings.abyssea.value then
            equip_set.main = settings.main.value
            equip_set.sub = 'empty'
            equip_set.swap_managed_weapon = function() return true end
        end
    end
    rules.engaged:append({test = abyssea_offhand})
    rules.idle:append({test = abyssea_offhand})
    rules.precast:append({test = abyssea_offhand})
    rules.midcast:append({test = abyssea_offhand})
end

local fighters_roll_effect
do
    local ifrits_favor = 0
    -- Can't track favor very accurately, will assume 24 potency
    events.buff_change:register(function(buff, gain)
        if buff == 'Ifrit\'s Favor' then ifrits_favor = gain and 24 or 0 end
    end)
    fighters_roll_effect = function(value)
        return function()
            return ifrits_favor + rolls['Fighter\'s Roll'].effect_value >= value
        end
    end
end

events.load:register(function()
    windower.send_command(
        'imput /macro book 5;wait .1; input /macro set 1;wait 2;input /lockstyleset 3')

    sets.item['Holy Water'] = {neck = 'Nicander\'s Necklace', ring1 = 'Purity Ring'}

    sets.JA['Mighty Strikes'] = {hands = 'Agoge Mufflers +2'}
    sets.JA['Blood Rage'] = {body = 'Boii Lorica +1'}
    sets.JA.Warcry = {head = 'Agoge Mask +3'}
    sets.JA.Berserk = {
        main = 'Instigator',
        body = 'Pummeler\'s Lorica +3',
        feet = 'Agoge Calligae +3',
        back = gear.Cichol.VIT_WSD, -- A bit of vit to reduce enemy dSTR
        swap_managed_weapon = function()
            return player.tp < 1000 and
                       not (buffactive['Aftermath: Lv.3'] and
                           settings.main.value ~= 'Chango')
        end
    }
    sets.JA.Aggressor = {
        main = 'Instigator',
        head = 'Pummeler\'s Mask +2',
        body = 'Agoge Lorica + 3',
        swap_managed_weapon = function()
            return player.tp < 1000 and
                       not (buffactive['Aftermath: Lv.3'] and
                           settings.main.value ~= 'Chango')
        end
    }
    sets.JA.Provoke = {
        head = 'Halitus Helm',
        body = 'Emet Harness +1',
        hands = 'Pummeler\'s Mufflers +1',
        legs = gear.Odyssean.Legs.VIT_WSD,
        neck = 'Moonlight Necklace',
        waist = 'Kasiri Belt',
        ear1 = 'Friomisi Earring',
        ear2 = 'Cryptic Earring',
        ring1 = 'Petrov Ring',
        ring2 = 'Eihwaz Ring'
    }

    sets.precast = { --                                 FC 
        ammo = 'Impatiens',
        head = gear.Odyssean.Head.FC, -- 7 FC           7  
        body = 'Sacro Breastplate', -- 10 FC            17
        hands = 'Leyline Gloves', -- 8 FC               25
        legs = gear.Odyssean.Legs.FC, -- 7 FC           32
        feet = gear.Odyssean.Feet.FC, -- 12 FC          44
        neck = 'Baetyl Pendant', -- 4 FC                48
        ear1 = 'Loquacious Earring', -- 2 FC            
        ear2 = 'Etiolation Earring', -- 1 FC            
        ring1 = 'Prolix Ring', -- 2 FC                  
        ring2 = 'Gelatinous Ring +1',
        back = gear.Cichol.FC -- 10                     
    }

    sets.idle = { --                                    PDT MDT
        ammo = 'Staunch Tathlum +1', -- 3 DT            3   3
        head = 'Hjarrandi Helm', -- 10 DT               13  13
        body = 'Sacro Breastplate',
        hands = 'Agoge Mufflers +3', -- 6 PDT           19  13
        legs = 'Pummeler\'s Cuisses +3', -- 5 PDT       24  13
        feet = 'Pummeler\'s Calligae +3',
        neck = 'Loricate Torque +1', -- 6 DT            30  19
        waist = 'Asklepian Belt',
        ear1 = 'Odnowa Earring +1', -- 3 PDT, 5 MDT     33  24
        ear2 = 'Tuisto Earring',               
        ring1 = gear.MoonlightRing1, -- 5 DT            38  29
        ring2 = 'Gelatinous Ring +1', -- 7 PDT, -1 MDT  45  28
        back = 'Moonlight Cape' -- 6 DT                 51  34
    }

    sets.midcast = { --                                     DT  SIRD
        ammo = 'Staunch Tathlum +1', -- 3 DT, 11 SIRD       3   21
        head = gear.Souveran.Head.PathD, -- 4 PDT, 20 SIRD  7   41
        body = 'Hjarrandi Breastplate', -- 12 DT            19
        hands = 'Pummeler\'s Mufflers +3', -- 7 PDT         26
        legs = 'Founder\'s Hose', -- 30 SIRD                    71
        feet = gear.Odyssean.Feet.FC, -- 20 SIRD                91
        neck = 'Moonlight Necklace', -- 15 SIRD                 104
        waist = 'Flume Belt +1', -- 4 PDT                   30
        ear1 = 'Odnowa Earring +1',
        ear2 = 'Tuisto Earring', -- 2 PDT                   32
        ring1 = gear.MoonlightRing1, -- 5 DT                37
        ring2 = 'Gelatinous Ring +1', -- 7 PDT              44
        back = 'Moonlight Cape', -- 6 DT                    50
    }

    -- 33 base DA, 15 STP from /sam
    sets.engaged = { --                                      DA  TA  STP QA
        ammo = 'Aurgelmir Orb +1', -- 5 STP                         20
        head = 'Flamma Zucchetto +2', -- 5 TA, 6 STP            5   26
        body = gear.Valorous.Body.DA, -- 7 DA, 3 STP        40      29  
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA             46
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA           57
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    66      33
        neck = 'War. Beads +2', -- 7 DA               73
        waist = 'Ioskeha Belt +1', -- 9 DA                  82
        ear1 = 'Brutal Earring', -- 5 DA, 1 STP             87      34
        ear2 = 'Cessance Earring', -- 3 DA, 3 STP           90      37
        ring1 = 'Niqmaddu Ring', -- 3 QA                                3
        ring2 = gear.MoonlightRing2, -- 5 STP                          42
        back = gear.Cichol.DEX_DA, -- 10 DA                 100 5   42  3
        swaps = {
            { -- 1 or 9, regal
                test = fighters_roll_effect(13),
                body = 'Hjarrandi Breastplate', -- -7 DA, +7 STP
                hands = gear.Emicho.Hands.PathB -- -6 DA, +7 STP
            }, { --
                test = fighters_roll_effect(15),
                ear2 = 'Telos Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(17),
                ear1 = 'Cessance Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(20),
                ear1 = 'Dedition Earring' -- -3 DA, +5 STP
            }, {
                test = fighters_roll_effect(23),
                ear1 = 'Brutal Earring', -- +2 DA, -2 STP
                ear2 = 'Cessance Earring', -- + 2 DA, -2 STP
                back = gear.Cichol.DEX_STP -- - 10 DA, +10 STP
            }, {
                test = fighters_roll_effect(25),
                ear2 = 'Telos Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(27),
                ear1 = 'Cessance Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(29),
                legs = gear.Odyssean.Legs.STP, -- -9 DA, + 12 STP
                ear1 = 'Dedition Earring', -- -3 DA, +5 STP
                back = gear.Cichol.DEX_DA -- +10 DA, - 10 STP
            }, {
                test = fighters_roll_effect(33),
                hands = 'Sulevia\'s Gauntlets +2', -- +6 DA, -7 STP
                back = gear.Cichol.DEX_STP -- - 10 DA, + 10 STP
            }, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }

    sets.engaged.DW11 = { --                                DA  STP TA  QA  DW
        ammo = 'Aurgelmir Orb +1', -- 5 STP                 33  5   0   0   0
        head = 'Hjarrandi Helm', -- 6 DA, 7 STP             39  12
        body = gear.Emicho.Body.PathB, -- 9 DA              48
        hands = gear.Emicho.Hands.PathD, -- 7 STP, 6 DW         18          6
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA           59
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    68  22
        neck = 'War. Beads +2', -- 7 DA                     75
        waist = 'Ioskeha Belt +1', -- 9 DA                  84
        ear1 = 'Brutal Earring', -- 5 DA , 1 STP            89  23
        ear2 = 'Suppanomimi', -- 5 DW                                       11
        ring1 = 'Niqmaddu Ring', -- 3 QA                                3
        ring2 = 'Petrov Ring', -- 1 DA, 5 STP               90  28
        back = gear.Cichol.DEX_DA, -- 10 DA                 100
        swaps = {
            {
                test = fighters_roll_effect(11),
                head = 'Flamma Zucchetto +2', -- -6 DA, -1 STP, +5 TA
                ear1 = 'Dedition Earring' -- -5 DA, +7 STP
            }, {
                test = fighters_roll_effect(13),
                body = gear.Valorous.Body.DA -- -2 DA, +3 STP
            }, {
                test = fighters_roll_effect(20),
                body = 'Hjarrandi Breastplate' -- -7 DA, +7 STP
            }, {
                test = fighters_roll_effect(30),
                back = gear.Cichol.DEX_STP -- -10 DA, +10 STP
            }, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                            pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'

            }
        }
    }

    sets.engaged.Farsha = {}
    sets.engaged.Farsha.AM3 = { --                          DA
        ammo = 'Yetshila +1', --            
        head = 'Flamma Zucchetto +2', -- 5 TA, 7 STP
        body = 'Hjarrandi Breastplate', -- 10 STP, 12 DT
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA          39
        legs = 'Agoge Cuisses +3', -- 6 DA                  45
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    54
        neck = 'War. Beads +2', -- 7 DA               61
        waist = 'Ioskeha Belt +1', -- 9 DA                  70
        ear1 = 'Brutal Earring', -- 5 DA, 1 STP             75
        ear2 = 'Cessance Earring', -- 3 DA, 3 STP           78
        ring1 = 'Niqmaddu Ring', -- 3 QA
        ring2 = 'Hetairoi Ring', -- 2 TA
        back = gear.Cichol.STR_DA, -- 10 DA                 88
        swaps = {
            {test = fighters_roll_effect(18), hands = 'Flamma Manopolas +2'},
            {test = fighters_roll_effect(28), back = gear.Cichol.DEX_Crit}, {
                test = fighters_roll_effect(30),
                ear2 = 'Telos Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(32),
                ear1 = 'Cessance Earring' -- -2 DA, +2 STP
            }, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }
    sets.engaged.Farsha.AM3.DW11 = set_combine(sets.engaged.Farsha.AM3, {
        ear2 = 'Suppanomimi',
        hands = gear.Emicho.Hands.PathD,
        swaps = { -- Set has 79 DA
            {test = fighters_roll_effect(23), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(25), ear1 = 'Telos Earring'},
            {test = fighters_roll_effect(26), ear1 = 'Dedition Earring'}, {
                test = fighters_roll_effect(31),
                ear1 = 'Brutal Earring',
                back = gear.Cichol.DEX_Crit
            }, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    })

    sets.engaged.Ukonvasara = {}
    sets.engaged.Ukonvasara.AM3 = set_combine(sets.engaged.Farsha.AM3, {})

    sets.engaged.Hybrid = { --                              DA  STP PDT MDT
        ammo = 'Aurgelmir Orb +1', -- 5 STP                    20
        head = 'Hjarrandi Helm', -- 6 DA, 7 STP, 10 DT      39      10  10
        body = 'Hjarrandi Breastplate', -- 10 STP, 12 DT    39  32  22  22
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA, 5 DT    45      27  27
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA, 5 PDT    56      32
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    65  36  
        neck = 'War. Beads +2', -- 7 DA               72
        waist = 'Tempus Fugit +1',
        ear1 = 'Cessance Earring', -- 3 DA, 3 STP           75  39
        ear2 = 'Telos Earring', -- 5 STP, 1 DA              76  40
        ring1 = gear.MoonlightRing1, -- 5 STP, 5 DT             45  37  32
        ring2 = gear.MoonlightRing2, -- 5 STP, 5 DT             50  42  37
        back = gear.Cichol.DEX_DA, -- 10 DA, 10 PDT         86      52  
        swaps = {
            {
                test = fighters_roll_effect(17),
                ear1 = 'Dedition Earring' -- -3 DA, +5 STP
            }, {test = fighters_roll_effect(27), back = gear.Cichol.DEX_STP}, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }

    sets.engaged.Hybrid.DW11 = { --                         DA  STP PDT 
        ammo = 'Staunch Tathlum +1', -- 3 DT                33  0   3     
        head = 'Hjarrandi Helm', -- 6 DA, 7 STP, 10 DT      39  7   13
        body = 'Hjarrandi Breastplate', -- 10 STP, 12 DT        17  25
        hands = gear.Emicho.Hands.PathD, -- 7 STP               24
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA, 5 DT     50      30
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    59  28
        neck = 'War. Beads +2', -- 7 DA               66
        waist = 'Tempus Fugit +1',
        ear1 = 'Brutal Earring', -- 5 DA, 1 STP             71  29
        ear2 = 'Suppanomimi',
        ring1 = gear.MoonlightRing1, -- 5 STP, 5 DT             34  35
        ring2 = gear.MoonlightRing2, -- 5 STP, 5 DT             39  40
        back = gear.Cichol.DEX_DA, -- 10 DA, 10 PDT         81      50
        swaps = {
            {test = fighters_roll_effect(21), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(24), ear1 = 'Dedition Earring'}, {
                test = fighters_roll_effect(29),
                ear1 = 'Brutal Earring',
                back = gear.Cichol.DEX_STP
            }, {test = fighters_roll_effect(31), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(33), ear1 = 'Telos Earring'}, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }

    sets.engaged.Hybrid.Farsha = {}
    sets.engaged.Hybrid.Farsha.AM3 = { --                   DA  STP PDT
        ammo = 'Yetshila +1', --            
        head = 'Hjarrandi Helm', -- 6 DA, 7 STP, 10 DT      39  22  10
        body = 'Hjarrandi Breastplate', -- 10 STP, 12 DT        32  22  
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA, 5 DT    45      27
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA, 5 PDT    56      32
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    65  36  
        neck = 'War. Beads +2', -- 7 DA               72
        waist = 'Tempus Fugit +1', --                       
        ear1 = 'Brutal Earring', -- 5 DA, 1 STP             77  37
        ear2 = 'Cessance Earring', -- 3 DA, 3 STP           80  40
        ring1 = 'Niqmaddu Ring', -- 3 QA
        ring2 = gear.MoonlightRing2, -- 5 STP, 5 DT             45  37
        back = gear.Cichol.STR_DA, -- 10 DA, 10 DT          90      47
        swaps = {
            {
                test = fighters_roll_effect(12),
                ear2 = 'Telos Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(14),
                ear1 = 'Cessance Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(17),
                ear1 = 'Dedition Earring' -- -3 DA, +5 STP
            }, {
                test = fighters_roll_effect(20),
                ear1 = 'Brutal Earring',
                ear2 = 'Cessance Earring',
                back = gear.Cichol.DEX_Crit
            }, {
                test = fighters_roll_effect(22),
                ear2 = 'Telos Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(24),
                ear1 = 'Cessance Earring' -- -2 DA, +2 STP
            }, {
                test = fighters_roll_effect(27),
                ear1 = 'Dedition Earring' -- -3 DA, +5 STP
            }, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }
    sets.engaged.Hybrid.Farsha.AM3.DW11 =
        set_combine(sets.engaged.Hybrid.Farsha.AM3, {
            ear2 = 'Suppanomimi',
            hands = gear.Emicho.Hands.PathD,
            ring1 = gear.MoonlightRing1,
            swaps = { -- Set has 82 DA
                {test = fighters_roll_effect(20), ear1 = 'Cessance Earring'},
                {test = fighters_roll_effect(22), ear1 = 'Telos Earring'},
                {test = fighters_roll_effect(23), ear1 = 'Dedition Earring'}, {
                    test = fighters_roll_effect(28),
                    ear1 = 'Brutal Earring',
                    back = gear.Cichol.DEX_Crit
                }, {test = fighters_roll_effect(30), ear1 = 'Cessance Earring'},
                {test = fighters_roll_effect(32), ear1 = 'Telos Earring'},
                {test = fighters_roll_effect(33), ear1 = 'Dedition Earring'}, {
                    test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                             pred_factory.buff_active('Flash')),
                    hands = 'Regal Captain\'s Gloves'
                }
            }
        })
    sets.engaged.Hybrid.Farsha.Fencer = set_combine(sets.engaged.Hybrid.Fencer,
                                                    {})
    sets.engaged.Hybrid.Ukonvasara = {}
    sets.engaged.Hybrid.Ukonvasara.AM3 =
        set_combine(sets.engaged.Hybrid.Farsha.AM3, {})

    sets.engaged.Fencer = { --                      DA
        ammo = 'Aurgelmir Orb +1',
        head = 'Hjarrandi Helm', --                 39
        body = gear.Valorous.Body.DA, --            46
        hands = 'Sulevia\'s Gauntlets +2', --       52
        legs = 'Agoge Cuisses +3', --               58
        feet = 'Pummeler\'s Calligae +3', --        67
        neck = 'War. Beads +2', --            74
        waist = 'Ioskeha Belt +1', --               83
        ear1 = 'Brutal Earring', --                 88
        ear2 = 'Cessance Earring', --               91
        ring1 = 'Niqmaddu Ring', --         
        ring2 = 'Hetairoi Ring',
        back = gear.Cichol.DEX_DA, --               101
        swaps = {
            {test = fighters_roll_effect(5), head = 'Flamma Zucchetto +2'},
            {test = fighters_roll_effect(12), body = 'Hjarrandi Breastplate'},
            {test = fighters_roll_effect(14), ear2 = 'Telos Earring'},
            {test = fighters_roll_effect(16), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(19), ear1 = 'Dedition Earring'},
            {test = fighters_roll_effect(25), hands = 'Flamma Manopolas +2'}, {
                test = fighters_roll_effect(33),
                ear2 = 'Cessance Earring',
                back = gear.Cichol.DEX_STP
            }, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }
    sets.engaged.Hybrid.Fencer = { --                   DA
        ammo = 'Staunch Tathlum +1', --                 33
        head = 'Hjarrandi Helm', -- 6 DA                39
        body = 'Hjarrandi Breastplate',
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA      45
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA       56
        feet = 'Pummeler\'s Calligae +3', -- 9 DA       65
        neck = 'War. Beads +2', -- 7 DA           72
        waist = 'Tempus Fugit +1',
        ear1 = 'Brutal Earring', -- 5 DA                77
        ear2 = 'Cessance Earring', -- 3 DA              80
        ring1 = gear.MoonlightRing1,
        ring2 = gear.MoonlightRing2,
        back = gear.Cichol.DEX_DA, -- 10 DA             90
        swaps = {
            {test = fighters_roll_effect(12), ear2 = 'Telos Earring'},
            {test = fighters_roll_effect(14), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(17), ear1 = 'Dedition Earring'},
            {test = fighters_roll_effect(27), back = gear.Cichol.DEX_STP},
            {test = fighters_roll_effect(33), hands = 'Agoge Mufflers +3'}, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }

    -- 1 Crit rate is worth ~ .5 STP
    sets.engaged['Hand-to-Hand'] = { --                     DA
        ammo = 'Focal Orb', -- 2 DA                         35
        head = 'Hjarrandi Helm', -- 6 DA, 7 STP             41
        body = gear.Valorous.Body.DA, -- 7 DA, 3 STP        48
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA          54
        legs = 'Agoge Cuisses +3', -- 6 DA                  60
        feet = 'Pummeler\'s Calligae +3', -- 9 DA, 4 STP    69
        neck = 'War. Beads +2', -- 7 DA               76
        waist = 'Ioskeha Belt +1', -- 9 DA                  85
        ear1 = gear.MacheEarring1, -- 2 DA                  87
        ear2 = gear.MacheEarring2, -- 2 DA                  89
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Petrov Ring', -- 1 DA, 5 STP               90
        back = gear.Cichol.DEX_DA, -- 10 DA                 100
        swaps = {
            {
                test = fighters_roll_effect(13),
                body = 'Hjarrandi Breastplate',
                head = 'Flamma Zucchetto +2'
            }, {test = fighters_roll_effect(19), hands = 'Flamma Manopolas +2'},
            {test = fighters_roll_effect(21), ammo = 'Yetshila +1'},
            {test = fighters_roll_effect(22), ring2 = 'Hetairoi Ring'},
            {test = fighters_roll_effect(32), back = gear.Cichol.DEX_STP}, {
                test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                         pred_factory.buff_active('Flash')),
                hands = 'Regal Captain\'s Gloves'
            }
        }
    }
    sets.engaged.Hybrid['Hand-to-Hand'] =
        {
            ammo = 'Staunch Tathlum +1',
            head = 'Flamma Zucchetto +2',
            body = 'Hjarrandi Breastplate',
            hands = 'Sulevia\'s Gauntlets +2',
            legs = 'Pummeler\'s Cuisses +3',
            feet = 'Pummeler\'s Calligae +3',
            neck = 'War. Beads +2',
            waist = 'Ioskeha Belt +1',
            ear1 = gear.MacheEarring1,
            ear2 = gear.MacheEarring2,
            ring1 = gear.MoonlightRing1,
            ring2 = gear.MoonlightRing2,
            back = gear.Cichol.DEX_DA,
            swaps = {
                {
                    test = pred_factory.p_or(pred_factory.buff_active('Blindness'),
                                             pred_factory.buff_active('Flash')),
                    hands = 'Regal Captain\'s Gloves'
                }
            }
        }

    sets.WS = {
        ammo = 'Knobkierrie',
        head = 'Agoge Mask +3',
        body = 'Pummeler\'s Lorica +3',
        hands = gear.Odyssean.Hands.STR_WSD,
        legs = gear.Valorous.Legs.STR_WSD,
        feet = 'Sulevia\'s Leggins +2',
        neck = 'War. Beads +2',
        waist = 'Sailfi Belt +1',
        ear1 = 'Moonshade Earring',
        ear2 = 'Thrud Earring',
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), ear1 = 'Lugra Earring +1'}, {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                hands = gear.Valorous.STR_Crit,
                legs = gear.Valorous.STR_Crit,
                feet = 'Boii Calligae +1'
            }
        }
    }

    -- all STP gear
    sets.WS.Abyssea = {
        ammo = 'Ginsen',
        head = 'Sulevia\'s Mask +2',
        body = gear.Valorous.Body.STP,
        hands = gear.Emicho.Hands.PathD,
        legs = gear.Odyssean.Legs.STP,
        feet = 'Flamma Gambieras +2',
        neck = 'Combatant\'s Torque',
        waist = 'Kentarch Belt +1',
        ear1 = 'Telos Earring',
        ear2 = 'Dedition Earring',
        ring1 = gear.MoonlightRing1,
        ring2 = gear.MoonlightRing2,
        back = gear.Cichol.STR_DA,
        swaps = {
            {
                test = function()
                    return settings.main.value == 'Mutsunokami'
                end,
                head = 'Kengo Hachimaki'
            }
        }
    }

    -- The fencer argument of the ETP function assumes blurred shield +1, since I don't use any other shields
    sets.WS['Savage Blade'] = {
        ammo = 'Knobkierrie',
        head = 'Agoge Mask +3',
        body = 'Pummeler\'s Lorica +3',
        hands = gear.Odyssean.Hands.STR_WSD,
        legs = gear.Valorous.Legs.STR_WSD,
        feet = 'Sulevia\'s Leggings +2',
        neck = 'War. Beads +2',
        waist = 'Sailfi Belt +1',
        ear1 = 'Thrud Earring',
        ear2 = 'Moonshade Earring',
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750, 2), ear2 = 'Lugra Earring +1'}, {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                legs = gear.Valorous.Legs.STR_Crit,
                feet = 'Boii Calligae +1'
            }
        }
    }

    sets.WS['Decimation'] = { --                    DA
        ammo = 'Aurgelmir Orb +1',
        head = 'Flamma Zucchetto +2',
        body = 'Dagon Breastplate',
        hands = gear.Argosy.Hands.PathD, -- 5 DA    38
        legs = gear.Argosy.Legs.PathD, -- 6 DA      42
        feet = 'Flamma Gambieras +2', -- 6 DA       48
        neck = 'War. Beads +2', -- 7 DA             55
        waist = 'Sailfi Belt +1', -- 5 DA           60
        ear1 = 'Brutal Earring', -- 5 DA            65
        ear2 = 'Cessance Earring', -- 3 DA          68
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_DA, -- 10 DA         78
        swaps = {
            {
                test = function()
                    return settings.engaged.value == 'Hybrid'
                end,
                hands = 'Sulevia\'s Gauntlets +2',
                legs = 'Pummeler\'s Cuisses +3'
            }, {test = fighters_roll_effect(25), neck = 'Fotia Gorget'}, {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                body = gear.Valorous.Body.STR_Crit,
                hands = gear.Valorous.Hands.STR_Crit,
                legs = gear.Valorous.Legs.STR_Crit,
                feet = 'Boii Calligae +1'
            }
        }
    }

    sets.WS['Cloudsplitter'] = {
        ammo = 'Knobkierrie',
        head = gear.Odyssean.Head.MAB_WSD,
        body = 'Sacro Breastplate',
        hands = gear.Odyssean.Hands.MAB_WSD,
        legs = 'Augury Cuisses +1',
        feet = gear.Odyssean.Feet.MAB_WSD,
        neck = 'Baetyl Pendant',
        waist = 'Orpheus\'s Sash',
        ear1 = 'Moonshade Earring',
        ear2 = 'Thrud Earring',
        ring1 = 'Epaminondas\'s Ring',
        ring2 = 'Regal Ring', -- 'Metamorph Ring +1',
        back = gear.Cichol.STR_WSD,
        swaps = {
            -- {
            --     test = function()
            --         return settings.engaged.value == 'Hybrid'
            --     end,
            --     body = 'Sacro Brestplate'
            -- },
            {test = pred_factory.hachirin_bonus(2), waist = 'Hachirin-no-Obi'},
            {test = pred_factory.etp_gt(2750, 1), ear1 = 'Friomisi Earring'}
        }
    }

    sets.WS.Calamity = {
        ammo = 'Knobkierrie',
        head = 'Agoge Mask +3',
        body = 'Pummeler\'s Lorica +3',
        hands = gear.Odyssean.Hands.STR_WSD,
        legs = gear.Valorous.Legs.STR_WSD,
        feet = 'Sulevia\'s Leggings +2',
        neck = 'War. Beads +2',
        waist = 'Fotia Belt',
        ear1 = 'Moonshade Earring',
        ear2 = 'Thrud Earring',
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_WSD,
        swaps = {
            {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                legs = gear.Valorous.Legs.STR_Crit,
                feet = 'Boii Calligae +1'
            }, {test = pred_factory.etp_gt(2750, 2), ear1 = 'Lugra Earring +1'}
        }
    }
    sets.WS['Mistral Axe'] = sets.WS.Calamity

    sets.WS.Rampage = {
        ammo = 'Yetshila +1',
        head = 'Flamma Zucchetto +2',
        body = 'Hjarrandi Breastplate',
        hands = 'Flamma Manopolas +2',
        legs = 'Agoge Cuisses +3',
        feet = 'Boill Calligae +1',
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        ear1 = 'Brutal Earring',
        ear2 = 'Moonshade Earring',
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_DA,
        swaps = {
            {test = pred_factory.etp_gt(2750, 1), ear2 = 'Lugra Earring +1'}, {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                body = gear.Valorous.Body.STR_Crit,
                hands = gear.Valorous.Hands.STR_Crit,
                legs = gear.Valorous.Legs.STR_Crit
            }
        }
    }

    sets.WS['Impulse Drive'] = {
        ammo = 'Knobkierrie',
        head = 'Agoge Mask +3',
        body = 'Pummeler\'s Lorica +3',
        hands = gear.Odyssean.Hands.STR_WSD,
        legs = gear.Valorous.Legs.STR_WSD,
        feet = 'Sulevia\'s Leggings +2',
        neck = 'War. Beads +2',
        waist = 'Sailfi Belt +1',
        ear1 = 'Thrud Earring',
        ear2 = 'Moonshade Earring',
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_WSD,
        swaps = {
            {
                test = pred_factory.crit_bonus_gt(50), -- ! Probably not the optimal number, needs testing
                ammo = 'Yetshila +1',
                legs = gear.Valorous.Legs.STR_Crit,
                feet = 'Boii Calligae +1'
            }, {test = pred_factory.etp_gt(2750), ear2 = 'Lugra Earring +1'}
        }
    }

    sets.WS.Stardiver = { --                                DA
        ammo = 'Aurgelmir Orb +1',
        head = gear.Lustratio.Head.PathA, -- 3 DA           36
        body = gear.Argosy.Body.PathD, -- 6 DA                 42
        hands = gear.Argosy.Hands.PathD, -- 5 DA               47
        legs = gear.Argosy.Legs.PathD, -- 6 DA                53
        feet = gear.Lustratio.Feet.PathD,
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        ear1 = 'Brutal Earring', -- 5 DA                    58
        ear2 = 'Moonshade Earring',
        ring1 = 'Regal Ring',
        ring2 = 'Niqmaddu Ring',
        back = gear.Cichol.STR_DA, -- 10 DA                 68
        swaps = {
            {
                test = function()
                    return settings.engaged.value == 'Hybrid'
                end,
                head = 'Flamma Zucchetto +2',
                body = 'Dagon Breastplate',
                hands = 'Sulevia\'s Gauntlets +2',
                legs = 'Pummeler\'s Cuisses +3',
                feet = 'Flamma Gambieras +2'
            }, {test = pred_factory.etp_gt(2750), ear2 = 'Lugra Earring +1'}, {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                head = 'Flamma Zucchetto +2',
                body = gear.Valorous.Body.STR_Crit,
                hands = gear.Valorous.Hands.STR_Crit,
                legs = gear.Valorous.Legs.STR_Crit,
                feet = 'Boii Calligae +1'
            }
        }
    }

    local function ukko_crit_rate_gt(n)
        return function()
            local b_crit = 25
            if player.tp < 2000 then
                b_crit = b_crit + (player.tp - 1000) * .015
            else
                b_crit = b_crit + 15 + (player.tp - 2000) * .02
            end
            return pred_factory.crit_bonus_gt(n - b_crit)()
        end
    end
    sets.WS['Ukko\'s Fury'] = { --                          DA  TA  CR  CD
        ammo = 'Yetshila +1', -- 2 CR, 6 CD                 33  0   22  6
        head = 'Flamma Zucchetto +2', -- 5 TA 7 STP             5
        body = 'Hjarrandi Breastplate', -- 13 CR, 10 STP            35
        hands = 'Sulevia\'s Gauntlets +2', -- 6 DA          39
        legs = 'Pummeler\'s Cuisses +3', -- 11 DA           50
        feet = 'Boii Calligae +1', -- 11 CD                             17
        neck = 'War. Beads +2', -- 7 DA               55
        waist = 'Sailfi Belt +1', -- 5 DA                   62
        ear1 = 'Brutal Earring', -- 5 DA                    67
        ear2 = 'Moonshade Earring', -- 3.75-5 CR 
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_DA, -- 10 DA                 77      
        swaps = {
            {test = ukko_crit_rate_gt(78), body = 'Dagon Breastplate'},
            {test = pred_factory.etp_gt(2750), ear2 = 'Thrud Earring'},
            {test = fighters_roll_effect(25), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(28), ear1 = 'Lugra Earring +1'},
            {
                test = fighters_roll_effect(32),
                hands = gear.Valorous.Hands.STR_Crit
            }
        }
    }

    sets.WS.Cataclysm = {
        ammo = 'Knobkierrie',
        head = gear.Odyssean.Head.MAB_WSD,
        body = 'Sacro Breastplate',
        hands = gear.Odyssean.Hands.STR_WSD,
        legs = 'Augury Cuisses +1',
        feet = 'Sulevia\'s Leggings +2',
        neck = 'Baetyl Pendant',
        waist = 'Orpheus\'s Sash',
        ear1 = 'Moonshade Earring',
        ear2 = 'Thrud Earring',
        ring1 = 'Epaminondas\'s Ring',
        ring2 = 'Metamorph Ring +1',
        back = gear.Cichol.STR_WSD,
        swaps = {
            {
                test = function()
                    return settings.engaged.value == 'Hybrid'
                end,
                body = 'Sacro Brestplate'
            },
            {test = pred_factory.hachirin_bonus(2), waist = 'Hachirin-no-Obi'},
            {test = pred_factory.etp_gt(2750, 1), ear1 = 'Friomisi Earring'}
        }
    }


    local function raging_crit_rate_gt(n)
        return function()
            local b_crit = 20
            if player.tp < 2000 then
                b_crit = b_crit + (player.tp - 1000) * .015
            else
                b_crit = b_crit + 15 + (player.tp - 2000) * .02
            end
            return pred_factory.crit_bonus_gt(n - b_crit)()
        end
    end
    sets.WS['Raging Rush'] = set_combine(sets.WS['Ukko\'s Fury'], {
        swaps = {
            {test = raging_crit_rate_gt(78), body = 'Dagon Breastplate'},
            {test = pred_factory.etp_gt(2750), ear2 = 'Thrud Earring'}, {
                test = pred_factory.p_and(pred_factory.etp_gt(2750),
                                          pred_factory.time_between(18, 6)),
                ear2 = 'Lugra Earring +1'
            }, {test = fighters_roll_effect(25), ear1 = 'Cessance Earring'},
            {test = fighters_roll_effect(28), ear1 = 'Lugra Earring +1'}, {
                test = pred_factory.p_and(fighters_roll_effect(28),
                                          pred_factory.time_between(18, 6),
                                          pred_factory.etp_gt(2750)),
                ear1 = 'Thrud Earring'
            },
            {
                test = fighters_roll_effect(32),
                hands = gear.Valorous.Hands.STR_Crit
            }
        }
    })

    sets.WS.Upheaval = {
        ammo = 'Knobkierrie',
        head = 'Agoge Mask +3',
        body = 'Pummeler\'s Lorica +3',
        hands = gear.Odyssean.Hands.VIT_WSD,
        legs = gear.Odyssean.Legs.VIT_WSD,
        feet = 'Sulevia\'s Leggins +2',
        neck = 'War. Beads +2',
        waist = 'Sailfi Belt +1',
        ear1 = 'Moonshade Earring',
        ear2 = 'Thrud Earring',
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Gelatinous Ring +1',
        back = gear.Cichol.VIT_WSD,
        swaps = {
            {test = pred_factory.etp_gt(2750), ear1 = 'Lugra Earring +1'}
            -- TODO: Mighty strikes
        }
    }

    sets.WS.Resolution = { --                    DA
        ammo = 'Aurgelmir Orb +1',
        head = 'Flamma Zucchetto +2',
        body = 'Dagon Breastplate',
        hands = gear.Argosy.Hands.PathD, -- 5 DA    38
        legs = gear.Argosy.Legs.PathD, -- 6 DA      42
        feet = 'Flamma Gambieras +2', -- 6 DA       48
        neck = 'Fotia Gorget',
        waist = 'Fotia Belt',
        ear1 = 'Brutal Earring', -- 5 DA            53
        ear2 = 'Cessance Earring', -- 3 DA          56
        ring1 = 'Niqmaddu Ring',
        ring2 = 'Regal Ring',
        back = gear.Cichol.STR_DA, -- 10 DA         66
        swaps = {
            {
                test = function()
                    return settings.engaged.value == 'Hybrid'
                end,
                hands = 'Sulevia\'s Gauntlets +2',
                legs = 'Pummeler\'s Cuisses +3'
            }, {
                test = pred_factory.buff_active('Mighty Strikes'),
                ammo = 'Yetshila +1',
                body = gear.Valorous.Body.STR_Crit,
                hands = gear.Valorous.Hands.STR_Crit,
                legs = gear.Valorous.Legs.STR_Crit,
                feet = 'Boii Calligae +1'
            }
        }
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
        print(mode.description)
        return imap(mode, function(el)
            local item_name = type(el) == 'table' and el.name or el
            local value = type(el) == 'table' and el.alias or item_name
            local img
            if windower.file_exists(windower.addon_path .. '/data/graphics/' ..
                                        item_name .. '.png') then
                img = windower.addon_path .. '/data/graphics/' .. item_name ..
                          '.png'
            elseif windower.file_exists(windower.addon_path ..
                                            '/data/graphics/WAR/' .. item_name ..
                                            '.png') then
                img =
                    windower.addon_path .. '/data/graphics/WAR/' .. item_name ..
                        '.png'
            else
                img = get_icon(item_name)
            end
            return {img = img, value = tostring(value)}
        end)
    end

    local function grid_icons(icons)
        local res = T {T {}, T {}}
        for i, v in ipairs(icons) do res[i % 2 == 1 and 1 or 2]:append(v) end
        return res
    end
    local GUI_x = 1732
    local GUI_y = 80
    IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.engaged,
        icons = {
            {img = 'DD Normal.png', value = 'Normal'},
            {img = 'DD Hybrid.png', value = 'Hybrid'}
        }
    }):draw()

    GUI_y = GUI_y + 54

    GridButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.main,
        icons = grid_icons(get_icons(main_hands))
    }):draw()

    GUI_y = GUI_y + 54

    local sub_button = IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.sub,
        icons = get_icons(settings.sub)
    })
    sub_button:draw()

    settings.sub.on_option_change:register(
        function() sub_button:new_icons(get_icons(settings.sub)) end)

    GUI_y = GUI_y + 54

    local abyssea_main
    ToggleButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.abyssea,
        iconUp = 'WAR/Atomos.png',
        iconDown = 'WAR/Atomos.png'
    }):draw()
    settings.abyssea.on_change:register(function()
        if settings.abyssea.value then
            abyssea_main:enable()
            abyssea_main:show()
        else
            abyssea_main:disable()
            abyssea_main:hide()
        end
    end)

    GUI_y = GUI_y + 54

    abyssea_main = IconButton({
        x = GUI_x,
        y = GUI_y,
        var = abyssea_main_hands,
        icons = get_icons(abyssea_main_hands)
    })
    abyssea_main:draw()
    abyssea_main:hide()

    GUI_y = GUI_y + 54

    local dw_mode_display = TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_mode,
        align = 'left',
        width = 112,
        start_hidden = true,
        disabled = true
    })
    dw_mode_display:draw()

    GUI_y = GUI_y + 32

    local dw_level_display = TextCycle({
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_level,
        align = 'left',
        width = 112,
        start_hidden = true,
        disabled = true
    })
    dw_level_display:draw()
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

