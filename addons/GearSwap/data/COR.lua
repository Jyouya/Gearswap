require('J-Swap')
require('GUI')
local res = require('resources')

local M = require('J-Mode')
local events = require('J-Swap-Events')
local haste = require('J-Haste')
local pred_factory = require('J-Predicates')
local TH = require('TreasureHunter')
local command = require('J-Swap-Command')
local bind_key = require('J-Bind')
local auto_ra = require('J-AutoRA')

-- local function unpack_table(t) 
--     for k, 
-- end

-- J-Bind will automatically unbind these when the file unloads
bind_key('numpad0', 'input /ra <t>')
bind_key('numpad.', 'gs c qd 1')
bind_key('^numpad.', 'gs c qd 2')

local Camulus = {}
Camulus.DA = {
    name = "Camulus's Mantle",
    augments = {
        'DEX+20', 'Accuracy+20 Attack+20', 'DEX+10', '"Dbl.Atk."+10',
        'Magic dmg. taken-10%'
    }
}
Camulus.DW = {
    name = "Camulus's Mantle",
    augments = {
        'DEX+20', 'Accuracy+20 Attack+20', 'Accuracy+10', '"Dual Wield"+10',
        'Phys. dmg. taken-10%'
    }
}
Camulus.rSTP = {
    name = "Camulus's Mantle",
    augments = {
        'AGI+20', 'Rng.Acc.+20 Rng.Atk.+20', 'AGI+10', '"Store TP"+10',
        'Damage taken-5%'
    }
}
Camulus.AM3 = {
    name = "Camulus's Mantle",
    augments = {
        'AGI+20', 'Rng.Acc.+20 Rng.Atk.+20', 'AGI+10', 'Crit.hit rate+10',
        'Phys. dmg. taken-10%'
    }
}

Camulus.Savage = {
    name = "Camulus's Mantle",
    augments = {
        'STR+20', 'Accuracy+20 Attack+20', 'STR+10', 'Weapon skill damage +10%',
        'Damage taken-5%'
    }
}
Camulus.LastStand = {
    name = "Camulus's Mantle",
    augments = {
        'AGI+20', 'Rng.Acc.+20 Rng.Atk.+20', 'AGI+10',
        'Weapon skill damage +10%', 'Damage taken-5%'
    }
}
Camulus.LeadenSalute = {
    name = "Camulus's Mantle",
    augments = {
        'AGI+20', 'Mag. Acc+20 /Mag. Dmg.+20', 'AGI+10',
        'Weapon skill damage +10%', 'Damage taken-5%'
    }
}
Camulus.AeolianEdge = {
    name = "Camulus's Mantle",
    augments = {
        'INT+20', 'Mag. Acc+20 /Mag. Dmg.+20', 'INT+10',
        'Weapon skill damage +10%', 'Damage taken-5%'
    }
}
Camulus.Snapshot = {
    name = "Camulus's Mantle",
    augments = {
        'INT+20', 'Eva.+20 /Mag. Eva.+20', '"Snapshot"+10', 'Damage taken-5%'
    }
}
Camulus.Fastcast = {
    name = "Camulus's Mantle",
    augments = {'HP+60', '"Fast Cast"+10'}
}
Camulus.QuickdrawDamage = {
    name = "Camulus's Mantle",
    augments = {
        'AGI+20', 'Mag. Acc+20 /Mag. Dmg.+20', 'AGI+10', '"Mag.Atk.Bns."+10',
        'Damage taken-5%'
    }
}

local Herc = {}
Herc.Feet = {}
Herc.Feet.DT = {
    name = "Herculean Boots",
    augments = {
        'Pet: "Dbl. Atk."+3', 'Phys. dmg. taken -2%', 'Damage taken-3%',
        'Accuracy+11 Attack+11', 'Mag. Acc.+3 "Mag.Atk.Bns."+3'
    }
}
Herc.Feet.WSDAGI = {
    name = "Herculean Boots",
    augments = {
        'Accuracy+23 Attack+23', 'Weapon skill damage +4%', 'AGI+8',
        'Accuracy+6', 'Attack+7'
    }
}
Herc.Feet.TA = {
    name = "Herculean Boots",
    augments = {'Accuracy+29', '"Triple Atk."+4', 'DEX+5'}
}
Herc.Legs = {}
Herc.Legs.LastStand = {
    name = "Herculean Trousers",
    augments = {'Rng.Acc.+28', 'Weapon skill damage +4%', 'DEX+1', 'Rng.Atk.+2'}
}
Herc.Legs.Leaden = {
    name = "Herculean Trousers",
    augments = {
        'Mag. Acc.+20 "Mag.Atk.Bns."+20', 'Weapon skill damage +1%', 'INT+9',
        'Mag. Acc.+11', '"Mag.Atk.Bns."+14'
    }
}
Herc.Legs.TreasureHunter = {
    name = "Herculean Trousers",
    augments = {'Accuracy+12', '"Treasure Hunter"+2', 'Accuracy+3 Attack+3'}
}
Herc.Legs.Savage = {
    name = "Herculean Trousers",
    augments = {'Weapon skill damage +5%', 'Phalanx +5', 'Accuracy+9 Attack+9'}
}
Herc.Hands = {}
Herc.Hands.Leaden = {
    name = "Herculean Gloves",
    augments = {
        'Mag. Acc.+19 "Mag.Atk.Bns."+19', 'Weapon skill damage +1%',
        'Mag. Acc.+13', '"Mag.Atk.Bns."+14'
    }
}
Herc.Head = {}
Herc.Head.Savage = {
    name = "Herculean Helm",
    augments = {
        'Rng.Acc.+12', 'Weapon skill damage +3%', 'STR+6', 'Accuracy+15',
        'Attack+13'
    }
}
Herc.Head.Wildfire = {
    name = "Herculean Helm",
    augments = {
        'Mag. Acc.+16 "Mag.Atk.Bns."+16', 'Crit.hit rate+1', 'Mag. Acc.+15',
        '"Mag.Atk.Bns."+15'
    }
}

