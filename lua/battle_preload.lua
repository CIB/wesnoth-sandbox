wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/quest.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/battle_handlers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/location.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/town.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/army.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/rpg_advancement.lua"

function place_army(army_id, side, x, y)
	local army = savegame.armies[army_id]
	
	-- place actual enemy leader
	if army.leader then
		local enemy_unit = wesnoth.get_recall_units({ id = army.leader })[1]
		enemy_unit.side = side
		helper.place_unit_nearby(enemy_unit, x, y)
	end
	
	for i, unit_id in ipairs(army.units) do
		local enemy_unit = wesnoth.get_recall_units({ id = unit_id })[1]
		enemy_unit.side = side
		
		helper.place_unit_nearby(enemy_unit, x, y)
	end
end

function scenario_start()
	-- Load all the player's units.
	local recall_units = wesnoth.get_recall_units({side = 1})
	local leader = wesnoth.get_units({side = 1, canrecruit = true})[1]
	for _, unit in ipairs(recall_units) do
		helper.place_unit_nearby(unit, leader.x, leader.y)
	end
	
	local enemy_leader = wesnoth.get_units({side = 2, canrecruit = true})[1]
	local x, y = enemy_leader.x, enemy_leader.y
	wesnoth.extract_unit(enemy_leader)
	if savegame.battle_data.army then
		place_army(savegame.battle_data.army, 2, x, y)
	end
	
	local allied_leader = wesnoth.get_units({side = 3, canrecruit = true})[1]
	if allied_leader then
		x, y = allied_leader.x, allied_leader.y
		wesnoth.extract_unit(allied_leader)
		if savegame.battle_data.allied_army then
			place_army(savegame.battle_data.allied_army, 3, x, y)
		end
	end
	
	if savegame.battle_data.quest then
		quest_handle_battle_start(savegame.battle_data.quest, savegame.battle_data)
	end
end

function side_turn()
	local enemy_units = wesnoth.get_units {side = 2}
	if #enemy_units == 0 then
		helper.quitlevel("overmap")
	end
end

-- react to a victory event
function on_victory()
	battle_handler.on_victory()
	
	if savegame.battle_data.quest then
		quest_handle_victory(savegame.battle_data.quest, savegame.battle_data)
	end
	
	-- kill the army we just defeated
	local defeated_army = savegame.armies[savegame.battle_data.army]
	if defeated_army and not defeated_army.persistent then
		kill_army(savegame.battle_data.army)
	end
	
	cleanup_army(savegame.battle_data.army)
	cleanup_army(savegame.battle_data.allied_army)
	
	if savegame.battle_data.location and savegame.battle_data.location.armies then
		for key, value in pairs(savegame.battle_data.location.armies) do
			if not savegame.armies[value] then
				savegame.battle_data.location.armies[key] = nil
			end
		end
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
