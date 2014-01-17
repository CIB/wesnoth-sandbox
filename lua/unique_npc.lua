-- unique NPC's whom one can interact with
-- identified by their name, which will be used
-- as their ID

wesnoth.dofile "~add-ons/Sandbox/lua/personality.lua"

-- table mapping names to unique unit descriptions
unique_npcs = { }

-- create a unique NPC
-- returns the id of the new NPC
function create_unique_NPC(type, name, faction, location, personality, side)
	side = side or 2
	
	local stored_unit_id, stored_unit = helper.create_stored_unit { name = name, type = type, random_traits = true }
	
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
		id = stored_unit_id
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
	
	local unit_type = wesnoth.unit_types[unit.type]
	if unit_type.__cfg.portrait then
		return unit_type.__cfg.portrait.image
	else
		return unit_type.__cfg.image
	end
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
	if npc.quest and not npc.quest.taken then		
		-- offer new quest
		local choices = { _ "I'll do it", _ "No" }
		local choice_values = { true, false }
		local tags = { speaker = "narrator", 
			caption = get_npc_name(npc.name), 
			image = get_unit_portrait(npc.name), 
			message = get_message(npc.personality, npc.quest.mission_text) 
		}
		local user_choice = choice_values[helper.get_user_choice(tags, choices)]
		if user_choice == true then
			helper.dialog("Thank you. Your help will be appreciated.", get_npc_name(npc.name), get_unit_portrait(npc.name))
			add_quest(npc.quest)
		else
			helper.dialog("Oh, that's too bad..", get_npc_name(npc.name), get_unit_portrait(npc.name))
		end
	elseif npc.quest and npc.quest.taken and npc.quest.completed then
		-- player has taken quest from NPC
		local msg = get_message(npc.personality, npc.quest.completion_text) .. " " .. get_message(npc.personality, sayings.normal_quest_reward)
		helper.dialog(msg, get_npc_name(npc.id), get_unit_portrait(npc.id))
		player_adjust_resources(player, { Gold = helper.random(20, 50), Crops = helper.random(10, 30)} )
		remove_quest(npc.quest)
		npc.quest = nil
	else
		-- smalltalk
		local msg = get_message(npc.personality, sayings.smalltalk)
		helper.dialog(msg, get_npc_name(npc.id), get_unit_portrait(npc.id))
	end
end