local Adhemar = {}
Adhemar.Head = {}
Adhemar.Head.PathD = {
    name = "Adhemar Bonnet +1",
    augments = {'HP+105', 'Attack+13', 'Phys. dmg. taken -4'}
}
Adhemar.Body = {}
Adhemar.Body.PathA = {
    name = "Adhemar Jacket +1",
    augments = {'DEX+12', 'AGI+12', 'Accuracy+20'}
}
Adhemar.Legs = {}
Adhemar.Legs.PathC = {
    name = "Adhemar Kecks +1",
    augments = {'AGI+12', 'Rng.Acc.+20', 'Rng.Atk.+20'}
}
Adhemar.Legs.PathD = {
    name = "Adhemar Kecks +1",
    augments = {'AGI+12', '"Rapid Shot"+13', 'Enmity-6'}
}
Adhemar.Hands = {}
Adhemar.Hands.PathA = {
    name = "Adhemar Wrist. +1",
    augments = {'DEX+12', 'AGI+12', 'Accuracy+20'}
}
Adhemar.Hands.PathC = {
    name = "Adhemar Wrist. +1",
    augments = {'AGI+12', 'Rng.Acc.+20', 'Rng.Atk.+20'}
}

local Carmine = {}
Carmine.Head = {}
Carmine.Head.PathD = {
    name = "Carmine Mask +1",
    augments = {'Accuracy+20', 'Mag. Acc.+12', '"Fast Cast"+4'}
}
Carmine.Feet = {}
Carmine.Feet.PathD = {
    name = "Carmine Greaves +1",
    augments = {'HP+80', 'MP+80', 'Phys. dmg. taken -4'}
}

local Rostam = {}
Rostam.A = {alias = 'RostamA', name = "Rostam", augments = {'Path: A'}}
Rostam.B = {alias = 'RostamB', name = "Rostam", augments = {'Path: B'}}
Rostam.C = {alias = 'RostamC', name = "Rostam", augments = {'Path: C'}}

settings.main = M {
    ['description'] = 'Main Hand',
    Rostam.A,
    Rostam.B,
    'Naegling',
    'Tauret',
    'Fettering Blade'

}

settings.main.on_change:register(function(m)
    if tostring(m.value) == tostring(settings.sub.value) then
        settings.sub:cycle()
    end
    windower.send_command('gs c update')
end)

settings.sub = M {['description'] = 'Off Hand', 'Nusku Shield'}
settings.sub.on_change:register(function(m)
    if m.value == settings.main.value then settings.sub:cycle() end
    windower.send_command('gs c update')
end)

do
    local function sub_options()
        if player.sub_job == 'NIN' or player.sub_job == 'DNC' then
            settings.sub:options('Tauret', 'Blurred Knife +1', 'Nusku Shield',
                                 Rostam.A, Rostam.B, 'Fettering Blade')
        else
            settings.sub:options('Nusku Shield')
        end
    end

    events.load:register(sub_options)
    events.sub_job_change:register(sub_options)
end

settings.range = M {
    ['description'] = 'Ranged Weapon',
    'Death Penalty',
    'Armageddon',
    'Fomalhaut',
    'Anarchy +2'
}
settings.range.on_change:register(function(m)
    windower.send_command('gs c update')
end)

settings.CorsairShot = M {
    ['description'] = 'Quick Draw Mode',
    'Damage',
    'STP',
    'Accuracy'
}

settings.quickdraw1 = M {
    ['description'] = 'Primary Quickdraw Element',
    'Fire',
    'Earth',
    'Water',
    'Wind',
    'Ice',
    'Thunder',
    'Light',
    'Dark'
}

