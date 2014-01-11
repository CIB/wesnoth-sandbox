wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/quest.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/battle_handlers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/location.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/town.lua"

function scenario_start()
	-- Load all the player's units.
	local recall_units = wesnoth.get_recall_units({side = 1})
	local leader = wesnoth.get_units({side = 1, canrecruit = "yes"})[1]
	for _, unit in ipairs(recall_units) do
		helper.place_unit_nearby(unit, leader.x, leader.y)
	end
	
	-- Create enemy units from given types
	local enemy_leader = wesnoth.get_units({side = 2, canrecruit = "yes"})[1]
	local army = savegame.armies[savegame.battle_data.army]
	for i, unit_id in ipairs(army.units) do
		local x, y = enemy_leader.x, enemy_leader.y
		local enemy_unit = wesnoth.get_recall_units({ id = unit_id })[1]
		
		-- First iteration is to create the leader
		if i == 1 then
			-- really ugly code to replace the leader with the first unit created
			wesnoth.put_unit(x, y, enemy_unit)
			W.store_unit({{ "filter", { side = "2", x = x, y = y} }, variable = "enemy_leader", kill = "yes" })
			V.enemy_leader.canrecruit = "yes"
			W.unstore_unit({ variable = "enemy_leader", x = x, y = y})
			enemy_leader = wesnoth.get_unit(x, y)
		else
		-- Following iterations are to create regular enemy units
			helper.place_unit_nearby(enemy_unit, x, y)
		end
	end
	
	for key, quest in ipairs(savegame.quests) do
		quest_handle_battle_start(quest, savegame.battle_data)
	end
end

-- react to a victory event
function on_victory()
	battle_handler.on_victory()
	
	for key, quest in ipairs(savegame.quests) do
		quest_handle_victory(quest, savegame.battle_data)
	end
	
	save_player()
end

-- save the player's stats
function save_player()
	savegame.player = player
	savegame.towns = towns
	V.savegame = pickle(savegame)
end

-- load the player's stats
function load_player()
	savegame = unpickle(V.savegame)
	player = savegame.player
	battle_handler = battle_handlers[savegame.battle_data.battle_handler]
	battle_data = savegame.battle_data
	towns = savegame.towns
	
	helper.set_gold(1, savegame.player.gold)
end

load_player()
