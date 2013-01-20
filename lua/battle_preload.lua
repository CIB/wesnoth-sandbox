helper = wesnoth.require "lua/helper.lua"
W = helper.set_wml_action_metatable {}

V = {}
helper.set_wml_var_metatable(V)
wesnoth.dofile "~add-ons/Sandbox/lua/sandbox_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/pickle.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"
_ = helper.textdomain "sandbox"
S = {}

helper.get_global_variable("next_battle", "next_battle")
local next_battle = unpickle(V.next_battle)

-- Load all the player's units.
local recall_units = wesnoth.get_recall_units({side = 1})
local leader = wesnoth.get_units({side = 1, canrecruit = "yes"})[1]
for _, unit in ipairs(recall_units) do
	helper.place_unit_nearby(unit, leader.x, leader.y)
end

-- Create enemy units.
local enemy_recruits = {}
if next_battle.encounter_type == "Bandits" then
	enemy_recruits = { "Thug", "Footpad", "Thief", "Poacher" }
end

local enemy_leader = wesnoth.get_units({side = 2, canrecruit = "yes"})[1]
for i = 1,next_battle.number_enemies do
	local recruit_type = enemy_recruits[helper.random(1, #enemy_recruits)]
	local enemy_unit = wesnoth.create_unit { type = recruit_type, side = 2, random_traits = yes }
	local x, y = enemy_leader.x, enemy_leader.y
	
	if i == 1 then
		-- really ugly code to replace the leader with the first unit created
		wesnoth.put_unit(x, y, enemy_unit)
		W.store_unit({{ "filter", { side = "2", x = x, y = y} }, variable = "enemy_leader", kill = "yes" })
		V.enemy_leader.canrecruit = "yes"
		W.unstore_unit({ variable = "enemy_leader", x = x, y = y})
		enemy_leader = wesnoth.get_unit(x, y)
	else
		helper.place_unit_nearby(enemy_unit, x, y)
	end
end

-- save the player's stats
function save_player()
	savegame.player = player
	V.savegame = pickle(savegame)
	helper.set_global_variable("savegame", "savegame")
end

-- load the player's stats
function load_player()
	helper.get_global_variable("savegame", "savegame")
	
	savegame = unpickle(V.savegame)
	player = savegame.player
	
	helper.set_gold(1, savegame.player.gold)
end

load_player()

-- react to a victory event
function on_victory()
	S.gold = math.random(1, 10)
	S.fame = math.random(1, 10)
	wesnoth.message( _ "You are victorious!")
	wesnoth.message( _ "You find {gold} gold pieces on your enemies' corpses." )
	wesnoth.message( _ "Songs of your valour on the battlefield spread. You gain {fame} fame." )
	
	player.gold = player.gold + S.gold
	player.fame = player.fame + S.fame
	
	save_player()
end