settings.quickdraw2 = M {
    ['description'] = 'Secondary Quickdraw Element',
    'Dark',
    'Fire',
    'Earth',
    'Water',
    'Wind',
    'Ice',
    'Thunder',
    'Light'
}

settings.accuracy = M {
    ['description'] = 'Accuracy Mode',
    'Normal',
    'Mid',
    'High'
}
settings.accuracy.on_change:register(function()
    windower.send_command('gs c update')
end)

settings.ranged_accuracy = M {
    ['description'] = 'Ranged Accuracy',
    'STP',
    'Normal',
    'Mid',
    'High'
}
settings.ranged_accuracy.on_change:register(
    function() windower.send_command('gs c update') end)

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
    '31', -- /nin mid ma haste
    '41', -- /dnc mid ma haste
    '42', -- /nin low ma haste
    '49', -- /nin no ma haste
    '52', -- /dnc low ma haste
    '59' -- /dnc no ma haste
}

settings.roll_gear = M(true, 'Use ranged/weapon swaps for rolling')

haste.change:register(function(gearswap_vars_loaded)
    if not midaction() then
        if gearswap_vars_loaded then
            events.update:trigger()
        else
            windower.send_command('gs c update')
        end
    end
end)

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

rules.midcast:append({
    test = function(equip_set, spell) return spell.prefix == '/range' end,
    key = function(equip_set, spell)
        for i = settings.ranged_accuracy.index, 1, -1 do
            if equip_set[settings.ranged_accuracy[i]] then
                return settings.ranged_accuracy[i]
            end
        end
    end
})

-- Apply TH gear over midshot + swaps
-- ! Known issue with TH layering over swaps
-- ! Triple shot + TH results in only TH being applied
rules.midcast:append({
    test = function(equip_set, spell)
        if spell.prefix == '/range' and TH.Result then
            equip_set.swaps = equip_set.swaps or {}
            table.append(equip_set.swaps, table.update(sets.TreasureHunter, {
                test = function() return true end
            }))
        end
    end
})

-- Dual Wield sets and auto DW detection
local item_id_memo = setmetatable({}, {
    __index = function(t, k)
        t[k] = res.items:with('en', k).id
        return t[k]
    end
})
rules.engaged:append({
    test = function()
        local sub = settings.sub.value
        local sub_id = item_id_memo[type(sub) == 'table' and sub.name or sub]
        return (player.sub_job == 'NIN' or player.sub_job == 'DNC') and
                   res.items[sub_id].slots:contains(0) and
                   res.items[sub_id].slots:contains(1)
    end,
    key = function()
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
})

rules.idle:append({
    test = function()
        local sub = settings.sub.value
        local sub_id = item_id_memo[type(sub) == 'table' and sub.name or sub]
        return (player.sub_job == 'NIN' or player.sub_job == 'DNC') and
                   res.items[sub_id].slots:contains(0) and
                   res.items[sub_id].slots:contains(1)
    end,
    key = function()
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
})

-- Apply TH gear over engaged set + swaps
rules.engaged:append({
    test = function(equip_set, spell)
        print('th: ' .. (TH.Result and 'true' or 'false'))
        if TH.Result then
            equip_set.swaps = equip_set.swaps or {}
            table.append(equip_set.swaps, table.update(sets.TreasureHunter, {
                test = function() return true end
            }))
        end
    end
})

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
    local function handle_qd(number)
        print('qd ' .. number)
        local element = settings['quickdraw' .. number].value
        windower.send_command('input /ja "' .. element .. ' shot" <t>')
    end
    command:register('qd', handle_qd, 'number')
end

