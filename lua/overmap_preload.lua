wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/unique_npc.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/quest.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/faction.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/location.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/town.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/battle_handlers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/terrain.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/army.lua"


-- updates all the overmap labels
function update_labels()
	--TODO: figure out a way to clear existing labels
	
	-- draw locations, low priority
	for key, location in ipairs(locations) do
		if on_draw[location.location_type] then
			on_draw[location.location_type](location)
		end
	end
	
	-- draw all quest labels(high priority)
	for key, quest in ipairs(quests) do
		if not quest.completed then
			quest_handle_map(quest)
		end
	end
end

-- calculates how much a resource is worth in a given town
function get_resource_value(town, resource)
	return 1
end

-- start a battle with bandits, moving on to the next map
function start_bandit_battle(x, y)
	battle_data = {}
	battle_data.battle_handler = "bandits"
	battle_data.number_enemies = #wesnoth.get_recall_units({side = 1}) + helper.random(-2, 1)
	if battle_data.number_enemies < 1 then battle_data.number_enemies = 1 end
	save_overworld()
	
	helper.dialog("You're attacked by a brigade of bandits!")
	helper.quitlevel(get_battle_map(x, y))
end

function start_elf_battle(x, y)
	battle_data = {}
	battle_data.battle_handler = "elves"
	battle_data.number_enemies = #wesnoth.get_recall_units({side = 1}) + helper.random(-2, 0)
	if battle_data.number_enemies < 1 then battle_data.number_enemies = 1 end
	save_overworld()
	
	helper.dialog("You're attacked by a wandering group of elves.")
	helper.quitlevel(get_battle_map(x, y))
end

-- start a battle with a town
function start_town_battle(town)
	battle_data = {}
	battle_data.town = town.name
	
	helper.dialog("As you attempt to loot the town, the guards challenge you!")
	start_battle(town.army, "town", "town")
end

function start_battle(army, battle_handler, next_map)
	battle_data = battle_data or {}
	battle_data.battle_handler = battle_handler
	battle_data.army = army
	
	save_overworld()
	
	helper.quitlevel(next_map)
end

-- generic movement handler
function player_moved(x1, y1)
	--[[local max_moves = wesnoth.get_variable("unit.max_moves")
	local tiles_moved = max_moves - wesnoth.get_variable("unit.moves")
	local movement_percentage = tiles_moved / max_moves
	
	
	-- full movement is how far you can get in one full day(24 hours)
	]]
	

	for key, quest in ipairs(quests) do
		-- If a battle started or the like, do not process anything else
		if quest_handle_move(quest, V.x1, V.y1, movement_percentage) then
			return
		end
	end
	
	-- check if we moved onto a location
	local location = get_location(x1, y1)
	if location and on_move[location.location_type] then
		if on_move[location.location_type](location) then
			return
		end
	end
	
	local leader = wesnoth.get_units({side = 1, canrecruit = true})[1]
	
	if leader.moves == 0 then
		new_turn()
		leader.moves = leader.max_moves
	end
	
    --wesnoth.set_variable("unit.moves", wesnoth.get_variable("unit.max_moves"))
	--W.unstore_unit({variable = "unit"})
	
	update_labels()
	
	-- save periodically
	save_overworld()
end

-- save gamedata
function save_overworld()
	local leader = helper.get_leader(1)
	savegame.player = player
	savegame.player.x = leader.x
	savegame.player.y = leader.y
	savegame.player.gold = helper.get_gold(1)
	savegame.towns = towns
	savegame.battle_data = battle_data
	savegame.quests = quests
	savegame.unique_npcs = unique_npcs
	savegame.locations = locations
	V.savegame = pickle(savegame)
end

-- load gamedata
function load_overworld()
	-- if there's no savegame yet, abort
	if type(V.savegame) ~= "string" or V.savegame == "" then
		savegame = { }
		generate_player()
		generate_towns()
		return
	end
	
	savegame = unpickle(V.savegame)
	local leader = helper.get_leader(1)
	towns = savegame.towns
	quests = savegame.quests
	locations = savegame.locations
	unique_npcs = savegame.unique_npcs
	
	player = savegame.player
	helper.set_gold(1, player.gold)
	wesnoth.put_unit(player.x, player.y, leader)
end

load_overworld()
add_player_overview_button()
add_army_attack_button()

function scenario_start()
	save_overworld()
end

function side_turn()
	if V.side_number == 1 then
		new_turn()
	end
end

function new_turn()
		-- time passes
		local previous_time = player.time
		player.time = player.time + 24
		
		if get_day(player.time) ~= get_day(previous_time) then
			local number_bandit_camps = 0
			for key, pos in ipairs(bandit_camp_positions) do
				if not get_location(pos.x, pos.y) and math.random(1,1) == 1 then
					create_bandit_camp(pos.x, pos.y)
				end
			end
			
			for key, location in ipairs(locations) do
				if on_month_passed[location.location_type] then
					on_month_passed[location.location_type](location)
				end
			end
			
			wesnoth.message( _ "A day has passed, it is now "..get_time_string(player.time))
		end
		
		-- move all other armies
		for id, army in pairs(savegame.armies) do
			if army.behavior then
				army_behaviors[army.behavior](army, get_army_unit(army).moves)
			end
		end
end

update_labels()

-- spawn a single caravan for testing purposes
local leader = create_unique_NPC("Iron Mauler", "Drun", "Humans", nil, create_human_citizen_personality(), 2)
local army = create_army("Trade Caravan", leader, "caravan")
populate_army(army, {"Bowman", "Sergeant", "Spearman", "Mage", "Horseman"}, 10)
army.destinations = { { x = 30, y = 26 }, { x = 30, y = 24 }, { x = 34, y = 25}, { x = 35, y = 28} }
local army_unit = army_place_on_map(army, 34, 25)
