require('rnghelper')
require('modes')
require('GUI')
require('DualWieldCalc')
res = require('resources')
packets = require('packets')
require('cor.include')
local TH = require('TreasureHunter.lua')


function get_sets()
	bind_keys()
	setup()
	require(('COR-%s-Gear'):format(player.name))
	build_gearsets()
		
	build_UI()
end

function bind_keys()
	-- set keybinds
	send_command('bind f9 gs c cycle meleeAccuracy')
	send_command('bind ^f9 gs c cycle rangedAccuracy')
	send_command('bind !f9 gs c cycle magicAccuracy')
	send_command('bind @f9 gs c cycle hotshotAccuracy')
	
	send_command('bind f10 gs c set DDMode Emergancy DT')
	send_command('bind ^f10 gs c cycle DDMode')
	
	send_command('bind f11 gs c cycle quickdrawElement1')
	send_command('bind ^f11 gs c cycleback quickdrawElement1')
	send_command('bind !f11 gs c cycle quickdrawMode1')
	
	send_command('bind f12 gs c cycle quickdrawElement2')
	send_command('bind ^f12 gs c cycleback quickdrawElement2')
	send_command('bind !f12 gs c cycle quickdrawMode2')
	
	send_command('bind ^- gs c cycle meleeWeapons')
	send_command('bind ^= gs c cycle rangedWeapon')
	
	send_command('bind numpad0 input /ra <t>')
	send_command('bind numpad. gs c QD 1')
	send_command('bind ^numpad. gs c QD 2')
end

function file_unload() -- unbind hotkeys
	send_command('unbind f9')
	send_command('unbind ^f9')
	send_command('unbind !f9')
	send_command('unbind @f9')
	
	send_command('unbind f10')
	send_command('unbind ^f10')
	
	send_command('unbind f11')
	send_command('unbind ^f11')
	send_command('unbind !f11')
	
	send_command('unbind f12')
	send_command('unbind ^f12')
	send_command('unbind !f12')
	
	send_command('unbind ^-')
	send_command('unbind ^=')
	
	send_command('unbind numpad0')
	send_command('unbind numpad.')
	send_command('unbind ^numpad.')
end

function setup()
	selfCommandMaps = {
		['set']		= handle_set,
		['toggle']	= handle_toggle,
		['cycle']	= handle_cycle,
		['cycleback']	= handle_cycleback,
		['update']	= update_gear,
		['cursna']	= handle_cursna,
		['cure']	= handle_cure,
		['save']	= save_weapons,
		['QD']		= handle_qd,
		
		['face']	= handle_face,
		-- ['flurry'] = function() 
		-- 	for k, v in pairs(player.buff_details) do
		-- 		for k2, v2 in pairs(v) do
		-- 			print(k2, v2)
		-- 		end
		-- 	end
		-- end
		}
	
	Rostam = {}
	Rostam.A = { name="Rostam", augments={'Path: A'}}
	Rostam.B = { name = "Rostam", augments={'Path: B'}}

	rangedWeapon = M{['description']='Ranged Weapon', 'Death Penalty', 'Armageddon', 'Fomalhaut', 'Anarchy +2'}
	meleeWeapons = M{['description']='Melee Weapons', 'Rostam-Naegling', 'Rostam-Blurred', 'Rostam-Shield', 'Naegling-Blurred', 'Fettering-Shield', 'Rostam-Fettering'}
	
	weapontable = {
		['Rostam-Naegling']={main=Rostam.A,sub='Naegling'},
		['Rostam-Blurred']={main=Rostam.B,sub='Blurred Knife +1'},
		['Rostam-Shield']={main=Rostam.A,sub='Nusku Shield'},
		['Naegling-Blurred']={main='Naegling',sub={name='Blurred Knife +1',priority=15}},
		['Fettering-Shield']={main='Fettering Blade',sub='Nusku Shield'},
		['Rostam-Fettering']={main=Rostam.A,sub='Fettering Blade'}
		}
	
	meleeAccuracy = M{['description']='Melee Accuracy', 'Normal', 'Mid', 'Acc'}
	rangedAccuracy = M{['description']='Ranged Accuracy', 'STP', 'Normal', 'Mid', 'Acc'}
	magicAccuracy = M{['description']='Magic Accuracy', 'Normal', 'Mid', 'Acc'}
	hotshotAccuracy = M{['description']='Hotshot Accuracy', 'Normal', 'Mid', 'Acc'}
	quickdrawElement1 = M{['description']='Primary Quickdraw Element', 'Fire', 'Earth', 'Water', 'Wind', 'Ice', 'Thunder', 'Light', 'Dark'}
	quickdrawElement2 = M{['description']='Secondary Quickdraw Element', 'Dark', 'Fire', 'Earth', 'Water', 'Wind', 'Ice', 'Thunder', 'Light'}
	quickdrawMode1 = M{['description']='Primary Quickdraw Mode', 'Damage', 'Store TP'}
	quickdrawMode2 = M{['description']='Secondary Quickdraw Mode', 'Damage', 'Store TP'}
	QDMode = 'Damage'
	DDMode = M{['description']='DD Mode', 'Normal', 'Hybrid', 'Emergancy DT'}
	emergancyDT = M(false,'Emegancy DT')
	roll_weapons = M(true,'Use ranged/weapon swaps for rolling')
	bullets = {['Normal']='Chrono Bullet', ['Mid']='Devastating Bullet', ['Acc']='Devastating Bullet'}
	
	DWMode = M{['description']='Dual Wield Mode', 'Auto', 'Manual'}
	DWLevel = M{['description']='Dual Wield Level', '11', '15', '16'}
		
	local dw_level = get_dw_level()
	DWLevel:set(tostring(dw_level))
	
	DW_Needed = 11
	DW = true
	haste_sets = {
		[0]	 = 'SW',
		[11] = 'DW11',
		[15] = 'DW15',
		[74] = 'DW16',}	
	flurry = 1
	
	TreasureMode = TH.TreasureMode
	
	autofacetarget = true
	rm_target = nil
	moving = true