events.load:register(function()
    print('on load')
    sets.idle = {
        head = "Malignance Chapeau",
        body = "Malignance Tabard",
        hands = "Malignance Gloves",
        legs = "Malignance Tights",
        feet = "Malignance Boots",
        neck = "Loricate Torque +1",
        ear1 = "Odnowa Earring",
        ear2 = "Etiolation Earring",
        ring1 = "Defending Ring",
        ring2 = "Gelatinous Ring +1",
        -- back="Moonbeam Cape",
        back = Camulus.Snapshot,
        waist = "Flume Belt"
    }

    sets.JA = {}

    sets.JA['Snake Eye'] = {legs = "Lanun Trews"}
    sets.JA['Wild Card'] = {feet = "Lanun Bottes +3"}
    sets.JA['Random Deal'] = {body = "Lanun Frac +3"}
    sets.JA.Fold = {
        swaps = {
            {
                test = function() return buffactive['Bust'] == 2 end,
                hands = "Lanun Gants +3"
            }
        }
    }

    sets.JA.CorsairRoll = {
        main = Rostam.C,
        range = "Compensator",
        head = "Lanun Tricorne +3",
        body = "Malignance Tabard",
        hands = "Chasseur's Gants +1",
        legs = "Desultor Tassets",
        feet = "Malignance Boots",
        neck = "Regal Necklace",
        ear1 = "Genmei Earring",
        ear2 = "Etiolation Earring",
        ring1 = "Luzaf's Ring",
        ring2 = "Gelatinous Ring +1",
        back = Camulus.Snapshot,
        waist = "Flume Belt",
        swap_managed_weapon = function()
            local am3 = settings.main.value == 'Armageddon' and
                            buffactive['Aftermath: Lv.3']
            return not am3 and settings.roll_gear.value
        end
    }
    sets.JA['Double-Up'] = {ring1 = "Luzaf's Ring"}

    sets.JA["Caster's Roll"] = set_combine(sets.JA['Phantom Roll'],
                                           {legs = "Chas. Culottes +1"})
    sets.JA["Courser's Roll"] = set_combine(sets.JA['Phantom Roll'],
                                            {feet = "Chasseur's Bottes +1"})
    sets.JA["Blitzer's Roll"] = set_combine(sets.JA['Phantom Roll'],
                                            {head = "Chasseur's Tricorne +1"})
    sets.JA["Tactician's Roll"] = set_combine(sets.JA['Phantom Roll'],
                                              {body = "Chasseur's Frac +1"})
    sets.JA["Allies' Roll"] = set_combine(sets.JA['Phantom Roll'],
                                          {hands = "Chasseur's Gants +1"})

    sets.JA.CorsairShot = {}
    sets.JA.CorsairShot.Damage = {
        head = Herc.Head.Wildfire,
        body = "Lanun Frac +3",
        hands = "Carmine Fin. Ga. +1",
        legs = Herc.Legs.Leaden,
        feet = "Lanun Bottes +3",
        neck = "Baetyl Pendant",
        ear1 = "Moonshade Earring",
        ear2 = "Friomisi Earring",
        ring1 = "Dingir Ring",
        ring2 = "Ilabrat Ring",
        back = Camulus.QuickdrawDamage,
        waist = "Eschan Stone",
        swaps = {
            {test = pred_factory.orpheus, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.hachirin, waist = 'Hachirin-no-Obi'}
        }
    }
    sets.JA.CorsairShot.STP = {
        ammo = "Living Bullet",
        head = "Malignance Chapeau",
        body = "Malignance Tabard",
        hands = "Malignance Gloves",
        legs = "Malignance Tights",
        feet = "Malignance Boots",
        neck = "Iskur Gorget",
        ear1 = "Enervating Earring",
        ear2 = "Telos Earring",
        ring1 = "Chirich Ring +1",
        ring2 = "Ilabrat Ring",
        waist = "Kentarch Belt +1",
        back = Camulus.rSTP
    }
    sets.JA.CorsairShot.Accuracy = {
        ammo = "Devastating Bullet",
        head = "Malignance Chapeau",
        body = "Malignance Tabard",
        hands = "Malignance Gloves",
        legs = "Malignance Tights",
        feet = "Malignance Boots",
        ear1 = "Gwati Earring",
        ear2 = "Dignitary's Earring",
        ring1 = "Rahab Ring",
        ring2 = "Regal Ring",
        waist = "Kwahu Kachina Belt +1",
        neck = "Commodore Charm +2",
        back = Camulus.QuickdrawDamage
    }

    sets.JA['Light Shot'] = sets.JA.CorsairShot.Accuracy
    sets.JA['Dark Shot'] = sets.JA.CorsairShot.Accuracy

    sets.precast = {
        head = Carmine.Head.PathD,
        body = "Malignance Tabard",
        hands = "Leyline Gloves",
        legs = "Malignance Tights",
        feet = Carmine.Feet.PathD,
        neck = "Baetyl Pendant",
        ear1 = "Loquac. Earring",
        ear2 = "Odnowa Earring",
        ring1 = "Rahab Ring",
        ring2 = "Kishar Ring",
        back = Camulus.Fastcast
    }

    sets.precast.Utsusemi = set_combine(sets.precast, {
        neck = "Magoraga Beads",
        body = "Passion Jacket"
    })

    do
        local flurry_level
        windower.raw_register_event('action', function(act)
            local player_id = windower.ffxi.get_player().id
            local target_id = act.targets[1].id

            if target_id == player_id and act.category == 4 then
                if act.param == 845 and flurry_level ~= 2 then
                    flurry_level = 1
                elseif act.param == 846 then
                    flurry_level = 2
                end
            end
        end)

        sets.precast.RA = {
            head = "Taeon Chapeau",
            neck = "Commodore Charm +2",
            body = "Laksamana's Frac +3",
            hands = "Carmine Fin. Ga. +1",
            legs = "Laksamana's Trews +3",
            feet = "Meg. Jam. +2",
            back = Camulus.Snapshot,
            waist = "Impulse Belt",
            swaps = {
                {
                    test = pred_factory.buff_active(581),
                    legs = Adhemar.Legs.PathD,
                    waist = "Yemaya Belt"
                }, {
                    test = function()
                        return buffactive[581] and flurry_level == 2
                    end,
                    head = "Chass. Tricorne +1",
                    feet = "Pursuer's Gaiters"
                }
            }
        }
    end

    sets.WS = {}

    sets.WS['Last Stand'] = {
        ammo = "Chrono Bullet",
        head = "Lanun Tricorne +3",
        body = "Laksa. Frac +3",
        hands = "Meg. Gloves +2",
        legs = Herc.Legs.LastStand,
        feet = "Lanun Bottes +3",
        neck = "Fotia Gorget",
        waist = "Fotia Belt",
        left_ear = "Moonshade Earring",
        right_ear = "Ishvara Earring",
        left_ring = "Dingir Ring",
        right_ring = "Regal Ring",
        back = Camulus.LastStand,
        swaps = {{test = pred_factory.etp_gt(2850), ear1 = "Telos Earring"}}
    }

    sets.WS['Last Stand'].Mid = set_combine(sets.WS['Last Stand'],
                                            {neck = 'Iskur Gorget'})

    sets.WS['Last Stand'].High = set_combine(sets.WS['Last Stand'].Mid, {
        left_ring = 'Hajduk Ring +1',
        waist = 'K. Kachina Belt'
    })

    sets.WS['Leaden Salute'] = {
        ammo = "Living Bullet",
        head = "Pixie Hairpin +1",
        body = "Lanun Frac +3",
        hands = Herc.Hands.Leaden,
        legs = Herc.Legs.Leaden,
        feet = "Lanun Bottes +3",
        neck = "Commodore Charm +2",
        ear1 = "Moonshade Earring",
        ear2 = "Friomisi Earring",
        ring1 = "Dingir Ring",
        ring2 = "Archon Ring",
        back = Camulus.LeadenSalute,
        waist = "Eschan Stone",
        swaps = {
            {test = pred_factory.orpheus, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.hachirin, waist = 'Hachirin-no-Obi'},
            {test = pred_factory.etp_gt(2800), ear1 = 'Hecate\'s Earring'}
        }
    }

    sets.WS.Wildfire = {
        ammo = "Living Bullet",
        head = Herc.Head.Wildfire,
        body = "Lanun Frac +3",
        hands = Herc.Hands.Leaden,
        legs = Herc.Legs.Leaden,
        feet = "Lanun Bottes +3",
        neck = "Commodore Charm +2",
        ear1 = "Hecate's Earring",
        ear2 = "Friomisi Earring",
        ring1 = "Dingir Ring",
        ring2 = "Regal Ring",
        back = Camulus.LeadenSalute,
        waist = "Eschan Stone",
        swaps = {
            {test = pred_factory.orpheus, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.hachirin, waist = 'Hachirin-no-Obi'}
        }
    }

    sets.WS['Hot Shot'] = {
        ammo = "Living bullet",
        head = Herc.Head.Wildfire,
        body = "Lanun Frac +3",
        hands = Herc.Hands.Leaden,
        legs = Herc.Legs.Leaden,
        feet = "Lanun Bottes +3",
        neck = "Commodore Charm +2",
        ear1 = "Moonshade Earring",
        ear2 = "Friomisi Earring",
        ring1 = "Dingir Ring",
        ring2 = "Ilabrat Ring",
        back = Camulus.LeadenSalute,
        waist = "Fotia Belt",
        swaps = {
            {test = pred_factory.orpheus, waist = 'Orpheus\'s Sash'},
            {test = pred_factory.hachirin, waist = 'Hachirin-no-Obi'}
        }
    }

    sets.WS.Evisceration = {
        head = "Adhemar Bonnet +1",
        body = "Abnoba Kaftan",
        hands = "Mummu Wrists +2",
        legs = "Samnuha Tights",
        feet = "Mummu Gamash. +2",
        neck = "Fotia Gorget",
        waist = "Fotia Belt",
        ear1 = "Moonshade Earring",
        ear2 = "Telos Earring",
        ring1 = "Mummu Ring",
        ring2 = "Regal Ring",
        back = Camulus.DA
    }

    sets.WS.Evisceration.Mid = set_combine(sets.WS.Evisceration, {
        head = "Mummu Bonnet +2",
        body = "Mummu Jacket +2"
    })

    sets.WS.Evisceration.High = set_combine(sets.WS.Evisceration.Mid, {})

    sets.WS['Savage Blade'] = {
        head = Herc.Head.Savage,
        body = "Laksa. Frac +3",
        hands = "Meg. Gloves +2",
        legs = Herc.Legs.Savage,
        feet = "Lanun Bottes +3",
        neck = "Commodore Charm +2",
        waist = "Sailfi Belt +1",
        ear1 = "Moonshade Earring",
        ear2 = "Ishvara Earring",
        ring1 = "Regal Ring",
        ring2 = "Rufescent Ring",
        back = Camulus.Savage,
        swaps = {{test = pred_factory.etp_gt(2800), ear1 = "Telos Earring"}}
    }

    sets.WS.Requiescat = {
        head = "Adhemar Bonnet +1",
        body = "Adhemar Jacket +1",
        hands = "Meg. Gloves +2",
        legs = "Meg. Chausses +2",
        feet = Herc.Feet.TA,
        neck = "Fotia Gorget",
        waist = "Fotia Belt",
        ear1 = {name = "Moonshade Earring", priority = 15},
        ear2 = "Telos Earring",
        ring1 = "Regal Ring",
        ring2 = "Rufescent Ring",
        back = Camulus.DA
    }

    sets.WS['Aeolian Edge'] = {
        ammo = "Living Bullet",
        head = Herc.Head.Wildfire,
        body = "Lanun Frac +3",
        hands = "Carmine Fin. Ga. +1",
        legs = Herc.Legs.Leaden,
        feet = "Lanun Bottes +3",
        neck = "Comm. Charm +2",
        waist = "Orpheus's Sash",
        ear1 = "Moonshade Earring",
        ear2 = "Friomisi Earring",
        ring1 = "Dingir Ring",
        ring2 = "Ilabrat Ring", -- Empanada Ring
        back = Camulus.AeolianEdge
    }

    sets.midcast = {}
    sets.midcast.RA = {}
    sets.midcast.RA.Normal = {
        ammo = "Chrono Bullet",
        head = "Malignance Chapeau",
        body = "Malignance Tabard",
        hands = "Malignance Gloves",
        legs = "Malignance Tights",
        feet = "Malignance Boots",
        neck = "Iskur Gorget",
        ear1 = "Enervating Earring",
        ear2 = "Telos Earring",
        ring1 = "Dingir Ring",
        ring2 = "Ilabrat Ring",
        waist = "Yemaya Belt",
        back = Camulus.rSTP,
        swaps = {
            {
                test = pred_factory.buff_active('Triple Shot'),
                head = "Oshosi Mask +1",
                body = "Chasseur's Frac +1",
                hands = "Lanun Gants +3",
                legs = "Oshosi Trousers +1",
                feet = "Oshosi Leggings +1"
            }
        }
    }

    sets.midcast.RA.Mid = set_combine(sets.midcast.RA.Normal, {
        ammo = "Devastating Bullet",
        ring1 = "Hajduk Ring +1",
        waist = "K. Kachina Belt +1"
    })

    sets.midcast.RA.High = set_combine(sets.midcast.RA.Mid,
                                       {ring2 = "Regal Ring"})

    sets.midcast.RA.STP = set_combine(sets.midcast.RA.Normal, {
        ammo = "Devastating Bullet",
        ear1 = "Dedition Earring",
        ring1 = "Chirich Ring +1"
    })

    sets.midcast.RA.Armageddon = set_combine(sets.midcast.RA.Normal, {})
    sets.midcast.RA.Armageddon.Mid = set_combine(sets.midcast.RA.Mid, {})
    sets.midcast.RA.Armageddon.High = set_combine(sets.midcast.RA.High, {})
    sets.midcast.RA.Armageddon.STP = set_combine(sets.midcast.RA.STP, {})

    sets.midcast.RA.Armageddon.AM3 = {
        ammo = "Chrono Bullet",
        head = "Meghanada Visor +2",
        body = "Meghanada Cuirie +2",
        hands = "Mummu Wrists +2",
        legs = "Darraigner's Brais",
        feet = "Oshosi Leggings +1",
        neck = "Iskur Gorget",
        waist = "K. Kachina Belt +1",
        ear1 = "Enervating Earring",
        ear2 = "Telos Earring",
        ring1 = "Mummu Ring",
        ring2 = "Begrudging Ring",
        back = Camulus.AM3,
        swaps = {
            {
                test = pred_factory.buff_active('Triple Shot'),
                head = "Oshosi Mask +1",
                body = "Chasseur's Frac +1",
                hands = "Lanun Gants +3",
                legs = "Oshosi Trousers +1",
                feet = "Oshosi Leggings +1"
            }
        }
    }

    sets.engaged = {
        head = "Malignance Chapeau",
        body = "Malignance Tabard",
        hands = "Malignance Gloves",
        legs = "Samnuha Tights",
        feet = "Malignance Boots",
        neck = "Iskur Gorget",
        left_ear = "Cessance Earring",
        right_ear = "Telos Earring",
        ring1 = "Chirich Ring +1",
        ring2 = "Epona's Ring",
        back = Camulus.DA,
        waist = "Windbuffet Belt +1",
        swaps = {
            {
                test = function()
                    return settings.accuracy.index > 1
                end,
                waist = "Kentarch Belt +1",
                neck = "Combatant's Torque"
            }, {
                test = function()
                    return settings.accuracy.index > 2
                end,
                legs = "Malignance Tights"
            }
        }
    }

    sets.engaged.DW9 = set_combine(sets.engaged, {
        -- waist = 'Gerdr Belt +1',
        left_ear = 'Suppanomimi',
        right_ear = 'Eabani Earring', -- ! remove when we get Gerdr +1
        swaps = {
            { -- Accuracy swapping rule
                test = function()
                    return settings.accuracy.index > 1
                end,
                neck = "Combatant's Torque"
            }, {
                test = function()
                    return settings.accuracy.index > 2
                end,
                legs = "Malignance Tights"
            }
        }
    })

    sets.engaged.DW11 = set_combine(sets.engaged, {
        waist = 'Reiki Yotai',
        left_ear = {name = 'Eabani Earring', priority = 15}
    })

    sets.engaged.DW21 = set_combine(sets.engaged.DW11, {back = Camulus.DW})

    sets.engaged.DW31 = set_combine(sets.engaged.DW11, {
        body = 'Adhemar Jacket +1',
        feet = 'Taeon Boots',
        right_ear = 'Suppanomimi'
    })

    sets.engaged.DW41 = set_combine(sets.engaged.DW31, {back = Camulus.DW})

    sets.engaged.DW42 = set_combine(sets.engaged.DW31, {
        hands = "Floral Gauntlets",
        legs = "Carmine Cuisses +1",
        swaps = {
            { -- Accuracy swapping rule
                test = function()
                    return settings.accuracy.index > 1
                end,
                neck = "Combatant's Torque"
            }
        }
    })

    sets.engaged.DW49 = set_combine(sets.engaged.DW42, {
        -- This set would need a DW augged herc helm, and I'm not about to do that
    })

    sets.engaged.DW52 = set_combine(sets.engaged.DW42, {back = Camulus.DW})

    sets.engaged.DW59 = set_combine(sets.engaged.DW49, {back = Camulus.DW})

    sets.TreasureHunter = {
        hands = "Volte Bracers",
        legs = Herc.Legs.TreasureHunter,
        waist = "Chaac Belt"
    }

end)

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
        if windower.file_exists(windower.addon_path .. '/data/graphics/' ..
                                    item_name .. '.png') then
            img = windower.addon_path .. '/data/graphics/' .. item_name ..
                      '.png'
        elseif windower.file_exists(
            windower.addon_path .. '/data/graphics/COR/' .. item_name .. '.png') then
            img = windower.addon_path .. '/data/graphics/COR/' .. item_name ..
                      '.png'
        else
            img = get_icon(item_name)
        end
        return {img = img, value = tostring(value)}
    end)
