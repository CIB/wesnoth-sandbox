-- unique NPC's whom one can interact with
-- identified by their name, which will be used
-- as their ID

wesnoth.dofile "~add-ons/Sandbox/lua/personality.lua"

-- table mapping names to unique unit descriptions
unique_npcs = { }

-- create a unique NPC
-- returns the id of the new NPC
function create_unique_NPC(type, name, faction, location, personality, recruitable, canrecruit)
	local stored_unit_id, stored_unit = helper.create_stored_unit { name = name, type = type, random_traits = true, canrecruit = canrecruit }
	
	if not name then
		name = stored_unit.name
	end
	
	unique_npcs[stored_unit_id] = {
		type = type,
		faction = faction,
		-- each unique NPC can hold up to one quest
		quest = nil,
		location = location,
		personality = personality,
		id = stored_unit_id,
		recruitable = recruitable
	}
	
	return stored_unit_id, stored_unit
end

-- unstores a unique NPC of the given name and returns the unit handle
-- unit will be placed on recall list of given side
function get_unique_NPC(id)
	local rval = wesnoth.get_recall_units({ id = id })[1]
	if not rval then
		return wesnoth.get_units({ id = id })[1]
	end
end

-- get the portrait image of a unique NPC
function get_unit_portrait(id)
	local unit = get_unique_NPC(id)
	
	return helper.get_portrait(unit)
end

-- get the name of an NPC, complete with role and all
function get_npc_name(id)
	local unit_handle = get_unique_NPC(id)
	return unit_handle.name
end

-- add a new quest to a unique NPC
-- the NPC will then be able to give this quest in dialog with the player
function add_quest_to_npc(name, quest)
	unique_npcs[name].quest = quest
	quest.giver = name
end

-- talk to an NPC
function npc_talk(npc)
	local npc_name = get_npc_name(npc.id)
	local npc_portrait = get_unit_portrait(npc.id)
	
	if npc.custom_talk then
		_G[npc.custom_talk](npc, npc_name, npc_portrait)
	end
	
	-- maybe we can recruit this guy?
	if npc.recruitable then
		local more_units = get_maximum_recruits(player) - #wesnoth.get_recall_units({side = 1})
		
		local recruited = get_unique_NPC(npc.id)
		S.name = tostring(npc_name)
		S.type = tostring(wesnoth.unit_types[recruited.type].name)
		S.gold = wesnoth.unit_types[recruited.type].cost
		local reply = helper.dialog(_ "Hire {name}, the {type} for {gold} gold?", npc_name, npc_portrait, {"Yes", "No"})
		if reply == 1 then
			local cost = wesnoth.unit_types[recruited.type].cost
			
			if cost > helper.get_gold(1) then
				helper.get_user_choice({ speaker = "narrator", message = "You can't afford that." }, { })
			elseif more_units <= 0 then
				helper.dialog("You can't recruit any more units!")
			else
				recruited.side = 1
				wesnoth.put_recall_unit(recruited, 1)
				local army = savegame.armies[recruited.variables.army]
				army_remove_unit(army, recruited.id)
			end
		end
		
		return
	end

	if npc.quest and not npc.quest.taken then		
		-- offer new quest
		local choices = { _ "I'll do it", _ "No" }
		local choice_values = { true, false }
		local tags = { speaker = "narrator", 
			caption = npc_name, 
			image = npc_portrait, 
			message = get_message(npc.personality, npc.quest.mission_text) 
		}
		local user_choice = choice_values[helper.get_user_choice(tags, choices)]
		if user_choice == true then
			helper.dialog("Thank you. Your help will be appreciated.", npc_name, npc_portrait)
			add_quest(npc.quest)
		else
			helper.dialog("Oh, that's too bad..", npc_name, npc_portrait)
		end
	elseif npc.quest and npc.quest.taken and npc.quest.completed then
		-- player has taken quest from NPC
		local msg = get_message(npc.personality, npc.quest.completion_text) .. " " .. get_message(npc.personality, sayings.normal_quest_reward)
		helper.dialog(msg, npc_name, npc_portrait)
		player_adjust_resources(player, { Gold = helper.random(20, 50), Crops = helper.random(10, 30)} )
		remove_quest(npc.quest)
		npc.quest = nil
	else
		-- smalltalk
		local msg = get_message(npc.personality, sayings.smalltalk)
		helper.dialog(msg, npc_name, npc_portrait)
	end
end