end

function build_UI()
	local GUI_x = 1732
	local GUI_y = 70
	GUI.bound.y.lower = 70 -- override the default y bound for where GUI-lib will open boxes
	GUI.bound.y.upper = 451
	DT = IconButton{
		x = GUI_x + 0,
		y = GUI_y + 0,
		var = DDMode,
		icons = {
			{img = 'DD Normal.png', value = 'Normal'},
			{img = 'DD Hybrid.png', value = 'Hybrid'},
			{img = 'Emergancy DT.png', value = 'Emergancy DT'}
		},
		command = 'gs c update'
	}
	DT:draw()

	weap = IconButton{
		x = GUI_x + 0,
		y = GUI_y + 54,
		var = meleeWeapons,
		icons = {
			{img = 'COR/Rostam-Naegling.png', value = 'Rostam-Naegling'},
			{img = 'COR/Rostam-Blurred.png', value = 'Rostam-Blurred'},
			{img = 'COR/Rostam-Nusku.png', value = 'Rostam-Shield'},
			{img = 'COR/Kaja-Blurred.png', value = 'Naegling-Blurred'},
			{img = 'COR/Fettering-Nusku.png', value = 'Fettering-Shield'},
			{img = 'COR/Rostam-Fettering.png', value = 'Rostam-Fettering'}
		},
		command = 'gs c update'
	}
	weap:draw() -- initialize the weapon button
	
	range= IconButton{
		x = GUI_x + 0,
		y = GUI_y + 54 * 2,
		var = rangedWeapon,
		icons = {
			{img = 'COR/Death Penalty.png', value = 'Death Penalty'},
			{img = 'COR/Armageddon.png', value = 'Armageddon'},
			{img = 'COR/Fomalhaut.png', value = 'Fomalhaut'},
			{img = 'COR/Anarchy +2.png', value = 'Anarchy +2'}
		},
		command = 'gs c update'
	}
	range:draw()
	
	QD1 = IconButton{
		x = GUI_x + 0,
		y = GUI_y + 54 * 3,
		var = quickdrawElement1,
		icons = {
			{img = 'COR/Fire Shot.png', value = 'Fire'},
			{img = 'COR/Earth Shot.png', value = 'Earth'},
			{img = 'COR/Water Shot.png', value = 'Water'},
			{img = 'COR/Wind Shot.png', value = 'Wind'},
			{img = 'COR/Ice Shot.png', value = 'Ice'},
			{img = 'COR/Thunder Shot.png', value = 'Thunder'},
			{img = 'COR/Light Shot.png', value = 'Light'},
			{img = 'COR/Dark Shot.png', value = 'Dark'}
		},
		command = 'gs c update'
	}
	QD1:draw()
	QD2 = IconButton{
		x = GUI_x + 0,
		y = GUI_y + 54 * 4,
		var = quickdrawElement2,
		icons = {
			{img = 'COR/Fire Shot.png', value = 'Fire'},
			{img = 'COR/Earth Shot.png', value = 'Earth'},
			{img = 'COR/Water Shot.png', value = 'Water'},
			{img = 'COR/Wind Shot.png', value = 'Wind'},
			{img = 'COR/Ice Shot.png', value = 'Ice'},
			{img = 'COR/Thunder Shot.png', value = 'Thunder'},
			{img = 'COR/Light Shot.png', value = 'Light'},
			{img = 'COR/Dark Shot.png', value = 'Dark'}
		},
		command = 'gs c update'
	}
	QD2:draw()
	
	RG = ToggleButton{
		x = GUI_x + 54,
		y = GUI_y + 54 * 4,
		var = roll_weapons,
		iconUp = 'COR/RollGearOff.png',
		iconDown = 'COR/RollGearOn.png',
	}
	RG:draw()
	
	THButton = ToggleButton{
		x = GUI_x + 54 * 2,
		y = GUI_y + 54 * 4,
		var = TH.TreasureMode,
		iconUp = 'TH Off.png',
		iconDown = 'TH On.png'
	}
	THButton:draw()
	
	DIV = Divider{
		x = GUI_x,
		y = GUI_y + 54 * 5,
		size = 150
	}
	DIV:draw()
	
	RHGUI_y = GUI_y + 54 * 5 + 15
	
	RHToggle = ToggleButton{
		x = GUI_x + 54,
		y = RHGUI_y,
		var = 'enabled',
		iconUp = 'COR/RH Off.png',
		iconDown = 'COR/RH On.png',
	}
	RHToggle:draw()
	
	SOTPToggle = ToggleButton{
		x = GUI_x + 54 * 2,
		y = RHGUI_y,
		var = 'stop_on_tp',
		iconUp = 'COR/Stop on tp Off.png',
		iconDown = 'COR/Stop on tp On.png'
	}
	SOTPToggle:draw()
	
	WS_Shortcuts = M{['description']='Weaponskill Shortcut UI','Leaden Salute', 'Hot Shot', 'Wildfire', 'Last Stand', ''}
	RHShortcuts = IconButton{
		x = GUI_x + 0,
		y = RHGUI_y,
		var = WS_Shortcuts,
		icons = {
			{img = 'COR/Leaden Salute.png', value = 'Leaden Salute'},
			{img = 'COR/Hot Shot.png', value = 'Hot Shot'},
			{img = 'COR/Wildfire.png', value = 'Wildfire'},
			{img = 'COR/Last Stand.png', value = 'Last Stand'},
			{img = 'COR/NO.png', value = ''}
		},
		command = function() windower.send_command('gs rh set %s':format(WS_Shortcuts.value)) end
	}
	RHShortcuts:draw()
	
	AMToggle = ToggleButton{
		x = GUI_x + 54,
		y = RHGUI_y + 54,
		var = 'useAM',
		iconUp = 'COR/Aftermath Off.png',
		iconDown = 'COR/Aftermath On.png',
	}
	AMToggle:draw()
	
	RHClear = FunctionButton{
		x = GUI_x + 54 * 2,
		y = RHGUI_y + 54,
		icon = 'COR/RH Clear.png',
		command = function() windower.send_command('gs rh clear') end
	}
	RHClear:draw()
	
	RHTP = SliderButton{
		x = GUI_x + 0,
		y = RHGUI_y + 54,
		var = "ws_tp",
		min = 1000,
		max = 3000,
		increment = 100,
		height = 144,--122,
		icon="COR/TP.png",
	}
	RHTP:draw()
	
	RHWS = PassiveText({
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2,
		text = 'RH Weaponskill: %s',
		--var = 'weaponskill',
		align = 'right'},
		'weaponskill')
	RHWS:draw()
	
	Acc_display = TextCycle{
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2 + 20,
		var = meleeAccuracy,
		align = 'right',
		width = 112,
		command = 'gs c update'
	}
	Acc_display:draw()
	
	RAcc_display = TextCycle{
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2 + 20 + 32 * 1,
		var = rangedAccuracy,
		align = 'right',
		width = 112,
		command = 'gs c update'
	}
	RAcc_display:draw()
	
	MAcc_display = TextCycle{
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2 + 20 + 32 * 2,
		var = magicAccuracy,
		align = 'right',
		width = 112,
		command = 'gs c update'
	}
	MAcc_display:draw()
	
	HAcc_display = TextCycle{
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2 + 20 + 32 * 3,
		var = hotshotAccuracy,
		align = 'right',
		width = 112,
		command = 'gs c update'
	}
	HAcc_display:draw()
	
	HMDisplay = TextCycle{
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2 + 20 + 32 * 4,
		var = DWMode,
		align = 'right',
		width = 112,
		command = function() windower.send_command('gs c update') end,
	}
	HMDisplay:draw()
	DWDisplay = TextCycle{
		x = GUI_x + 164,
		y = RHGUI_y + 54 * 2 + 20 + 32 * 5,
		var = DWLevel,
		align = 'right',
		width = 112,
		command = function() DWMode:set('Manual'); windower.send_command('gs c update') end,
	}
	DWDisplay:draw()
