require('table')
require('Modes')
require('sets')
local events = require('J-Swap-Events')
local command = require('J-Swap-Command')

spell_map = spell_map or require('J-Map')
sets = sets or {
    idle = {},
    engaged = {},
    item = {},
    JA = {},
    WS = {},
    precast = {RA = {}},
    midcast = {RA = {}}
}
settings = settings or {}
rules = table.update({
    precast = T {},
    midcast = T {},
    idle = T {},
    engaged = T {}
}, rules or {})

raw_set_combine = set_combine
do
    local combinable_keys = S {'swap_managed_weapon', 'swaps'}
    function set_combine(...)
        local new_set = raw_set_combine(...)
        for _, set in ipairs {...} do
            for key in pairs(combinable_keys) do
                new_set[key] = set[key] or new_set[key]
            end
        end
        return new_set
    end
end

local get_midcast
local player_incapacitated

local slots = S {
    'main', 'sub', 'range', 'ammo', 'head', 'body', 'hands', 'legs', 'feet',
    'neck', 'waist', 'left_ear', 'right_ear', 'left_ring', 'right_ring', 'back',
    'ear1', 'ear2', 'ring1', 'ring2'
}

local function empty_set(set)
    for k, _ in pairs(set) do
        if slots:contains(k:lower()) then return false end
    end
    return true
end

local function get_max_recast(spell)
    if spell.recast_id == 231 then -- strategems
        return player.main_job == 'SCH' and 132 or 120
    elseif spell.recast_id == 195 then
        return 30
        -- TODO: Get other stacking cooldowns, Maneuvers possibly?
    else
        return 0
    end
end

-- TODO: remove this
local function resolve_mode_alias(value)
    -- return type(value) == 'table' and value.value or value
    return value
end

local magic_prefixes = S {'/magic', '/ninjutsu', '/song'}

local pretarget
do
    local ranges = {
        [0] = 1,
        [2] = 3.4,
        [3] = 4.47273,
        [4] = 5.76,
        [5] = 6.88889,
        [6] = 7.8,
        [7] = 8.4,
        [8] = 10.4,
        [9] = 12.4,
        [10] = 14.5,
        [11] = 16.4,
        [12] = 20.4
    }
    pretarget = function(spell)
        if spell.prefix == '/item' then return end
        if spell.range and spell.target.distance and ranges[spell.range] +
            (spell.target.model_size or 0) < spell.target.distance then
            return cancel_spell()
        end
        if spell.type == 'WeaponSkill' then
            if player.tp < 1000 then return cancel_spell() end
            if player_incapacitated() or buffactive.Amnesia then
                return cancel_spell()
            end
        elseif spell.prefix == '/jobability' then
            if player_incapacitated() or buffactive.Amnesia then
                return cancel_spell()
            end
            local recasts = windower.ffxi.get_spell_recasts()
            if recasts[spell.recast_id] > get_max_recast(spell) then
                return cancel_spell()
            end
        elseif magic_prefixes[spell.prefix] then
            if player_incapacitated() then return cancel_spell() end
            local recasts = windower.ffxi.get_spell_recasts()
            if recasts[spell.recast_id] > get_max_recast(spell) then
                return cancel_spell()
            end
        end
    end
end

