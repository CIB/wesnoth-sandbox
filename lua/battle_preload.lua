wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"

function scenario_start()
	-- Load all the player's units.
	local recall_units = wesnoth.get_recall_units({side = 1})
	local leader = wesnoth.get_units({side = 1, canrecruit = "yes"})[1]
	for _, unit in ipairs(recall_units) do
		helper.place_unit_nearby(unit, leader.x, leader.y)
	end

	-- Create enemy units.
	local enemy_recruits = {}
	if savegame.battle_data.encounter_type == "Bandits" then
		enemy_recruits = { "Thug", "Footpad", "Thief", "Poacher" }
	elseif savegame.battle_data.encounter_type == "Town" then
		local town = get_town_by_name(savegame.towns, savegame.battle_data.town)
		enemy_recruits = town.possible_recruits
	elseif savegame.battle_data.encounter_type == "Elves" then
		enemy_recruits = { "Elvish Fighter", "Elvish Shaman", "Elvish Scout", "Elvish Archer" }
	end

	local enemy_leader = wesnoth.get_units({side = 2, canrecruit = "yes"})[1]
	for i = 1,savegame.battle_data.number_enemies do
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
end

-- save the player's stats
function save_player()
	savegame.player = player
	V.savegame = pickle(savegame)
end

-- react to a victory event
function on_victory()
	if savegame.battle_data.encounter_type == "Bandits" then
		S.gold = math.random(1, 10)
		S.fame = math.random(1, 10)
		S.human_faction = _ "the Human Empire"
		wesnoth.message( _ "You are victorious!")
		wesnoth.message( _ "You find {gold} gold pieces on your enemies' corpses." )
		wesnoth.message( _ "Songs of your valour on the battlefield spread. You gain {fame} fame." )
		wesnoth.message( _ "Your favour with {human_faction} increases." )
		
		player.gold = player.gold + S.gold
		player.fame = player.fame + S.fame
		change_faction_relation(player, "Humans", 1)
	elseif savegame.battle_data.encounter_type == "Elves" then
		S.gold = math.random(1, 10)
		S.fame = math.random(1, 10)
		wesnoth.message( _ "You are victorious!")
		wesnoth.message( _ "You find {gold} gold pieces on your enemies' corpses." )
		wesnoth.message( _ "Songs of your valour on the battlefield spread. You gain {fame} fame." )
		
		player.gold = player.gold + S.gold
		player.fame = player.fame + S.fame
	elseif savegame.battle_data.encounter_type == "Town" then
		local town = get_town_by_name(savegame.towns, savegame.battle_data.town)
		S.gold = town.resources.Gold
		S.fame = math.random(5,20)
		S.karma = math.random(10, 20)
		S.faction = town.faction
		town.guards = #wesnoth.get_units({ side = 2 })
		
		wesnoth.message( _ "You are victorious!")
		wesnoth.message( _ "You search the village for spoils of war.")
		wesnoth.message( _ "You find {gold} gold among the corpses.")
		wesnoth.message( _ "Songs of your valour on the battlefield spread. You gain {fame} fame." )
		wesnoth.message( _ "Your relation with {faction} detorriates.")
		
		for resource, value in pairs(town.resources) do
			if resource ~= "Gold" then
				S.resource_name = resource
				S.amount = value
				wesnoth.message( _ "You scavenge {amount} cargos of {resource_name}." )
				player.resources[resource] = player.resources[resource] + value
				town.resources[resource] = 0
			end
		end
		
		player.gold = player.gold + town.resources.Gold
		town.resources.Gold = 0
		player.fame = player.fame + S.fame
		change_faction_relation(player, town.faction, -10)
	end
	
	if savegame.battle_data.quest then
		handle_victory(savegame.battle_data)
	end
	
	save_player()
end

-- load the player's stats
function load_player()
	savegame = unpickle(V.savegame)
	player = savegame.player
	
	helper.set_gold(1, savegame.player.gold)
end

load_player()