end

function self_command(commandArgs)
	local commandArgs = commandArgs
	if type(commandArgs) == 'string' then
		commandArgs = T(commandArgs:split(' '))
		if #commandArgs == 0 then
			return
		end
	end
	
	-- Of the original command message passed in, remove the first word from
	-- the list (it will be used to determine which function to call), and
	-- send the remaining words as parameters for the function.
	local handleCmd = table.remove(commandArgs, 1)
	if selfCommandMaps[handleCmd] then
		selfCommandMaps[handleCmd](commandArgs)
	end
end

function handle_toggle(cmdParams)
	if #cmdParams == 0 then
		return
	end
	mode = _G[cmdParams[1]]
	mode:toggle()
	add_to_chat(123,'%s set to %s':format(mode.description, tostring(mode.value)))
	update_gear()
end

function handle_set(cmdParams)
	if #cmdParams == 0 then
		return
	end
	local m = table.remove(cmdParams, 1)
	mode = _G[m]
	
	local s = table.remove(cmdParams, 1)
	if #cmdParams ~= 0 then
		for i,word in ipairs(cmdParams) do
			s = s..' '..word
		end
	end
	
	mode:set(s)
	update_gear()
	add_to_chat(123,'%s set to %s':format(mode.description, tostring(mode.value)))