local function precast(spell, action)
    local equip_set = {}
    local breadcrumbs = T {}
    spell.map = spell_map[spell.english]

    -- Find the base set

    local category1 -- Used to create things like Weapon skill modes or casting modes
    if spell.type == 'WeaponSkill' then
        equip_set = sets.WS
        breadcrumbs:append('WS')
        category1 = 'WeaponSkill'
    elseif magic_prefixes[spell.prefix] then
        equip_set = sets.precast
        breadcrumbs:append('precast')
        category1 = 'Magic'
    elseif spell.prefix == '/jobability' then
        equip_set = sets.JA
        breadcrumbs:append('JA')
        category1 = 'JobAbility'
    elseif spell.prefix == '/range' then
        equip_set = sets.precast.RA
        breadcrumbs:append('precast')
        breadcrumbs:append('RA')
        category1 = 'Ranged'
    elseif spell.type == 'Item' then
        equip_set = sets.item
        breadcrumbs:append('item')
        category1 = 'Item'
    end

    local category_setting = settings[category1] and settings[category1].value
    if equip_set[category_setting] then
        equip_set = equip_set[category_setting]
        breadcrumbs:append(category_setting)
    end

    -- Get the tree for this skill
    local category2
    if equip_set[spell.english] then
        equip_set = equip_set[spell.english]
        breadcrumbs:append(spell.english)
        category2 = spell.english
    elseif equip_set[spell.map] then
        equip_set = equip_set[spell.map]
        breadcrumbs:append(spell.map)
        category2 = spell.map
    elseif equip_set[spell.type] then
        equip_set = equip_set[spell.type]
        breadcrumbs:append(spell.type)
        category2 = spell.type
    elseif equip_set[spell.skill] then
        equip_set = equip_set[spell.skill]
        breadcrumbs:append(spell.skill)
        category2 = spell.skill
    end

    -- Main/sub/range modifiers (mostly for aftermath sets)

    local main_hand = settings.main and settings.main.value
    local off_hand

    if main_hand and equip_set[main_hand] then
        equip_set = equip_set[main_hand]
        breadcrumbs:append(main_hand)

        local off_hand = settings.sub and settings.sub.value

        if off_hand and equip_set[off_hand] then
            equip_set = equip_set[off_hand]
            breadcrumbs:append(off_hand)
        end
    end

    local range = settings.range and settings.range.value

    if range and equip_set[range] then
        equip_set = equip_set[range]
        breadcrumbs:append(range)
    end

    -- Aftermath sets

    local aftermath_level = 0
    if buffactive['Aftermath: Lv.3'] then
        aftermath_level = 3
    elseif buffactive['Aftermath: Lv.2'] then
        aftermath_level = 2
    elseif buffactive['Aftermath: Lv.1'] or buffactive['Aftermath'] then
        aftermath_level = 1
    end

    if aftermath_level == 3 and equip_set.AM3 then
        equip_set = equip_set.AM3
        breadcrumbs:append('AM3')
    elseif aftermath_level >= 2 and equip_set.AM2 then
        equip_set = equip_set.AM2
        breadcrumbs:append('AM2')
    elseif aftermath_level >= 1 then
        if equip_set.AM1 then
            equip_set = equip_set.AM1
            breadcrumbs:append('AM1')
        elseif equip_set.AM then
            equip_set = equip_set.AM
            breadcrumbs:append('AM')
        end
    end

    -- User toggles
    local spell_setting = settings[category2] and settings[category2].value
    if equip_set[spell_setting] then
        equip_set = equip_set[spell_setting]
        breadcrumbs:append(spell_setting)
    end

    equip_set = table.copy(equip_set) -- shallow copy the set, so that rules can mutate it

    -- User defined gear rules
    for _, rule in ipairs(rules.precast) do
        if rule.test(equip_set, spell, action) then
            local key = type(rule.key) == 'function' and
                            rule.key(equip_set, spell, action) or rule.key
            if equip_set[key] then
                equip_set = equip_set[key]
                breadcrumbs:append(key)
            end
        end
    end

    print(breadcrumbs:concat('.'))

    -- If a set is empty, go back up the tree till a set has gear
    if empty_set(equip_set) then -- if it contains no gear
        for i = #breadcrumbs - 1, 1, -1 do
            table.remove(breadcrumbs, i + 1)
            local s = sets
            for j = 1, i, 1 do s = s[breadcrumbs[j]] end
            if not empty_set(s) then
                equip_set = s
                break
            end
        end
    end

    -- gear substitutions
    local final_set = equip_set
    if equip_set.swaps then
        for _, swap in ipairs(equip_set.swaps) do
            if swap.test(spell, action) then
                final_set = set_combine(final_set, swap)
            end
        end
    end

    -- If we have managed weapons
    if main_hand or range then
        local swap_managed_weapon = equip_set.swap_managed_weapon
        if not (swap_managed_weapon and swap_managed_weapon(spell, action)) then
            main_hand = resolve_mode_alias(main_hand)
            off_hand = resolve_mode_alias(off_hand)
            range = resolve_mode_alias(range)
            if main_hand then
                final_set = set_combine(final_set, {main = main_hand})
            end
            if off_hand then
                final_set = set_combine(final_set, {sub = off_hand})
            end
            if range then
                final_set = set_combine(final_set, {range = range})
            end
        end
    end

    -- ! For ranged attacks, precast Ammo MUST be the same as midcast
    if spell.prefix == '/range' then
        local midcast_set = get_midcast(spell)
        local ammo = settings.ammo and settings.ammo.value
        if midcast_set.ammo then
            final_set = set_combine({ammo = midcast_set.ammo}, final_set)
        elseif ammo then
            final_set = set_combine({ammo = ammo}, final_set)
        end
    end

    equip(final_set)
