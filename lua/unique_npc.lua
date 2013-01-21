-- unique NPC's whom one can interact with
-- identified by their name, which will be used
-- as their ID

-- table mapping names to unique unit descriptions
unique_npcs = { }

-- create a unique NPC
-- returns the name of the new NPC, or nil if name
-- was given and an NPC with that name already existed
function create_unique_NPC(type, name, faction, location)
	if not name then
		while unique_npcs[name] do
			local unit = wesnoth.create_unit { type = type, side = 2, placement = "recall" }
			name = unit.name
			-- don't need the unit handle for now anymore, put it away
			wesnoth.extract_unit(unit)
		end
	else
		if unique_npcs[name] then
			return nil
		end
	end
	
	unique_npcs[name] = {
		name = name,
		type = type,
		faction = faction,
		-- lists of quests the NPC can give
		quests = { },
		location = location
	}
	
	return name
end

-- unstores a unique NPC of the given name and returns the unit handle
-- unit will be placed on recall list of given side
function get_unique_NPC(name, side)
	if side == nil then side = 2 end
	return wesnoth.create_unit { type = type, side = side, placement = "recall" }
end

-- get the portrait image of a unique NPC
function get_unit_portrait(name)
	local unit = get_unique_NPC(name)
	wesnoth.extract_unit(unit)
	
	local unit_type = wesnoth.unit_types[unit.type]
	return unit_type.__cfg.portrait.image
end

-- add a new quest to a unique NPC
-- the NPC will then be able to give this quest in dialog with the player
function add_quest_to_npc(name, quest)
	table.insert(unique_npcs[name].quests, quest)
end