end

function handle_cycle(cmdParams)
	if #cmdParams == 0 then
		add_to_chat(123,'Cycle failure: field not specified.')
		return
	end
	mode = _G[cmdParams[1]]
	mode:cycle()
	add_to_chat(123,'%s set to %s':format(mode.description,mode.value))
	update_gear()
end

function handle_cycleback(cmdParams)
	if #cmdParams == 0 then
		add_to_chat(123,'Cycle failure: field not specified.')
		return
	end
	mode = _G[cmdParams[1]]
	mode:cycleback()
	add_to_chat(123,'%s set to %s':format(mode.description,mode.value))
	update_gear()
end

function get_idle_set()
	if buffactive['Shell'] then
		return sets.idle.ShellV
	else
		return sets.idle
	end
end

function get_engaged_set()	
	local acc = meleeAccuracy.value
	local haste = 'DW'..DWLevel.value --get_haste_set()
	
	if sets.engaged[haste][acc] then
		s = sets.engaged[haste][acc]
	else
		s = sets.engaged[haste]
	end
	if DDMode.value == 'Hybrid' then
		s = set_combine(s, sets.engaged.Hybrid)
	end
	if TH.Result then
		s = set_combine(s, sets.TreasureHunter)
	end
	
	return s
end

function get_haste_set()
	local k = 100
	for i,set in pairs(haste_sets) do -- assumes it iterates in order
		if DW_Needed <= i then
			if i < k then
				k = i
			end
		end
	end
	return haste_sets[k]
end

function get_WS_acc(ws)
	return _G[weaponskills[ws] or 'meleeAccuracy'].value
end

function get_WS_type(ws)
	local t = weaponskills[ws]
	if t == 'rangedAccuracy' then
		return 'Ranged'
	elseif t == 'magicAccuracy' then
		return 'Magic'
	else
		return 'Physical'
	end
end

function handle_cure()
	equip(sets.CureReceived)
end

function handle_cursna()
	equip(sets.Cursna)
end

