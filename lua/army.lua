-- an army is a group of units moving on the overmap

function create_army(name, leader)
	savegame.armies = savegame.armies or {}
	if not savegame.army_ID then
		savegame.army_ID = 0
	end
	
	savegame.army_ID = savegame.army_ID + 1

	local rval = {
		id = "army_" .. tostring(savegame.army_ID), -- unique ID for the army
		name = name, -- display name for the army
		leader = leader, -- leader must be a unique NPC name
		overmap_unit_id = nil,
		units = {}, -- list of units serialized with store_unit
		position = nil
	}
	local npc = unique_npcs[rval.leader]
	rval.overmap_unit_id = helper.create_stored_unit { id = rval.id, name = name, type = npc.type }
	savegame.armies[savegame.army_ID] = rval
	return rval	
end

function army_place_on_map(army, x, y)
	army.position = {x = x, y = y}
	helper.unstore_unit(army.overmap_unit_id, x, y, 2)
end