end

get_midcast = function(spell)
    local equip_set = {}
    local breadcrumbs = T {}
    -- ? Since I mutated spell in precast, does it already have map?
    -- spell.map = spell_map[spell.english] 

    -- Find the base set

    local category1 -- Used to create things like Weapon skill modes or casting modes
    if spell.type == 'WeaponSkill' then
        return
    elseif magic_prefixes[spell.prefix] then
        equip_set = sets.midcast
        breadcrumbs:append('midcast')
        category1 = 'Magic'
    elseif spell.type == 'JobAbility' then
        return
    elseif spell.prefix == '/range' then
        equip_set = sets.midcast.RA
        breadcrumbs:append('midcast')
        breadcrumbs:append('RA')
        category1 = 'Ranged'
    elseif spell.type == 'Item' then
        return
    end

    local category_setting = settings[category1] and settings[category1].value
    if equip_set[category_setting] then
        equip_set = equip_set[category_setting]
        breadcrumbs:append(category_setting)
    end

    -- Get the tree for this skill

    local category2
    if equip_set[spell.english] then
        equip_set = equip_set[spell.english]
        breadcrumbs:append(spell.english)
        category2 = spell.english
    elseif equip_set[spell.map] then
        equip_set = equip_set[spell.map]
        breadcrumbs:append(spell.map)
        category2 = spell.map
    elseif equip_set[spell.type] then
        equip_set = equip_set[spell.type]
        breadcrumbs:append(spell.type)
        category2 = spell.type
    elseif equip_set[spell.skill] then
        equip_set = equip_set[spell.skill]
        breadcrumbs:append(spell.skill)
        category2 = spell.skill
    end

    -- Main/sub/range modifiers (mostly for aftermath sets)

    local main_hand = settings.main and settings.main.value
    local off_hand

    if main_hand and equip_set[main_hand] then
        equip_set = equip_set[main_hand]
        breadcrumbs:append(main_hand)

        off_hand = settings.sub and settings.sub.value

        if off_hand and equip_set[off_hand] then
            equip_set = equip_set[off_hand]
            breadcrumbs:append(off_hand)
        end
    end

    local range = settings.range and settings.range.value or
                      player.equipment.range

    if range and equip_set[range] then
        equip_set = equip_set[range]
        breadcrumbs:append(range)
    end

    -- Aftermath sets

    local aftermath_level = 0
    if buffactive['Aftermath: Lv.3'] then
        aftermath_level = 3
    elseif buffactive['Aftermath: Lv.2'] then
        aftermath_level = 2
    elseif buffactive['Aftermath: Lv.1'] or buffactive['Aftermath'] then
        aftermath_level = 1
    end

    if aftermath_level == 3 and equip_set.AM3 then
        equip_set = equip_set.AM3
        breadcrumbs:append('AM3')
    elseif aftermath_level >= 2 and equip_set.AM2 then
        equip_set = equip_set.AM2
        breadcrumbs:append('AM2')
    elseif aftermath_level >= 1 then
        if equip_set.AM1 then
            equip_set = equip_set.AM1
            breadcrumbs:append('AM1')
        elseif equip_set.AM then
            equip_set = equip_set.AM
            breadcrumbs:append('AM')
        end
    end

    -- User toggles
    local spell_setting = settings[category2] and settings[category2].value
    if equip_set[spell_setting] then
        equip_set = equip_set[spell_setting]
        breadcrumbs:append(spell_setting)
    end

    equip_set = table.copy(equip_set) -- shallow copy the set, so that rules can mutate it

    -- User defined gear rules
    for _, rule in ipairs(rules.midcast) do
        if rule.test(equip_set, spell) then
            local key = type(rule.key) == 'function' and
                            rule.key(equip_set, spell) or rule.key
            if equip_set[key] then
                equip_set = equip_set[key]
                breadcrumbs:append(key)
            end
        end
    end

    print(breadcrumbs:concat('.'))

    -- If a set is empty, go back up the tree till a set has gear
    if empty_set(equip_set) then -- if it contains no gear
        for i = #breadcrumbs - 1, 1, -1 do
            table.remove(breadcrumbs, i + 1)
            local s = sets
            for j = 1, i, 1 do s = s[breadcrumbs[j]] end
            if not empty_set(s) then
                equip_set = s
                break
            end
        end
    end

    -- gear substitutions
    local final_set = equip_set
    if equip_set.swaps then
        for _, swap in ipairs(equip_set.swaps) do
            if swap.test(spell) then
                final_set = set_combine(final_set, swap)
            end
        end
    end

    -- If we have managed weapons
    if main_hand or range then
        local swap_managed_weapon = equip_set.swap_managed_weapon
        if not (swap_managed_weapon and swap_managed_weapon(spell)) then
            main_hand = resolve_mode_alias(main_hand)
            off_hand = resolve_mode_alias(off_hand)
            range = resolve_mode_alias(range)
            if main_hand then
                final_set = set_combine(final_set, {main = main_hand})
            end
            if off_hand then
                final_set = set_combine(final_set, {sub = off_hand})
            end
            if range then
                final_set = set_combine(final_set, {range = range})
            end
        end
    end

    -- ! For ranged attacks, precast Ammo MUST be the same as midcast
    if spell.prefix == '/range' then
        if not equip_set.ammo then
            local ammo = settings.ammo and settings.ammo.value
            if ammo then
                final_set = set_combine({ammo = ammo}, final_set)
            end
        end
    end

    return final_set