function handle_qd(cmdParams)
	local element = _G['quickdrawElement%i':format(cmdParams[1])].value
	QDMode = _G['quickdrawMode%i':format(cmdParams[1])].value	-- set global QD mode for the precast function
	send_command('input /ja "'..element..' shot" <t>')
end

function handle_face(target)
	rm_target = tonumber(target)
end

function update_gear()
	if player.status == 'Engaged' and DDMode.value ~=  'Emergancy DT' then
		equip(get_engaged_set())
		--[[if DDMode.value == 'Hybrid' then
			equip(sets.engaged.Hybrid)
		end]]
	else -- if we are idle
		equip(get_idle_set())
	end
	if buffactive.Sleep or buffactive.Lullaby then
		equip(get_idle_set())
	end
	--print(rangedWeapon.value, meleeWeapons.value)
	
	equip({range=rangedWeapon.value})
	equip(weapontable[meleeWeapons.value])
end

function get_eTP()
	local etp = player.tp + 250
	if player.equipment.range == 'Fomalhaut' then
		local etp = etp + 500
	elseif player.equipment.range == 'Anarchy +2' then
		local etp = etp + 1000
	end
	return etp
end

function buff_change(buff,gain)
	if buff == 'Sleep' or buff == 'Lullaby' then update_gear() end
	if buff == 'Flurry' and not gain then
		flurry = 0
	end
	if buff == 'Haste' and not gain then
		Haste_Level = 0
	end
	local dw_level = get_dw_level()
	if dw_level ~= DWLevel.value and DWMode.value == 'Auto' then
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

function precast(spell,action)
	--if RA_precast(spell,action) then return end -- intercept and queue actions if autoRA is on
	
	-- rng helper integration --
	eventArgs = {} 
	filter_precast(spell, {}, eventArgs)
	if eventArgs.cancel then return end -- might need to cancel_spell here
	-- end rng helper integration --
	
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
	elseif spell.action_type == 'Ranged Attack' then
		if spell.target.distance > 24.9 then
			cancel_spell()
			return
		end
		local acc = rangedAccuracy.value
		
		local gun = rangedWeapon.value
		local midSet = sets.midcast.RA
		
		-- Determine midcast ammo, and equip it during precast
		if midSet[gun] then
			midSet = midSet[gun]
		end
		if midSet.AM3 and buffactive['Aftermath: Lv.3'] then
			midSet = midSet.AM3
		end
		if midSet[acc] then
			midSet = midSet[acc]
		end
		
		local bullet = {
			ammo=midSet.ammo--bullets[acc]
		}
		
		if buffactive[265] or buffactive[581] then
			if flurry == 1 then
				equip(set_combine(sets.precast.RA.Flurry1, bullet))
			else
				equip(set_combine(sets.precast.RA.Flurry2, bullet))
			end
		else
			equip(set_combine(sets.precast.RA, bullet))
		end
		local t = ft_target()
		if t and bit.band(t.id,0xFF000000) ~= 0 then -- highest byte of target.id indicates whether it's a play or not
			facetarget()
		end
	elseif spell.type == 'WeaponSkill' then
		if spell.skill == 'Marksmanship' then
			if spell.target.distance > 21 then
				cancel_spell()
				return
			end
		elseif spell.target.distance > 5.9 then
			cancel_spell()
			return
		end
		if sets.WS[spell.name] then
			if sets.WS[spell.name][get_WS_acc(spell.name)] then
				set = sets.WS[spell.name][get_WS_acc(spell.name)] -- sets.WS.WSName.Acc
			else
				set = sets.WS[spell.name]	-- sets.WS.WSName
			end
		else
			set = sets.WS[get_WS_type(spell.name)][get_WS_acc(spell.name)] -- sets.WS.Physical.Acc	
		end
		if get_eTP() > 2900 then
			if set.maxTP then
				set = set.maxTP
			end
		end
		equip(set)
		if get_WS_type(spell.name) == 'Magic' and (	world.weather_element == spell.element or
													world.day_element == spell.element ) then
			equip(sets.Obi)
		end
		facetarget()
	elseif spell.name:contains('Waltz') then
		equip(sets.precast.Waltz)
	elseif spell.name:contains('Step') then
		equip(sets.precast.Step)
	elseif spell.type == 'CorsairRoll' and spell.name:contains('Roll') then
		s = sets.JA['Phantom Roll']
		if not roll_weapons.value then
			s = set_combine(s, {main='', sub='', range=''})
		end
		equip(s)
	elseif spell.type == 'CorsairShot' then
		if QDMode == 'Damage' then
			if spell.name:contains('Light') or spell.name:contains('Dark') then
				equip(sets.JA.Quickdraw.Accuracy)
			else
				equip(sets.JA.Quickdraw.Damage)
			end
		else -- STP
			if spell.name:contains('Light') or spell.name:contains('Dark') then
				equip(sets.JA.Quickdraw.Accuracy)
			else
				equip(sets.JA.Quickdraw['Store TP'])
			end
		end
		facetarget()
		
	elseif spell.type == 'JobAbility' then	
		if sets.JA[spell.name] then
			equip(sets.JA[spell.name])
		elseif spell.english == 'Fold' and buffactive['Bust'] == 2 then
			equip(sets.JA.FoldDoubleBust)
		end
		if world.weather_element == spell.element or world.day_element == spell.element then
			equip(sets.Obi)
		end
	elseif spell.name:contains('Soultrapper') then
		equip({ammo="Blank Soulplate"})
	elseif spell.type == 'Item' then
		if sets.item[spell.name] then
			equip(sets.item[spell.name])
		end
	end
