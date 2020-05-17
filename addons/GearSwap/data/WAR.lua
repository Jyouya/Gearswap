require('Modes')
require('Gui')
require('DualWieldCalc')

function setup()
    AccuracyMode = M {
        ['description'] = 'Accuracy Mode',
        'Normal',
        'Mid',
        'High'
    }

    AbysseaMode = M(false, 'Abyssea Mode')
    OffhandMode = M {['description'] = 'Offhand Mode', 'Auto', 'Manual'}

    WeaponMode = M {
        ['description'] = 'Weapon',
        'Chango',
        'Montante +1',
        'Raetic Algol +1',
        'Shining One',
        'Kaja Staff',
        'Kaja Axe',
        'Kaja Sword'
    }
    Offhand = M {
        ['description'] = 'Offhand',
        'Reikiko',
        'Barbarity +1',
        'Digirbalag',
        'Blurred Shield +1'
    }
    AbysseaWeapon = M {
        ['description'] = 'Weapon',
        'Dagger',
        'Sword',
        'Greatsword',
        'Scythe',
        'Spear',
        'Club',
        'Staff',
        'Katana',
        'Great Katana'
    }

    EngagedMode = M {['description'] = 'Engaged Mode', 'Normal', 'Hybrid', 'DT'}
    IdleMode = M {['description'] = 'Idle Mode', 'Normal', 'Fell Cleave'} -- Normal idel gear or Su3 for fell cleave

    DWMode = M {['description'] = 'Dual Wield Mode', 'Auto', 'Manual'}
    DWLevel = M {['description'] = 'Dual Wield Level', '11', '15', '21', '25'}

    Obi_WS =
        T { -- Any weaponskills we want to check weather/day and use the obi
            'Cloudsplitter'
        }

    WeaponTable = {
        ['Chango'] = {main = "Chango", type = '2H', img = 'WAR/Chango.png'},
        ['Montante +1'] = {
            main = "Montante +1",
            type = '2H',
            img = 'WAR/Montante.png'
        },
        ['Raetic Algol +1'] = {
            main = "Raetic Algol +1",
            type = '2H',
            img = 'WAR/Raetic Algol.png.'
        },
        ['Shining One'] = {
            main = "Shining One",
            type = '2H',
            img = 'WAR/Bismarck.png'
        },
        ['Kaja Staff'] = {
            main = "Kaja Staff",
            type = '2H',
            img = 'WAR/Kaja Staff.png'
        },
        ['Kaja Axe'] = {
            main = "Dolichenus",
            type = '1H',
            DW = true,
            img = 'WAR/Kaja Axe.png',
            offhand = T {
                default = 'digirbalag',
                {buff = 'Fighter\'s Roll', weapon = 'Barbarity +1'},
                {buff = 'Mighty Strikes', weapon = 'Reikiko'}
            }
        },
        ['Kaja Sword'] = {
            main = "Kaja Sword",
            type = '1H',
            DW = true,
            img = 'WAR/Kaja Sword.png',
            offhand = T {
                default = 'Barbarity +1',
                {buff = 'Mighty Strikes', weapon = 'Reikiko'}
            }
        }
    }

    OffhandTable = {
        ['Reikiko'] = {sub = "Reikiko", img = 'WAR/Reikiko.png', DW = true},
        ['Barbarity +1'] = {
            sub = "Barbarity +1",
            img = 'WAR/Barbarity.png',
            DW = true
        },
        ['Digirbalag'] = {
            sub = "Digirbalag",
            img = 'WAR/Digirbalag.png',
            DW = true
        },
        ['Blurred Shield +1'] = {
            sub = "Blurred Shield +1",
            img = 'WAR/Blurred Shield.png',
            Fencer = true
        }
    }

    AWeaponTable = {
        ['Dagger'] = {main = "Bronze Dagger", img = 'WAR/Bronze Dagger.png'},
        ['Sword'] = {main = "Ibushi Shinai", img = 'WAR/Ibushi Shinai.png'},
        ['Greatsword'] = {main = "Claymore", img = 'WAR/Claymore.png'},
        ['Scythe'] = {main = "Bronze Zaghnal", img = 'WAR/Bronze Zaghnal.png'},
        ['Spear'] = {main = "Harpoon", img = 'WAR/Harpoon.png'},
        ['Club'] = {main = "Soulflayer's Wand", img = 'WAR/Ash Club.png'},
        ['Staff'] = {main = "Ash Staff", img = 'WAR/Ash Staff.png'},
        ['Katana'] = {main = "Debahocho", img = 'WAR/Debahocho.png'},
        ['Great Katana'] = {main = "Mutsunokami", img = 'WAR/Mutsunokami.png'}
    }

    selfCommandMaps = {
        ['set'] = function(arg)
            _G[arg[1]]:set(table.concat(table.slice(arg, 2, -1), " "));
            update_gear()
        end,
        ['toggle'] = function(arg)
            _G[arg[1]]:toggle();
            update_gear()
        end,
        ['cycle'] = function(arg)
            _G[arg[1]]:cycle();
            update_gear()
        end,
        ['cycleback'] = function(arg)
            _G[arg[1]]:cycleback();
            update_gear()
        end,
        ['update'] = update_gear,
        ['cursna'] = function() equip(sets.Cursna) end,
        ['cure'] = function() equip(sets.Cure) end
    }

    build_GUI()
    bind_keys()
    local dw_level = get_dw_level()
    DWLevel:set(tostring(dw_level))
