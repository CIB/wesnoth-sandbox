wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/quest.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/battle_handlers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/location.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/town.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/unique_npc.lua"

function scenario_start()
	-- man the guard posts(if any)
	local army = savegame.armies[location.army]
	local positions = location.unit_positions
	if positions.guards then
		for i=1,math.min(#positions.guards, #army.units) do
			local position = positions.guards[i]
			local unit_id = army.units[i]
			local guard_unit = helper.unstore_unit(unit_id, position.x, position.y, 2)
		end
	end
	
	local civilians = savegame.armies[location.civilians]
	if positions.civilians then
		for i=1,math.min(#positions.civilians, #civilians.units) do
			local position = positions.civilians[i]
			local unit_id = civilians.units[i]
			local civilian_unit = helper.unstore_unit(unit_id, position.x, position.y, 2)
		end
	end
	

	local recruits = savegame.armies[location.recruits]
	if positions.recruits then
		for i=1,math.min(#positions.recruits, #recruits.units) do
			local position = positions.recruits[i]
			local unit_id = recruits.units[i]
			local recruit_unit = helper.unstore_unit(unit_id, position.x, position.y, 2)
		end
	end
	
	-- put some recruits on the map
	
	
	--[[
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
	]]
end

-- save the player's stats
function save_player()
	savegame.player = player
	savegame.towns = towns
	savegame.unique_npcs = unique_npcs
	V.savegame = pickle(savegame)
end

-- load the player's stats
function load_player()
	savegame = unpickle(V.savegame)
	player = savegame.player
	towns = savegame.towns
	location = savegame.explore_location -- the location we're exploring
	unique_npcs = savegame.unique_npcs
	
	helper.set_gold(1, savegame.player.gold)
end

function player_moved(x, y)
	local leader = wesnoth.get_units { side = 1, canrecruit = true}[1]
	leader.moves = leader.max_moves
	
	if x == 1 or y == 1 then
		helper.quitlevel("overmap")
	end
end

function explore_talk()
	local unit_at_location = wesnoth.get_units { x = V.x1, y = V.y1 }[1]
	local npc = unique_npcs[unit_at_location.id]
	if npc then
		npc_talk(npc)
	end
end


function add_talk_button()
	helper.menu_item("army_attack_button", _ "Talk", nil, "explore_talk", {{"have_unit", { x = "$x1", y = "$y1", side = 2, {"filter_adjacent", { side = 1}}}}})
end

add_talk_button()

load_player()
