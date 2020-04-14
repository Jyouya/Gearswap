-- TH library.  Uses a bunch of code from Motes-TreasureHunter
-- Rather than locking gear, it provides a boolean we can read
-- to determine if we should put on TH gear in our engaged/midshot set

TH = {}

TH.tagged_mobs = T{}
TH.last_player_target_index = 0

TH.TreasureMode = M(true, 'TreasureHunter Mode')

TH.Result = false -- read this to know if you should apply TH


function TH.on_target_change(new_index, old_index)
    -- Only care about changing targets while we're engaged, either manually or via current target death.
    --if player.status == 'Engaged' then
        -- If  the current player.target is the same as the new mob then we're actually
        -- engaged with it.
        -- If it's different than the last known mob, then we've actually changed targets.
        if player.target.index == new_index and new_index ~= TH.last_player_target_index then
            --if _settings.debug_mode then add_to_chat(123,'Changing target to '..player.target.id..'.') end
			--print('Changing target to '..player.target.id..'.')
            TH.last_player_target_index = player.target.index
            TH.for_first_hit()
        end
    --end
end


-- On any action event, mark mobs that we tag with TH.  Also, update the last time tagged mobs were acted on.
function TH.on_action(action)
    --add_to_chat(123,'cat='..action.category..',param='..action.param)
    -- If player takes action, adjust TH tagging information
    if TH.TreasureMode.value then
        if action.actor_id == player.id then
            -- category == 1=melee, 2=ranged, 3=weaponskill, 4=spell, 6=job ability, 14=unblinkable JA
            if TH.TreasureMode.value then
                for index,target in pairs(action.targets) do
                    TH.tagged_mobs[target.id] = os.time()
                end
				if TH.Result == true then
					
					TH.Result = false
					if action.category == 1 then
						windower.send_command('gs c update')
					end
				end
            end
        elseif TH.tagged_mobs[action.actor_id] then
            -- If mob acts, keep an update of last action time for TH bookkeeping
            TH.tagged_mobs[action.actor_id] = os.time()
        else
            -- If anyone else acts, check if any of the targets are our tagged mobs
            for index,target in pairs(action.targets) do
                if TH.tagged_mobs[target.id] then
                    TH.tagged_mobs[target.id] = os.time()
                end
            end
        end
    end
    TH.cleanup_tagged_mobs()
end


-- Need to use this event handler to listen for deaths in case Battlemod is loaded,
-- because Battlemod blocks the 'action message' event.
--
-- This function removes mobs from our tracking table when they die.
function TH.on_incoming_chunk(id, data, modified, injected, blocked)
    if id == 0x29 then
        local target_id = data:unpack('I',0x09)
        local message_id = data:unpack('H',0x19)%32768

        -- Remove mobs that die from our tagged mobs list.
        if TH.tagged_mobs[target_id] then
            -- 6 == actor defeats target
            -- 20 == target falls to the ground
            if message_id == 6 or message_id == 20 then
                TH.tagged_mobs[target_id] = nil
            end
        end
    end
end


-- Clear out the entire tagged mobs table when zoning.
function TH.on_zone_change(new_zone, old_zone)
    TH.tagged_mobs:clear()
end

-- On engaging a mob, attempt to add TH gear.  For any other status change, unlock TH gear slots.
function TH.on_status_change(new_status_id, old_status_id)
    if T{2,3,4}:contains(old_status_id) or T{2,3,4}:contains(new_status_id) then return end
    
    local new_status = gearswap.res.statuses[new_status_id].english
    local old_status = gearswap.res.statuses[old_status_id].english

    if new_status == 'Engaged' then
        TH.last_player_target_index = player.target.index
        TH.for_first_hit()
    elseif old_status == 'Engaged' then
        TH.last_player_target_index = 0
        TH.Result = false
    end
end

--[[function TH.for_first_hit()
    if player.status == 'Engaged' and TH.TreasureMode.value ~= 'Off' then
        if not TH.tagged_mobs[player.target.id] then   
            TH.Result = true
			windower.send_command('gs c update')
        else
            TH.Result = false
        end
    else
        TH.Result = false
    end
end]]

function TH.for_first_hit()
    if TH.TreasureMode.value then
        if not TH.tagged_mobs[player.target.id] then   
            TH.Result = true
			if player.status == 'Engaged' then
				windower.send_command('gs c update')
			end
        else
            TH.Result = false
        end
    else
        TH.Result = false
    end
end


-- Remove mobs that we've marked as tagged with TH if we haven't seen any activity from or on them
-- for over 3 minutes.  This is to handle deagros, player deaths, or other random stuff where the
-- mob is lost, but doesn't die.
function TH.cleanup_tagged_mobs()
    -- If it's been more than 3 minutes since an action on or by a tagged mob,
    -- remove them from the tagged mobs list.
    local current_time = os.time()
    local remove_mobs = S{}
    -- Search list and flag old entries.
    for target_id,action_time in pairs(TH.tagged_mobs) do
        local time_since_last_action = current_time - action_time
        if time_since_last_action > 180 then
            remove_mobs:add(target_id)
        end
    end
    -- Clean out mobs flagged for removal.
    for mob_id,_ in pairs(remove_mobs) do
        TH.tagged_mobs[mob_id] = nil
    end
end

windower.register_event('status change', TH.on_status_change)
windower.register_event('target change', TH.on_target_change)
windower.raw_register_event('action', TH.on_action)
windower.raw_register_event('incoming chunk', TH.on_incoming_chunk)
windower.raw_register_event('zone change', TH.on_zone_change)

return TH