end

function get_sets()
    setup()

    Cichol = {}
    Cichol.Acc = {
        name = "Cichol's Mantle",
        augments = {
            'DEX+20', 'Accuracy+20 Attack+20', 'Accuracy+10', '"Dbl.Atk."+10',
            'Phys. dmg. taken -10%'
        }
    }
    Cichol.STR = {
        name = "Cichol's Mantle",
        augments = {
            'STR+20', 'Accuracy+20 Attack+20', 'STR+10', '"Dbl. Atk."+10',
            'Phys. dmg. taken -10%'
        }
    }
    Cichol.VIT = {
        name = "Cichol's Mantle",
        augments = {
            'VIT+20', 'Accuracy+20 Attack+20', 'VIT+10',
            'Weapon skill damage +10%'
        }
    }
    Cichol.WSD = {
        name = "Cichol's Mantle",
        augments = {
            'STR+20', 'Accuracy+20 Attack+20', 'STR+10',
            'Weapon skill damage +10%', 'Phys. dmg. taken -10%'
        }
    }
    Cichol.DW = {
        name = "Cichol's Mantle",
        augments = {
            'DEX+20', 'Accuracy+20 Attack+20', 'Accuracy+10', '"Dbl.Atk."+10',
            'Phys. dmg. taken -10%'
        }
    } -- Dual Wield Cape

    Odyssean = {}
    Odyssean.Hands = {}
    Odyssean.Hands.WS = {
        name = "Odyssean Gauntlets",
        augments = {'Accuracy+25', 'Weapon skill damage +3%', 'VIT+4'}
    }
    Odyssean.Legs = {}
    Odyssean.Legs.STP = {
        name = "Odyssean Cuisses",
        augments = {'"Store TP"+7', 'Accuracy+13', 'Attack+20', 'VIT+8'}
    }
    Odyssean.Legs.WS = {
        name = "Odyssean Cuisses",
        augments = {'Accuracy+25 Attack+25', 'Weapon skill damage +3%', 'AGI+6'}
    }
    Odyssean.Feet = {}
    -- Odyssean.Feet.FC = { name="Odyssean Greaves", augments={'Attack+20','"Fast Cast"+4','Accuracy+15',}}

    Valorous = {}
    Valorous.Body = {}
    Valorous.Body.STP = {
        name = "Valorous Mail",
        augments = {
            'INT+10', 'MND+4', '"Store TP"+9', 'Mag. Acc.+1 "Mag.Atk.Bns."+1'
        }
    }

    sets.Obi = {waist = "Hachirin-No-Obi"}

    sets.Grip = {sub = "Utu Grip"}

    sets.Shield = {sub = "Blurred Shield +1"}

    sets.enmity = {
        head = "Halitus Helm",
        body = "Emet Harness +1",
        hands = "Pummeler's Mufflers +1",
        legs = "Odyssean Cuisses",
        neck = "Moonlight Necklace",
        waist = "Kasiri Belt",
        ear1 = "Friomisi Earring",
        ear2 = "Cryptic Earring",
        ring1 = "Petrov Ring",
        ring2 = "Eihwaz Ring"
    }

    sets.precast = {}

    sets.JA = {}

    sets.JA['Mighty Strikes'] = {hands = "Agoge Mufflers"}
    sets.JA['Blood Rage'] = {body = "Boii Lorica +1"}
    sets.JA['Warcry'] = {head = "Agoge Mask +3"}
    sets.JA['Berserk'] = {
        main = "Instigator",
        body = "Pumm. Lorica +3",
        feet = "Agoge Calligae +3"
    }
    sets.JA['Tomahawk'] = {ammo = "Throwing Tomahawk"}
    sets.JA['Provoke'] = sets.enmity
    sets.JA['Aggressor'] = {head = "Pummeler's Mask +1", body = "Agoge Lorica +3"}

    sets.precast = {
        ammo = "Impatiens",
        body = "Odyssean Chestplate",
        hands = "Leyline Gloves",
        legs = "Eschite Cuisses",
        feet = "Odyssean Greaves",
        ear1 = "Loquacious Earring",
        ring1 = "Moonlight Ring",
        ring2 = "Prolix Ring"
    }

    sets.precast.Utsusemi = set_combine(sets.precast, {neck = "Magoraga Beads"})

    sets.midcast = set_combine(sets.precast, {})

    sets.midcast.Utsusemi = set_combine(sets.precast.Utsusemi, {})

    -- Weaponskill Sets --
    -- format is sets.WS['Savage Blade']['Mighty Strikes']['Brazen Rush'].Fencer.TP[2000].Mid.Day
    -- Any value may be omitted, but they must be in order
    -- Buffs are calculated into TP.  Fencer is not

    sets.WS = {
        ammo = "Seething Bomblet +1",
        head = "Flamma Zucchetto +2",
        body = "Flamma Korazin +2",
        hands = "Sulevia's Gauntlets +2",
        legs = "Sulevia's Cuisses +2",
        feet = "Pummeler's Calligae +3",
        neck = "Fotia Gorget",
        waist = "Fotia Belt",
        ear1 = "Brutal Earring",
        ear2 = "Moonshade Earring",
        ring1 = "Niqmaddu Ring",
        ring2 = "Regal Ring",
        back = Cichol.STR
    }

    sets.WS.Mid = set_combine(sets.WS, {legs = "Pummeler's Cuisses +3"})

    sets.WS.Acc = set_combine(sets.WS.Mid, {
        body = "Pumm. Lorica +3",
        ear1 = "Telos Earring"
    })

    -- Great Axe Weaponskills --

    sets.WS.Upheaval = {
        ammo = "Knobkierrie",
        head = "Agoge Mask +3",
        body = "Pumm. Lorica +3",
        hands = Odyssean.Hands.WS,
        legs = Odyssean.Legs.WS,
        feet = "Sulevia's Leggings +2",
        neck = "War. Beads +1",
        waist = "Sailfi Belt +1",
        ear1 = "Thrud Earring",
        ear2 = "Moonshade Earring",
        ring1 = "Niqmaddu Ring",
        ring2 = "Gelatinous Ring +1",
        back = Cichol.VIT
    }

    sets.WS.Upheaval.Mid = set_combine(sets.WS.Upheaval, {
        legs = "Pummeler's Cuisses +3",
        ring1 = "Regal Ring"
    })

    sets.WS.Upheaval.High = set_combine(sets.WS.Upheaval.Mid, {
        feet = "Pummeler's Calligae +3",
        ear1 = "Telos Earring"
    })

    sets.WS['Fell Cleave'] = {
        ammo = "Knobkierrie",
        head = "Agoge Mask +3",
        body = "Pumm. Lorica +3",
        hands = "Sulevia's Gauntlets +2", -- DT hybrid
        legs = Odyssean.Legs.WS, -- DT hybrid
        feet = "Sulevia's Leggings +2",
        neck = "War. Beads +1",
        waist = "Sailfi Belt +1",
        ear1 = "Ishvara Earring",
        ear2 = "Moonshade Earring",
        ring1 = "Niqmaddu Ring",
        ring2 = "Regal Ring",
        back = Cichol.WSD
    }

    sets.WS['Steel Cyclone'] =
        set_combine(sets.WS.Upheaval, {back = Cichol.WSD})

    -- Great Sword Weaponskills --

    sets.WS['Scourge'] = set_combine(sets.WS.Upheaval, {back = Cichol.WSD})

    sets.WS.Resolution = {
        ammo = "Seething Bomblet +1",
        head = "Flamma Zucchetto +2",
        body = "Dagon Breastplate",
        hands = "Argosy Mufflers +1",
        legs = "Argosy Breeches +1",
        feet = "Pummeler's Calligae +3",
        neck = "Fotia Gorget",
        waist = "Fotia Belt",
        ear1 = {name = "Brutal Earring", priority = 15},
        ear2 = "Moonshade Earring",
        ring1 = "Niqmaddu Ring",
        ring2 = "Regal Ring",
        back = Cichol.STR
    }

    sets.WS.Resolution.Mid = set_combine(sets.WS.Resolution,
                                         {legs = "Pummeler's Cuisses +3"})

    sets.WS.Resolution.High = set_combine(sets.WS.Resolution.Mid,
                                          {ear1 = "Telos Earring"})

    sets.WS.Resolution.High.TP = {}
    sets.WS.Resolution.High.TP[2800] = set_combine(sets.WS.Resolution.High,
                                                   {ear2 = "Cessance Earring"})

    sets.WS.Resolution['Mighty Strikes'] =
        {
            ammo = "Seething Bomblet +1",
            head = "Flamma Zucchetto +2",
            body = "Argosy Hauberk +1", -- get some crit valorous augs
            hands = "Argosy Mufflers +1",
            legs = "Argosy Breeches +1",
            feet = "Boii Calligae +1",
            neck = "Fotia Gorget",
            waist = "Fotia Belt",
            ear1 = {name = "Brutal Earring", priority = 15},
            ear2 = "Moonshade Earring",
            ring1 = "Niqmaddu Ring",
            ring2 = "Regal Ring",
            back = Cichol.STR
        }

    -- Spear Weaponskills --

    -- sets.WS.Stardiver = {}

    -- sets.WS['Impulse Drive'] = {} -- low TP set
    -- sets.WS['Impulse Drive'].TP = {} -- leave blank
    -- sets.WS['Impulse Drive'].TP[2000] = {} -- High TP set
    -- sets.WS['Impulse Drive'].TP[2800] = {} -- Full TP set

    -- Sword Weaponskills --

    -- sets.WS['Savage Blade'] = {}
    -- sets.WS['Savage Blade'].TP = {} -- leave blank
    -- sets.WS['Savage Blade'].TP[2800] = {} -- full TP set without moonshade

    -- sets.WS['Savage Blade'].Fencer = {}
    -- sets.WS['Savage Blade'].Fencer.TP = {}
    -- sets.WS['Savage Blade'].Fencer.TP[2000] = {}

    -- sets.WS['Requiescat'] = {}

    -- Axe Weaponskills --

    sets.WS.Decimation = set_combine(sets.WS.Resolution,
                                     {ear2 = "Cessance Earring"})

    sets.WS.Decimation.Mid = set_combine(sets.WS.Resolution.Mid,
                                         {ear2 = "Cessance Earring"})

    sets.WS.Decimation.High = set_combine(sets.WS.Resolution.High,
                                          {ear2 = "Cessance Earring"})

    -- sets.WS.Cloudsplitter = {}

    -- Idle Sets --

    sets.idle = {}
    sets.idle.Normal = {
        ammo = "Staunch Tathlum +1",
        head = "Hjarrandi Helm",
        body = "Hjarrandi Breastplate",
        hands = "Sulevia's Gauntlets +2",
        legs = "Pummeler's Cuisses +3",
        feet = "Pummeler's Calligae +3",
        neck = "Sanctity Necklace",
        waist = "Asklepian Belt",
        -- ear1="Etoilation Earring",
        ear2 = "Infused Earring",
        ring1 = "Moonlight Ring",
        ring2 = "Gelatinous Ring +1",
        back = "Moonlight Cape"	
    }

    sets.idle['Fell Cleave'] = set_combine(sets.idle.Normal, {})

    -- Engaged Sets --

    sets.engaged = {
        ammo = "Ginsen",
        head = "Flamma Zucchetto +2",
        -- body=Valorous.Body.STP,
        body = "Dagon Breastplate",
        hands = "Sulevia's Gauntlets +2",
        legs = Odyssean.Legs.STP,
        feet = "Pummeler's Calligae +3",
        neck = "War. Beads +1",
        waist = "Ioskeha Belt +1",
        ear1 = "Brutal Earring",
        ear2 = "Cessance Earring",
        ring1 = "Niqmaddu Ring",
        ring2 = "Petrov Ring",
        back = Cichol.STR
    }

    sets.engaged.Mid = set_combine(sets.engaged, {
        body = "Dagon Breastplate",
        legs = "Pummeler's Cuisses +3",
        neck = "Warrior's Bead Necklace +1",
        ear1 = "Telos Earring",
        back = Cichol.Acc
    })

    sets.engaged.High = set_combine(sets.engaged.Mid, {
        body = "Pumm. Lorica +3",
        ring2 = "Moonlight Ring" -- "Regal Ring"
    })

    sets.engaged.DW = {
        ammo = "Ginsen",
        head = "Flamma Zucchetto +2",
        body = Valorous.Body.STP,
        hands = "Emicho Gauntlets +1",
        legs = "Pummeler's Cuisses +3",
        feet = "Pummeler's Calligae +3",
        neck = "War. Beads +1",
        waist = "Ioskeha Belt +1",
        ear1 = "Brutal Earring",
        ear2 = {name = "Suppanomimi", priority = 15},
        ring1 = "Niqmaddu Ring",
        ring2 = "Petrov Ring",
        back = Cichol.STR
    }

    sets.engaged.DW.Mid = set_combine(sets.engaged.DW, {
        body = "Emicho Haubert +1",
        legs = "Pummeller's Cuisses +3",
        neck = "Warrior's Bead Necklace +1",
        ear1 = "Cessance Earring",
        back = Cichol.Acc
    })

    sets.engaged.DW.High = set_combine(sets.engaged.DW.Mid, {
        ear1 = "Telos Earring",
        ring2 = "Moonlight Ring"
    })

    sets.engaged.DW['11'] = sets.engaged.DW

    sets.engaged.DW['15'] = set_combine(sets.engaged.DW,
                                        {ear1 = "Eabani Earring"})

    sets.engaged.DW['15'].Mid = set_combine(sets.engaged.DW.Mid,
                                            {ear1 = "Eabani Earring"})

    sets.engaged.DW['15'].High = set_combine(sets.engaged.DW.High,
                                             {ear1 = "Eabani Earring"})

    sets.engaged.DW['21'] = set_combine(sets.engaged.DW, {
        -- back=Cichol.DW,
    })

    sets.engaged.DW['21'].Mid = set_combine(sets.engaged.DW.Mid, {
        -- back=Cichol.DW,
    })

    sets.engaged.DW['21'].High = set_combine(sets.engaged.DW.High, {
        -- back=Cichol.DW,
    })

    sets.engaged.DW['25'] = set_combine(sets.engaged.DW, {
        ear1 = "Eabani Earring"
        -- back=Cichol.DW
    })

    sets.engaged.DW['25'].Mid = set_combine(sets.engaged.DW.Mid, {
        ear1 = "Eabani Earring"
        -- back=Cichol.DW
    })

    sets.engaged.DW['25'].High = set_combine(sets.engaged.DW.High, {
        ear1 = "Eabani Earring"
        -- back=Cichol.DW
    })

    sets.engaged.Hybrid = {
        ammo = "Staunch Tathlum +1",
        head = "Flamma Zucchetto +2",
        body = "Hjarrandi Breastplate",
        hands = "Sulevia's Gauntlets +2",
        legs = "Pummeler's Cuisses +3",
        feet = "Pummeler's Calligae +3",
        neck = "War. Beads +1",
        waist = "Ioskeha Belt +1",
        ear1 = "Telos Earring",
        ear2 = "Cessance Earring",
        ring1 = "Moonlight Ring",
        ring2 = "Defending Ring",
        back = Cichol.Acc
    }

    sets.engaged.Hybrid.DW = {
        ammo = "Staunch Tathlum +1",
        head = "Sulevia's Mask +2",
        body = "Hjarrandi Breastplate",
        hands = "Emicho Gauntlets +1",
        legs = "Pummeler's Cuisses +3",
        feet = "Pummeler's Calligae +3",
        neck = "War. Beads +1",
        waist = "Ioskeha Belt +1",
        ear1 = "Telos Earring",
        ear2 = "Suppanomimi",
        ring1 = "Moonlight Ring",
        ring2 = "Defending Ring",
        back = Cichol.Acc
    }

    sets.engaged.DT = {
        ammo = "Staunch Tathlum +1",
        head = "Souveran Schaller +1",
        body = "Hjarrandi Breastplate",
        hands = "Souveran Handschuhs +1",
        legs = "Souveran Diechlings +1",
        feet = "Souveran Schuhs +1",
        neck = "War. Beads +1",
        waist = "Ioskeha Belt +1",
        ear1 = "Telos Earring",
        ear2 = "Odnowa Earring +1",
        ring1 = {name = "Moonlight Ring", priority = 15, bag = "wardrobe3"},
        ring2 = {name = "Moonlight Ring", priority = 15, bag = "wardrobe2"},
        back = Cichol.Acc
    }

    -- Status Swaps --

    sets.Blind = {hands = "Regal Captain's Gloves"}
