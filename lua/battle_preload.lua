helper = wesnoth.require "lua/helper.lua"
W = helper.set_wml_action_metatable {}
_ = wesnoth.textdomain "my-campaign"

V = {}
helper.set_wml_var_metatable(V)
wesnoth.dofile "~add-ons/Sandbox/sandbox_helpers.lua"

-- Load all the player's units.
local recall_units = wesnoth.get_recall_units({side = 1})
local leader = wesnoth.get_units({side = 1, canrecruit = "yes"})[1]
for _, unit in ipairs(recall_units) do
	helper.place_unit_nearby(unit, leader.x, leader.y)
end

-- Create enemy units.
local enemy_recruits = { "Thug", "Footpad", "Thief", "Poacher" }
local enemy_leader = wesnoth.get_units({side = 2, canrecruit = "yes"})[1]
for _ = 1,5 do
	local recruit_type = enemy_recruits[helper.random(1, #enemy_recruits)]
	local enemy_unit = wesnoth.create_unit { type = recruit_type, side = 2, random_traits = yes }
	helper.place_unit_nearby(enemy_unit, enemy_leader.x, enemy_leader.y)
end