end

function midcast(spell,action)
	if spell.name == 'Sneak' or spell.name == 'Spectral Jig' or spell.name:startswith('Monomi') and spell.target.type == 'SELF' then --click off buffs if needed
		send_command('cancel 71')
	end
	if spell.action_type == 'Magic' then
		if sets.midcast[spell.name] then 
			equip(sets.midcast[spell.name])
		elseif sets.midcast[spell.skill] then
			equip(sets.midcast[spell.skill])
		else
			equip(sets.midcast)
		end
	elseif spell.action_type == 'Ranged Attack' then
		local acc = rangedAccuracy.value
		local gun = rangedWeapon.value
		local equipSet = sets.midcast.RA
		
		if equipSet[gun] then
			equipSet = equipSet[gun]
		end
		if equipSet.AM3 and buffactive['Aftermath: Lv.3'] then
			equipSet = equipSet.AM3
		end
		if equipSet[acc] then
			equipSet = equipSet[acc]
		end
		
		if buffactive['Triple Shot'] then
			equipSet = set_combine(equipSet, sets.TripleShot)
		end
		
		if TH.Result then
			equipSet = set_combine(equipSet, sets.TreasureHunter)
		end
		
		equip(equipSet)
	end
end

function aftercast(spell,action)
	rm_target = nil
	update_gear()
end

function status_change(new,action)
	update_gear()
end

function facetarget()
	if not autofacetarget then return end
	local t = ft_target()
	local destX = t.x
	local destY = t.y
	local direction = math.abs(PlayerH - math.deg(HeadingTo(destX,destY)))
	if direction > 5 then
		windower.ffxi.turn(HeadingTo(destX,destY))
	end
end

function ft_target()
	local rh = rh_status()
	if rh.enabled and rh.target then
		return windower.ffxi.get_mob_by_id(rh.target)
	elseif rm_target then
		return windower.ffxi.get_mob_by_id(rm_target)
	else
		return windower.ffxi.get_mob_by_target('t')
	end
end

function HeadingTo(X,Y)
	local mob = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
  local H = math.atan2(X - mob.x, Y - mob.y)	
  return H - 1.5708
end

windower.raw_register_event('outgoing chunk', function(id, data)
    if id == 0x015 then
      local action_message = packets.parse('outgoing', data)
			PlayerH = action_message.Rotation
		end
end)

windower.raw_register_event('prerender', 
	function()
		local t = ft_target()
		if t and bit.band(t.id,0xFF000000) ~= 0 then -- highest byte of target.id indicates whether it's a player or not
			facetarget()
		end
	end)

windower.raw_register_event('action',
    function(act)
        --check if you are a target of spell
        local actionTargets = act.targets
        playerId = windower.ffxi.get_player().id
        isTarget = false
        for _, target in ipairs(actionTargets) do
            if playerId == target.id then
                isTarget = true
            end
        end
        if isTarget == true then
            if act.category == 4 then
                local param = act.param
                if param == 845 and flurry ~= 2 then
                    --add_to_chat(122, 'Flurry Status: Flurry I')
                    flurry = 1
                elseif param == 846 then
                    --add_to_chat(122, 'Flurry Status: Flurry II')
                    flurry = 2
                end
            end
        end
    end)	