end

function bind_keys()
    send_command('bind f9 gs c cycle AccuracyMode')
    send_command('bind f10 gs c set EngagedMode Hybrid')
    send_command('bind f11 gs c set EngagedMode DT')
    send_command('bind f12 gs c set EngagedMode Normal')
end

function file_unload()
    send_command('unbind f9')
    send_command('unbind f10')
    send_command('unbind f11')
    send_command('unbind f12')
end

function build_GUI()
    GUI_pos = {}
    GUI_pos.x = 1732
    GUI_pos.y = 80

    EM = IconButton {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 0,
        var = EngagedMode,
        icons = {
            {img = 'DD Normal.png', value = 'Normal'},
            {img = 'DD Hybrid.png', value = 'Hybrid'},
            {img = 'Emergancy DT.png', value = 'DT'}
        },
        command = 'gs c update'
    }
    EM:draw()

    local wi = {}
    for i, v in ipairs(WeaponMode) do
        wi[i] = {img = WeaponTable[v].img, value = v}
    end
    WM = IconButton {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54,
        var = WeaponMode,
        icons = wi,
        command = 'gs c update'
    }
    WM:draw()

    --[[FM = ToggleButton{
		x = GUI_pos.x + 0,
		y = GUI_pos.y + 54 * 2,
		var = FencerMode,
		iconUp = 'WAR/Fencer Off.png',
		iconDown = 'WAR/Fencer On.png',
		command = 'gs c update'
	}
	FM:draw()]]

    local oh = {}
    for i, v in ipairs(Offhand) do
        oh[i] = {img = OffhandTable[v].img, value = v}
    end
    OH_button = IconButton {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 2,
        var = Offhand,
        icons = oh,
        command = function()
            OffhandMode:set('Manual');
            windower.send_command('gs c update');
            OH_button:hideoverlay()
        end,
        overlay = {img = 'WAR/Auto.png', hide_on_click = false}
        -- on_click = function() OffhandMode:set('Manual') end
    }
    OH_button:draw()
    OH_button:showoverlay()

    AbbyM = ToggleButton {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 3,
        var = AbysseaMode,
        iconUp = 'WAR/Atomos.png',
        iconDown = 'WAR/Atomos.png',
        command = function()
            if AbysseaMode.value then
                AbbyW:enable();
                AbbyW:show()
            else
                AbbyW:disable();
                AbbyW:hide()
            end
            windower.send_command('gs c update')
        end
    }
    AbbyM:draw()

    local aw = {}
    for i, v in ipairs(AbysseaWeapon) do
        aw[i] = {img = AWeaponTable[v].img, value = v}
    end
    AbbyW = IconButton {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 4,
        var = AbysseaWeapon,
        icons = aw,
        command = 'gs c update'
    }
    AbbyW:draw()
    AbbyW:hide()

    AccDisplay = TextCycle {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 5,
        var = AccuracyMode,
        align = 'left',
        width = 112,
        command = 'gs c update'
    }
    AccDisplay:draw()
    IdleDisplay = TextCycle {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 5 + 32,
        var = IdleMode,
        align = 'left',
        width = 112,
        command = 'gs c update'
    }
    IdleDisplay:draw()
    OHModeDisplay = TextCycle {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 5 + 32 * 2,
        var = OffhandMode,
        align = 'left',
        width = 112,
        command = function()
            if OffhandMode.value == 'Auto' then
                OH_button:showoverlay();
                windower.send_command('gs c update')
            else
                OH_button:hideoverlay()
            end
        end
    }
    OHModeDisplay:draw()
    HMDisplay = TextCycle {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 5 + 32 * 3,
        var = DWMode,
        align = 'left',
        width = 112,
        command = function() windower.send_command('gs c update') end,
        start_hidden = true,
        disabled = true
    }
    HMDisplay:draw()
    DWDisplay = TextCycle {
        x = GUI_pos.x + 0,
        y = GUI_pos.y + 54 * 5 + 32 * 4,
        var = DWLevel,
        align = 'left',
        width = 112,
        command = function()
            DWMode:set('Manual');
            windower.send_command('gs c update')
        end,
        start_hidden = true,
        disabled = true
    }
    DWDisplay:draw()
