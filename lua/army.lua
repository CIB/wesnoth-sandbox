-- an army is a group of units moving on the overmap

function create_army(name, leader, behavior)
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
		position = nil,
		behavior = behavior,
		resources = { Gold = math.random(10, 100), Crops = math.random(50, 200) }
	}
	if leader then
		local npc = unique_npcs[rval.leader]
		rval.overmap_unit_id = helper.create_stored_unit { id = rval.id, name = name, type = npc.type }
	end
	savegame.armies["army_" .. savegame.army_ID] = rval
	return rval	
end

function kill_army(id)
	cleanup_army(id)
	savegame.armies[id] = nil
end

-- remove all invalid units from the army
function cleanup_army(id)
	local army = savegame.armies[id]
	
	if not army then return end
	
	for i=#army.units,1,-1 do
		local unit = wesnoth.get_recall_units { id = army.units[i] }[1]
		
		if not unit then
			table.remove(army.units, i)
		end
	end
end

function army_place_on_map(army, x, y)
	army.position = {x = x, y = y}
	return helper.unstore_unit(army.overmap_unit_id, x, y, 2)
end

function army_move_toward(army, army_unit, x, y, turns)
	local path = wesnoth.find_path(army_unit, x, y)
	army_unit.moves = turns
	
	local furthest = nil
	for i, tile in ipairs(path) do
		local check_path = wesnoth.find_path(army_unit, tile[1], tile[2], {max_cost=turns+1})
		if #check_path > 0 then furthest = check_path end
	end
	
	if not furthest then return false end
	local destination = furthest[#furthest]
	if not destination or destination[1] == army_unit.x and destination[2] == army_unit.y then return false end
	
	helper.move_unit_fake_no_scroll({id = army_unit.id}, destination[1], destination[2])
	army.position = { x = destination[1], y = destination[2] }
	return true
end

function army_remove_unit(army, id)
	for i, unit in ipairs(army.units) do
		if unit == id then
			table.remove(army.units, i)
		end
	end
end

-- get the unit representing the army on the overmap, if any
function get_army_unit(army)
	return wesnoth.get_units({id = army.id})[1]
end

army_behaviors = {}

function army_behaviors.bandits(army, turns)
	-- bandits "patrol" around their hideout
	if not army.destination or (army.position.x == army.destination.x and army.position.y == army.destination.y) then
		local base = army.base
		local offset_x, offset_y = math.random(-10, 10), math.random(-10, 10)
		army.destination = { x = base.x + offset_x, y = base.y + offset_y }
	end
	
	if not army_move_toward(army, get_army_unit(army), army.destination.x, army.destination.y, turns) then
		army.destination = nil -- recalculate destination if movement failed
	end
end

function army_behaviors.trader(army, turns)
	-- move between the regular towns to visit
	if not army.destination then
		army.destination = army.destinations[1]
	end
	
	if army.position.x == army.destination.x and army.position.y == army.destination.y then
		local next_i
		for i, dest in ipairs(army.destinations) do
			if dest.x == army.position.x and dest.y == army.position.y then
				next_i = i + 1
				break
			end
		end
		
		if next_i > #army.destinations then
			next_i = 1
		end
		
		army.destination = army.destinations[next_i]
	end
	
	army_move_toward(army, get_army_unit(army), army.destination.x, army.destination.y, turns)
	
	-- do trading
	for _, town in ipairs(savegame.towns) do
		if town.x == army.position.x and town.y == army.position.y then
			npc_trade(army, town)
		end
	end
end


function populate_army(army, recruits, amount, npc_generator)
	-- Create units from given types
	local enemy_leader = wesnoth.get_units({side = 2, canrecruit = "yes"})[1]
	for i = 1,amount do
		local recruit_type = recruits[helper.random(1, #recruits)]
		local unit_id, unit
		if npc_generator then
			unit_id, unit = npc_generator(recruit_type)
		else
			unit_id, unit = helper.create_stored_unit { type = recruit_type, side = 2, random_traits = yes }
		end
		table.insert(army.units, unit_id)
		unit.variables.army = army.id
	end
end

function army_attack()
	local army_at_location
	for i, army in pairs(savegame.armies) do
		if army.position and army.position.x == V.x1 and army.position.y == V.y1 then
			army_at_location = army
		end
	end
	
	start_battle(army_at_location.id, "default", get_battle_map(V.x1, V.y1))
end

function army_all_units(army)
	local rval = {}
	
	if army.leader then
		table.insert(rval, army.leader)
	end
	
	for _, id in ipairs(army.units) do
		table.insert(rval, id)
	end
	
	return rval
end

function army_scout()
	-- TODO: make the success of this depend on several factors, such as unit sent to scout, distance, size of target party, etc.
	--       possibly kill the unit sent to scout

	local army_at_location
	for i, army in pairs(savegame.armies) do
		if army.position and army.position.x == V.x1 and army.position.y == V.y1 then
			army_at_location = army
		end
	end
	
	local unit_amounts = {}
	for _, unit_id in ipairs(army_all_units(army_at_location)) do
		local unit = wesnoth.get_recall_units { id = unit_id }[1]
		
		if unit then
			unit_amounts[unit.type] = (unit_amounts[unit.type] or 0) + 1
		end
	end
	
	-- TODO: draw little pictures of the unit types
	local options = {}
	for type, amount in pairs(unit_amounts) do
		table.insert(options, tostring(amount).."x\t"..tostring(type))
	end
	
	helper.get_user_choice({ speaker = "narrator", message = "Party composition:" }, options)
end

function add_army_attack_button()
	helper.menu_item("army_attack_button", _ "Attack", nil, "army_attack", {{"have_unit", { x = "$x1", y = "$y1", side = 2, {"filter_adjacent", { side = 1}}}}})
end


function add_army_scout_button()
	helper.menu_item("army_scout_button", _ "Scout", nil, "army_scout", {{"have_unit", { x = "$x1", y = "$y1", side = 2}}})
end
