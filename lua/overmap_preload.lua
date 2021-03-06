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
wesnoth.dofile "~add-ons/Sandbox/lua/rpg_advancement.lua"


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
	for key, quest in ipairs(savegame.quests) do
		if not quest.completed then
			quest_handle_map(quest)
		end
	end
end

-- calculates how much a resource is worth in a given town
function get_resource_value(town, resource)
	return 1
end

-- start a battle with a town
function start_town_battle(town)
	battle_data = {}
	battle_data.town = town.name
	
	helper.dialog("As you attempt to loot the town, the guards challenge you!")
	start_battle(town.army, "town", "town")
end

-- enter a town
function town_enter(town)
	savegame.explore_location = town
	save_overworld()
	helper.quitlevel(town.explore_scenario)
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
	
	W.reset_fog { reset_view = true }
	W.redraw { clear_shroud = true }

	for key, quest in ipairs(savegame.quests) do
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
		leader.moves = 6
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
	savegame.unique_npcs = unique_npcs
	savegame.locations = locations
	V.savegame = pickle(savegame)
end

function create_trader()
	local leader = create_unique_NPC("Cavalryman", nil, "Humans", nil, create_human_citizen_personality(), false, true)
	local army = create_army("Humans", leader, "trader")
	populate_army(army, {"Cavalryman", "Peasant", "Bowman", "Spearman"}, math.random(4, 6))
	army.destinations = {
		{ x = 35, y = 28}, -- weldyn    
		{ x = 34, y = 25},
		{ x = 30, y = 24},
		{ x = 30, y = 26},
		{ x = 11, y = 16}, -- elensefar
	}
	army.position = { x = 33, y = 27 }
	army.resources.Crops = math.random(500, 1000)
	army.resources.Gold = math.random(500, 1000)
end

-- load gamedata
function load_overworld()
	-- if there's no savegame yet, abort
	if type(V.savegame) ~= "string" or V.savegame == "" then
		savegame = { }
		savegame.quests = {}
		generate_player()
		generate_towns()
		create_trader()
		return
	end
	
	savegame = unpickle(V.savegame)
	local leader = helper.get_leader(1)
	towns = savegame.towns
	locations = savegame.locations
	unique_npcs = savegame.unique_npcs
	
	player = savegame.player
	helper.set_gold(1, player.gold)
	wesnoth.put_unit(player.x, player.y, leader)
end

load_overworld()
add_player_overview_button()
add_army_attack_button()
add_army_scout_button()

function place_armies()
	for key, army in pairs(savegame.armies) do
		-- check if the position is a coordinate tuple
		if type(army.position) == "table" then
			army_place_on_map(army, army.position.x, army.position.y)
		end
	end
end

function scenario_start()
	save_overworld()
	place_armies()
	
	local leader = wesnoth.get_units { side = 1, canrecruit = true }[1]
	leader.moves = 6
	
	-- TODO: ask the player whether they want to see tutorial messages
	if savegame.tutorial_messages == nil then
		savegame.tutorial_messages = true
	end
	
	if savegame.tutorial_messages and not savegame.tutorial_message_overworld then
		savegame.tutorial_message_overworld = true
		helper.dialog("This is the overmap. On it, you can move your warparty throughout wesnoth.\nLocations you can visit are marked on the map. You can enter them by moving your character onto the marked hex. Once you accept a quest, you will also find your quest destination marked in red on the map.\nOther warparties also move on the overmap. You can attack them by moving close to them, selecting them with right-click, and choosing \"Attack\". Be careful not to expend all your movement points before attacking, or the NPC warparty will move before you get a chance to attack.")
	end
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
			
			-- create the lich cave if it doesn't already exist
			if not get_location(39, 10) then
				create_lich_cave(39, 10)
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
			if army.behavior and get_army_unit(army) then
				army_behaviors[army.behavior](army, get_army_unit(army).moves)
			end
		end
end

function wesnoth.game_events.on_save()
	save_overworld()
	return nil
end

update_labels()