end

function self_command(commandArgs)
    local commandArgs = commandArgs
    if type(commandArgs) == 'string' then
        commandArgs = T(commandArgs:split(' '))
        if #commandArgs == 0 then return end
    end
    local handleCmd = table.remove(commandArgs, 1)
    if selfCommandMaps[handleCmd] then
        selfCommandMaps[handleCmd](commandArgs)
    end
end

function get_weapons()
    local weps = {}
    if AbysseaMode.value then
        weps = AWeaponTable[AbysseaWeapon.value]
    else
        weps = WeaponTable[WeaponMode.value]
        if weps.type == '1H' then
            weps = set_combine(weps, OffhandTable[Offhand.value])
            -- table.map(weps, print)
        else
            weps = set_combine(weps, sets.Grip)
        end
    end
    return weps
end

function get_idle_set()
    local dw_level = get_dw_level()
    if dw_level ~= DWLevel.value and DWMode.value == 'Auto' then
        DWLevel:set(tostring(dw_level))
    end
    return set_combine(sets.idle[IdleMode.value], get_weapons())
end

function get_engaged_set() -- sets.engaged[DefenseMode].(DW or WeaponMode).Accuracy.AM3
    local equipset = sets.engaged
    if equipset[EngagedMode.value] then
        equipset = equipset[EngagedMode.value]
    end
    
    if equipset[WeaponMode.value] then -- sets.engaged[DefenseMode].Chango or something if desired.  Can also do .mainhand.offhand if you wanna get specific
        equipset = equipset[WeaponMode.value]
        if equipset[Offhand.value] then
            equipset = equipset[Offhand.value]
        end
    end
    if equipset.DW and WeaponTable[WeaponMode.value].type == '1H' and
        OffhandTable[Offhand.value].DW and
        (player.sub_job == 'DNC' or player.sub_job == 'NIN') then
        equipset = equipset.DW
        local dw_level = get_dw_level()
        if dw_level ~= DWLevel.value and DWMode.value == 'Auto' then
            DWLevel:set(tostring(dw_level))
        end
        if equipset[DWLevel.value] then
            equipset = equipset[DWLevel.value]
        end

    end
    if equipset[AccuracyMode.value] then
        equipset = equipset[AccuracyMode.value]
    end
    if equipset.AM3 and buffactive['Aftermath: Lv.3'] then
        equipset = equipset.AM3
    end

    if buffactive['Flash'] or buffactive['Blindness'] then
        equipset = set_combine(equipset, sets.Blind)
    end

    local neck = AbysseaMode.value and {neck = "Combatant's Torque"} or {}
    local head = AbysseaMode.value and AbysseaWeapon.value == 'Great Katana' and
                     {head = "Kengo Hachimaki"} or {}
    equipset = set_combine(equipset, get_weapons(), neck, head)
    return equipset