end

local function midcast(spell) equip(get_midcast(spell)) end

local function get_idle_set()
    local equip_set = sets.idle
    local breadcrumbs = T {'idle'}

    local idle_mode = settings.idle and settings.idle.value
    if idle_mode and equip_set[idle_mode] then
        equip_set = equip_set[idle_mode]
        breadcrumbs:append(idle_mode)
    end

    local main_hand = settings.main and settings.main.value
    local off_hand = settings.sub and settings.sub.value
    if main_hand and equip_set[main_hand] then
        equip_set = equip_set[main_hand]
        breadcrumbs:append(main_hand)

        if off_hand and equip_set[off_hand] then
            equip_set = equip_set[off_hand]
            breadcrumbs:append(off_hand)
        end
    end

    local range = settings.range and settings.range.value or
                      player.equipment.range

    if range and equip_set[range] then
        equip_set = equip_set[range]
        breadcrumbs:append(range)
    end

    equip_set = table.copy(equip_set) -- shallow copy the set, so that rules can mutate it

    for _, rule in ipairs(rules.idle) do
        if rule.test(equip_set) then
            local key = type(rule.key) == 'function' and rule.key(equip_set) or
                            rule.key
            if equip_set[key] then
                equip_set = equip_set[key]
                breadcrumbs:append(key)
            end
        end
    end

    -- If a set is empty, go back up the tree till a set has gear
    if empty_set(equip_set) then -- if it contains no gear
        for i = #breadcrumbs - 1, 1, -1 do
            table.remove(breadcrumbs, i + 1)
            local s = sets
            for j = 1, i, 1 do s = s[breadcrumbs[j]] end
            if not empty_set(s) then
                equip_set = s
                break
            end
        end
    end

    local final_set = equip_set
    if equip_set.swaps then
        for _, swap in ipairs(equip_set.swaps) do
            if swap.test() then
                final_set = set_combine(final_set, swap)
            end
        end
    end

    main_hand = resolve_mode_alias(main_hand)
    off_hand = resolve_mode_alias(off_hand)
    range = resolve_mode_alias(range)

    if main_hand then final_set = set_combine(final_set, {main = main_hand}) end
    if off_hand then final_set = set_combine(final_set, {sub = off_hand}) end
    if range then final_set = set_combine(final_set, {range = range}) end

    return final_set