end

do
    local GUI_x = 1732
    local GUI_y = 70
    GUI.bound.y.lower = 70
    GUI.bound.y.upper = 471

    local main_button = IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.main,
        icons = get_icons(settings.main)
    })
    main_button:draw()

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

    local range_button = IconButton({
        x = GUI_x,
        y = GUI_y,
        var = settings.range,
        icons = get_icons(settings.range)
    })
    range_button:draw()

    GUI_y = GUI_y + 54

    local quick_draw_primary_select = IconButton(
                                          {
            x = GUI_x,
            y = GUI_y,
            var = settings.quickdraw1,
            icons = {
                {img = 'COR/Fire Shot.png', value = 'Fire'},
                {img = 'COR/Earth Shot.png', value = 'Earth'},
                {img = 'COR/Water Shot.png', value = 'Water'},
                {img = 'COR/Wind Shot.png', value = 'Wind'},
                {img = 'COR/Ice Shot.png', value = 'Ice'},
                {img = 'COR/Thunder Shot.png', value = 'Thunder'},
                {img = 'COR/Light Shot.png', value = 'Light'},
                {img = 'COR/Dark Shot.png', value = 'Dark'}
            }
        })
    quick_draw_primary_select:draw()

    GUI_y = GUI_y + 54

    local quick_draw_secondary_select = IconButton {
        x = GUI_x,
        y = GUI_y,
        var = settings.quickdraw2,
        icons = {
            {img = 'COR/Fire Shot.png', value = 'Fire'},
            {img = 'COR/Earth Shot.png', value = 'Earth'},
            {img = 'COR/Water Shot.png', value = 'Water'},
            {img = 'COR/Wind Shot.png', value = 'Wind'},
            {img = 'COR/Ice Shot.png', value = 'Ice'},
            {img = 'COR/Thunder Shot.png', value = 'Thunder'},
            {img = 'COR/Light Shot.png', value = 'Light'},
            {img = 'COR/Dark Shot.png', value = 'Dark'}
        }
    }
    quick_draw_secondary_select:draw()

    GUI_x = GUI_x + 54

    local roll_gear = ToggleButton {
        x = GUI_x,
        y = GUI_y,
        var = settings.roll_gear,
        iconUp = 'COR/RollGearOff.png',
        iconDown = 'COR/RollGearOn.png'
    }
    roll_gear:draw()

    GUI_x = GUI_x + 54

    local th_button = ToggleButton {
        x = GUI_x,
        y = GUI_y,
        var = TH.TreasureMode,
        iconUp = 'TH Off.png',
        iconDown = 'TH On.png'
    }
    th_button:draw()

    GUI_x = GUI_x - 108
    GUI_y = GUI_y + 54

    Divider({x = GUI_x, y = GUI_y, size = 150}):draw()

    GUI_y = GUI_y + 15

    local auto_ra_ws = IconButton {
        x = GUI_x,
        y = GUI_y,
        var = auto_ra.weaponskill,
        icons = {
            {img = 'COR/Leaden Salute.png', value = 'Leaden Salute'},
            {img = 'COR/Hot Shot.png', value = 'Hot Shot'},
            {img = 'COR/Wildfire.png', value = 'Wildfire'},
            {img = 'COR/Last Stand.png', value = 'Last Stand'},
            {img = 'COR/NO.png', value = ''}
        },
        overlay = {img = 'COR/Other.png', hide_on_click = false}
    }
    local skills_with_icons = S {
        'Leaden Salute', 'Hot Shot', 'Wildfire', 'Last Stand', ''
    }
    auto_ra.weaponskill.on_change:register(
        function(m)
            if skills_with_icons[m.value] then
                auto_ra_ws:hideoverlay()
            else
                auto_ra_ws:showoverlay()
            end
        end)
    auto_ra_ws:draw()

    GUI_x = GUI_x + 54

    local auto_ra_toggle = ToggleButton {
        x = GUI_x,
        y = GUI_y,
        var = auto_ra.enabled,
        iconUp = 'COR/RH Off.png',
        iconDown = 'COR/RH On.png'
    }
    auto_ra_toggle:draw()

    GUI_x = GUI_x + 54

    local stop_on_tp_toggle = ToggleButton {
        x = GUI_x,
        y = GUI_y,
        var = auto_ra.stop_on_tp,
        iconUp = 'COR/Stop on tp Off.png',
        iconDown = 'COR/Stop on tp On.png'
    }
    stop_on_tp_toggle:draw()

    GUI_x = GUI_x - 108
    GUI_y = GUI_y + 54

    local auto_ws_tp_slider = SliderButton {
        x = GUI_x,
        y = GUI_y,
        var = auto_ra.ws_tp,
        min = 1000,
        max = 3000,
        increment = 100,
        height = 144,
        icon = "COR/TP.png"
    }
    auto_ws_tp_slider:draw()

    GUI_x = GUI_x + 54

    local auto_ra_aftermath_toggle = ToggleButton {
        x = GUI_x,
        y = GUI_y,
        var = auto_ra.use_aftermath,
        iconUp = 'COR/Aftermath Off.png',
        iconDown = 'COR/Aftermath On.png'
    }
    auto_ra_aftermath_toggle:draw()

    GUI_x = GUI_x + 54

    local auto_ra_clear_button = FunctionButton {
        x = GUI_x,
        y = GUI_y,
        icon = 'COR/RH Clear.png',
        command = function() windower.send_command('gs rh clear') end
    }
    auto_ra_clear_button:draw()

    GUI_x = GUI_x + 56
    GUI_y = GUI_y + 54

    local acc_display = TextCycle {
        x = GUI_x,
        y = GUI_y,
        var = settings.accuracy,
        align = 'right',
        width = 112
    }
    acc_display:draw()

    GUI_y = GUI_y + 32

    local racc_display = TextCycle {
        x = GUI_x,
        y = GUI_y,
        var = settings.ranged_accuracy,
        align = 'right',
        width = 112
    }
    racc_display:draw()

    GUI_y = GUI_y + 32

    local dual_wield_mode_display = TextCycle {
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_mode,
        align = 'right',
        width = 112
    }
    dual_wield_mode_display:draw()

    GUI_y = GUI_y + 32

    local dual_wield_display = TextCycle {
        x = GUI_x,
        y = GUI_y,
        var = settings.dual_wield_level,
        align = 'right',
        width = 112,
        command = function() settings.dual_wield_mode:set('Manual') end
    }

    dual_wield_display:draw()
end