end

function update_gear() -- will put on the appropriate engaged or idle set
    if OffhandMode.value == 'Auto' then auto_offhand() end
    if WeaponTable[WeaponMode.value].type == '1H' and
        OffhandTable[Offhand.value].DW then
        HMDisplay:enable()
        HMDisplay:show()
        DWDisplay:enable()
        DWDisplay:show()
    else
        HMDisplay:disable()
        HMDisplay:hide()
        DWDisplay:disable()
        DWDisplay:hide()
    end

    if player.status == 'Engaged' then
        equip(get_engaged_set())
    else
        equip(get_idle_set())
    end
end

function auto_offhand()
    if WeaponTable[WeaponMode.value].type == '1H' then
        local OH = ''
        if player.sub_job == 'DNC' or player.sub_job == 'NIN' then
            OH = WeaponTable[WeaponMode.value].offhand.default
            for i, v in ipairs(WeaponTable[WeaponMode.value].offhand) do
                if buffactive[v.buff] then OH = v.weapon end
            end

        else
            OH = sets.Shield.sub
        end
        Offhand:set(OH)
    end
end

function pretarget(spell) -- Would also check range here, if we wanted to avoid getting 'too far'
    if spell.type == 'WeaponSkill' then
        if player.tp < 1000 or buffactive['Stun'] or buffactive['Terror'] or
            buffactive['Amnesia'] or buffactive['Sleep'] or
            buffactive['Petrification'] then cancel_spell() end
    end
    -- TODO: cancel berserk/aggressor if they're on cooldown, so we don't drop TP.