end

local function get_engaged_set()
    local equip_set = sets.engaged
    local breadcrumbs = T {'engaged'}

    local engaged_mode = settings.engaged and settings.engaged.value
    if engaged_mode and equip_set[engaged_mode] then
        equip_set = equip_set[engaged_mode]
        breadcrumbs:append(engaged_mode)
    end

    local main_hand = settings.main and settings.main.value
    local off_hand = settings.sub and settings.sub.value
    if main_hand and equip_set[main_hand] then
        equip_set = equip_set[main_hand]
        breadcrumbs:append(main_hand)

        if off_hand and equip_set[off_hand] then
            equip_set = equip_set[off_hand]
            breadcrumbs:append(off_hand)
        end
    end

    local range = settings.range and settings.range.value or
                      player.equipment.range

    if range and equip_set[range] then
        equip_set = equip_set[range]
        breadcrumbs:append(range)
    end

    equip_set = table.copy(equip_set) -- shallow copy the set, so that rules can mutate it

    for _, rule in ipairs(rules.engaged) do
        if rule.test(equip_set) then
            local key = type(rule.key) == 'function' and rule.key(equip_set) or
                            rule.key
            if equip_set[key] then
                equip_set = equip_set[key]
                breadcrumbs:append(key)
            end
        end
    end

    -- If a set is empty, go back up the tree till a set has gear
    if empty_set(equip_set) then -- if it contains no gear
        for i = #breadcrumbs - 1, 1, -1 do
            table.remove(breadcrumbs, i + 1)
            local s = sets
            for j = 1, i, 1 do s = s[breadcrumbs[j]] end
            if not empty_set(s) then
                equip_set = s
                break
            end
        end
    end

    local final_set = equip_set
    if equip_set.swaps then
        for _, swap in ipairs(equip_set.swaps) do
            if swap.test() then
                final_set = set_combine(final_set, swap)
            end
        end
    end

    main_hand = resolve_mode_alias(main_hand)
    off_hand = resolve_mode_alias(off_hand)
    range = resolve_mode_alias(range)

    if main_hand then final_set = set_combine(final_set, {main = main_hand}) end
    if off_hand then final_set = set_combine(final_set, {sub = off_hand}) end
    if range then final_set = set_combine(final_set, {range = range}) end

    return final_set
end

player_incapacitated = function()
    -- TODO: generalize this with a set union of buffactive and incapacitating buffs
    return buffactive.Sleep or buffactive.Petrification or buffactive.Lullaby or
               buffactive.Stun or buffactive.Terror
end

local function update_gear()
    if player.status == 'Engaged' and not player_incapacitated() then
        equip(get_engaged_set())
    else
        equip(get_idle_set())
    end
end

local function aftercast(spell) if not pet_midaction() then update_gear() end end

-- TODO: figure out how the haste library fits into this
local function buff_change(name, gain, buff_details)
    if not (midaction() or pet_midaction()) then update_gear() end
end

local function status_change(new, old) update_gear() end

local function pet_aftercast(spell) update_gear() end

events.pretarget:register(pretarget)
events.precast:register(precast)
events.midcast:register(midcast)
events.aftercast:register(aftercast)
events.pet_aftercast:register(pet_aftercast)
events.buff_change:register(buff_change)
events.status_change:register(status_change)
events.update:register(update_gear)

command:register('update', update_gear)
command:register('set', function(name, value) settings[name]:set(value) end,
                 'name value')
command:register('toggle', function(name) settings[name]:toggle() end, 'name')
command:register('cycle', function(name) settings[name]:cycle() end, 'name')
command:register('cycleback', function(name) settings[name]:cycleback() end,
                 'name')

