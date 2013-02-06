-- unique NPC's whom one can interact with
-- identified by their name, which will be used
-- as their ID

wesnoth.dofile "~add-ons/Sandbox/lua/personality.lua"

-- table mapping names to unique unit descriptions
unique_npcs = { }

-- create a unique NPC
-- returns the name of the new NPC, or nil if name
-- was given and an NPC with that name already existed
function create_unique_NPC(type, name, faction, location, personality)
	if not name then
		while true do
			local unit = wesnoth.create_unit { type = type, side = 2, placement = "recall" }
			name = unit.name
			-- don't need the unit handle for now anymore, put it away
			wesnoth.extract_unit(unit)
			
			if not unique_npcs[name] then break end
		end
	else
		if unique_npcs[name] then
			return nil
		end
	end
	
	name = tostring(name)
	
	unique_npcs[name] = {
		name = name,
		type = type,
		faction = faction,
		-- each unique NPC can hold up to one quest
		quest = nil,
		location = location,
		personality = personality
	}
	
	return name
end

-- unstores a unique NPC of the given name and returns the unit handle
-- unit will be placed on recall list of given side
function get_unique_NPC(name, side)
	if side == nil then side = 2 end
	local npc = unique_npcs[name]
	return wesnoth.create_unit { type = npc.type, side = side, placement = "recall" }
end

-- get the portrait image of a unique NPC
function get_unit_portrait(name)
	local unit = get_unique_NPC(name)
	wesnoth.extract_unit(unit)
	
	local unit_type = wesnoth.unit_types[unit.type]
	if unit_type.__cfg.portrait then
		return unit_type.__cfg.portrait.image
	else
		return unit_type.__cfg.image
	end
end

-- get the name of an NPC, complete with role and all
function get_npc_name(name)
	local npc = unique_npcs[name]
	return npc.name
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
		helper.dialog(msg, get_npc_name(npc.name), get_unit_portrait(npc.name))
	else
		local msg = get_message(npc.personality, sayings.smalltalk)
		helper.dialog(msg, get_npc_name(npc.name), get_unit_portrait(npc.name))
	end
end