end

function precast(spell, action)
    if spell.action_type == 'Magic' then
        if spell.name:contains('Utsusemi') then
            equip(sets.precast.Utsusemi)
        elseif sets.precast[spell.name] then
            equip(sets.precast[spell.name])
        elseif sets.precast[spell.skill] then
            equip(sets.precast[spell.skill])
        else
            equip(sets.precast)
        end
    elseif spell.type == 'WeaponSkill' then
        local equipset = sets.WS
        if equipset[spell.name] then equipset = equipset[spell.name] end
        if equipset['Mighty Strikes'] and buffactive['Mighty Strikes'] then
            equipset = equipset['Mighty Strikes']
        end
        if equipset['Brazen Rush'] and buffactive['Brazen Rush'] then
            equipset = equipset['Brazen Rush']
        end
        if equipset.Fencer and OffhandTable[Offhand.value].Fencer then
            equipset = equipset.Fencer
        end
        if equipset.TP then -- sets.WS['Impulse Drive'].TP[2000].Mid.Day will be used when over 2000 TP
            local t = 1000
            local use_tp_set = false
            for tp, set in pairs(equipset.TP) do
                if tp > t and player.tp + (buffactive['warcry'] and 500 or 0) >
                    tp then
                    t = tp
                    use_tp_set = true
                end
            end
            if use_tp_set then equipset = equipset.TP[t] end
        end
        if equipset[AccuracyMode.value] then
            equipset = equipset[AccuracyMode.value]
        end
        if equipset.Day then
            if world.time < 1020 or world.time >= 420 then
                equipset = equipset.Day
            end
        elseif equipset.Night then
            if world.time >= 1020 or world.time < 420 then
                equipset = equipset.Night
            end
        end

        local neck = AbysseaMode.value and {neck = "Combatant's Torque"} or {}
        equip(equipset, neck)
        if Obi_WS:contains(spell.name) and
            (world.weather_element == spell.element or world.day_element ==
                spell.element) then equip(sets.Obi) end
    elseif spell.name:contains('Waltz') then
        equip(sets.precast.Waltz)
    elseif spell.name:contains('Step') then
        equip(sets.precast.Step)
    elseif spell.type == 'JobAbility' then
        if sets.JA[spell.name] then equip(sets.JA[spell.name]) end
    end

    local neck = AbysseaMode.value and {neck = "Combatant's Torque"} or {}
    local head = AbysseaMode.value and AbysseaWeapon.value == 'Great Katana' and
                     {head = "Kengo Hachimaki"} or {}
    equip(get_weapons(), neck, head)
end

function midcast(spell, action)
    if spell.action_type == 'Magic' then
        if spell.name:contains('Utsusemi') then
            equip(sets.midcast.Utsusemi)
        elseif sets.midcast[spell.name] then
            equip(sets.midcast[spell.name])
        elseif sets.midcast[spell.skill] then
            equip(sets.midcast[spell.skill])
        else
            equip(sets.midcast)
        end
    end
end

function aftercast(spell, action) update_gear() end

function status_change(new, action) update_gear() end

function buff_change(buff, gain)
    if buff == 'Haste' and not gain then Haste_Level = 0 end
    local dw_level = get_dw_level()
    if dw_level ~= DWLevel.value then
        DWLevel:set(tostring(dw_level))
        update_gear()
    end
end

function get_dw_level()
    local dw_needed = get_dw_needed()
    local dw_level = math.max(unpack(DWLevel))
    for i, dw in ipairs(DWLevel) do -- find the lowest dw that is >= dw_needed
        if tonumber(dw) < dw_level and tonumber(dw) >= dw_needed then
            dw_level = tonumber(dw)
        end
    end
    return dw_level
end

