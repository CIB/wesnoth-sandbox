wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/player.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/unique_npc.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/quest.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/faction.lua"

-- set up the player's variables
if player == nil then
	generate_player()
end

-- set up town metadata
if towns == nil then
	towns = {}
	
	towns[1] = { 
		x = 4, y = 2,
		name = "Aedinn",
		resources = {
			Gold = 100,
			Crops = 100
		},
		possible_recruits = {
			"Peasant", "Spearman", "Bowman", "Mage", "Fencer", "Horseman", "Heavy Infantryman", "Cavalryman"
		},
		production = {
			Crops = 20
		},
		npcs = {},
		recruits = nil,
		guards = 5,
		faction = "Humans"
	}
	
	towns[2] = { 
		x = 6, y = 2,
		name = "Forloss",
		resources = {
			Gold = 150,
			Crops = 50
		},
		possible_recruits = {
			"Peasant", "Spearman", "Bowman", "Mage", "Fencer", "Horseman", "Heavy Infantryman", "Cavalryman"
		},
		production = {
			Crops = 20
		},
		npcs = {},
		recruits = nil,
		guards = 5,
		faction = "Humans"
	}
end

-- updates all the overmap labels
function update_labels()
	--TODO: figure out a way to clear existing labels
	for key, quest in ipairs(quests) do
		quest_handle_map(quest)
	end
end

function town_month_passed(town)
	-- reset recruits
	town.recruits = nil
	
	-- trade and production
	for resource, amount in pairs(town.resources) do
		if resource ~= "Gold" then
			local sell_amount = math.floor(0.2 * amount)
			local production = town.production[resource] or 0
			town.resources[resource] = town.resources[resource] - sell_amount + production
			town.resources.Gold = town.resources.Gold + get_resource_value(town, resource) * sell_amount
		end
	end
	
	-- guard wages
	local guard_wage = 5
	local can_pay_guards = math.min(town.guards, town.resources.Gold / guard_wage)
	town.resources.Gold = town.resources.Gold - can_pay_guards * guard_wage
	town.guards = can_pay_guards
	
	-- NPC's coming and going
	if #town.npcs == 0 then
		local npc_type = town.possible_recruits[math.random(1, #town.possible_recruits)]
		local new_npc = create_unique_NPC(npc_type, nil, town.faction, town, create_human_citizen_personality())
		add_quest_to_npc(new_npc, generate_bandit_quest(new_npc))
		table.insert(town.npcs, new_npc)
	end
end

-- calculates how much a resource is worth in a given town
function get_resource_value(town, resource)
	return 1
end

-- dialog to buy resources at a town
function town_buy(town)
	while true do
		local choices = { }
		local choice_resources = {}
		
		local i = 1
		for key, value in pairs(town.resources) do 
			if key ~= "Gold" and value >= 0 then
				choice_resources[i] = key
				choices[i] = key .. "(Total: " .. value .. ")"
				i = i + 1
			end
		end
		
		choices[i] = "Done"
		
		user_choice = helper.get_user_choice({ speaker = "narrator", message = "Buy what?"}, choices)
		local bought = choice_resources[user_choice]
		
		if bought == nil then
			break
		end
		
		local buying_price = get_resource_value(town, bought)
		
		choices = { }
		local choice_values = { }
		i = 1
		local amount = 1
		while (amount <= town.resources[bought]) and ((amount * buying_price) <= helper.get_gold(1)) do
			choices[i] = amount.." (Price:"..amount*buying_price..")"
			choice_values[i] = amount
			
			if 	   amount == 1 then amount = 2
			elseif amount == 2 then amount = 5
			elseif amount == 5 then amount = 10
			elseif amount == 10 then amount = 20
			elseif amount == 20 then amount = 50
			elseif amount == 50 then amount = 100
			else break
			end
			
			i = i + 1
		end
		choices[i] = "Cancel"
		
		local buying_message = "Buy how many " .. bought .. "?"
		user_choice = helper.get_user_choice({ speaker = "narrator", message = buying_message}, choices)
		amount = choice_values[user_choice]
		if amount then
			town.resources[bought] = town.resources[bought] - amount
			player.resources[bought] = player.resources[bought] + amount
			town.resources.Gold = town.resources.Gold + amount * buying_price
			
			helper.add_gold(1, - amount * buying_price)
		end
	end
end

-- dialog to sell resources at a town
function town_sell(town)
	while true do
		local choices = { }
		local choice_resources = {}
		
		local i = 1
		for key, value in pairs(player.resources) do 
			if key ~= "Gold" and value >= 0 then
				choice_resources[i] = key
				choices[i] = key .. "(Total: " .. value .. ")"
				i = i + 1
			end
		end
		
		choices[i] = "Done"
		
		user_choice = helper.get_user_choice({ speaker = "narrator", message = "Sell what?"}, choices)
		local selling = choice_resources[user_choice]
		
		if selling == nil then
			break
		end
		
		local selling_price = get_resource_value(town, selling)
		
		choices = { }
		local choice_values = { }
		i = 1
		local amount = 1
		while (amount <= player.resources[selling]) and ((amount * selling_price) <= town.resources.Gold) do
			choices[i] = amount.." (Price:"..amount*selling_price..")"
			choice_values[i] = amount
			
			if 	   amount == 1 then amount = 2
			elseif amount == 2 then amount = 5
			elseif amount == 5 then amount = 10
			elseif amount == 10 then amount = 20
			elseif amount == 20 then amount = 50
			elseif amount == 50 then amount = 100
			else break
			end
			
			i = i + 1
		end
		choices[i] = "Cancel"
		
		local buying_message = "Sell how many " .. selling .. "?"
		user_choice = helper.get_user_choice({ speaker = "narrator", message = buying_message}, choices)
		amount = choice_values[user_choice]
		if amount then
			town.resources[selling] = town.resources[selling] + amount
			player.resources[selling] = player.resources[selling] - amount
			town.resources.Gold = town.resources.Gold - amount * selling_price
			
			helper.add_gold(1, amount * selling_price)
		end
	end
end

-- dialog to recruit units at a town
function town_recruit(town)
	while true do
		if town.recruits == nil then
			-- generate some shiny recruits
			town.recruits = {}
			for i=1,3 do
				local unit_type = town.possible_recruits[helper.random(1, #town.possible_recruits)]
				local unit = wesnoth.create_unit { type = unit_type, side = 2, placement = "recall", random_traits = yes }
				town.recruits[i] = { unit_type = unit_type, name = tostring(unit.name) }
			end
		end
		
		local choices = { }
		local choice_values = { }
		for i, recruit in ipairs(town.recruits) do
			local unit_type = wesnoth.unit_types[recruit.unit_type]
			choices[i] = "Recruit " .. recruit.name .. " the " .. unit_type.name .. " for " .. unit_type.cost .. " gold pieces."
			choice_values[i] = recruit
		end
		choices[#choices + 1] = "Done"
		
		S.gold = helper.get_gold(1)
		S.units = #wesnoth.get_recall_units({side = 1})
		S.more_units = get_maximum_recruits(player) - S.units
		
		local message = _ "Whom do you wish to recruit?\n"
		message = message .. _ "You have {gold} gold left.\n"
		if S.more_units > 0 then
			message = message .. _ "You have {units} units in your company and can recruit {more_units} more.\n"
		else
			message = message .. _ "You have {units} units in your company, but you can't recruit any more."
		end
			
		user_choice = helper.get_user_choice({ speaker = "narrator", message = message}, choices)
		local recruited = choice_values[user_choice]
		
		if recruited then
			local cost = wesnoth.unit_types[recruited.unit_type].cost
			
			if cost > helper.get_gold(1) then
				helper.get_user_choice({ speaker = "narrator", message = "You can't afford that." }, { })
			elseif S.more_units <= 0 then
				helper.dialog("You can't recruit any more units!")
			else
				helper.remove(town.recruits, recruited)
				local recruited_unit = wesnoth.create_unit { type = recruited.unit_type, side = 1, placement = "recall", random_traits = yes }
				recruited_unit.name = recruited.name
				wesnoth.put_recall_unit(recruited_unit)
				helper.add_gold(1, - cost)
				S.name = recruited.name; S.unit_type = recruited.unit_type; S.cost = cost
				wesnoth.message( _ "You recruited {name}, the {unit_type} for {cost} gold!" )
			end
		else
			break
		end
	end
end

-- talk to NPC's in the town
function town_talk(town)
	while true do
		if #town.npcs == 0 then
			helper.dialog("There's nobody to talk to..")
			return
		end
		
		local choices = {}
		local choice_values = {}
		local i = 1
		for k, name in ipairs(town.npcs) do
			local npc = unique_npcs[name]
			choices[i] = name
			choice_values[i] = npc
			i = i + 1
		end
		
		choices[#choices+1] = "Done"
		
		local npc = choice_values[1]
		if not npc then
			break
		end
		
		npc_talk(npc)
		return
	end
end

-- main town dialog, called when moving on the town's tile
function interact_town(x, y)
	local found_town = get_town(x, y)
	
	if found_town then
		local user_choice = nil
		while user_choice ~= "Done" do
			S.town_name = found_town.name
			S.relation = get_faction_relation(player, found_town.faction)
			S.faction = found_town.faction
			local message = _ "You enter {town_name}, a village of {faction}.\n";
			message = message .. _ "Relation: {relation}\n"
			message = message .. _ "Town Resources: \n"
			
			for resource_name, amount in pairs(found_town.resources) do
				S.resource_name = resource_name; S.amount = amount
				message = message .. _ "\t{resource_name}\t\t{amount}\n"
			end
			
			local choices = { _ "Buy Resources", _ "Sell Resources", _ "Tavern", _ "Talk", _ "Attack", _ "Done" }
			user_choice = choices[helper.get_user_choice({ speaker = "narrator", message = message}, choices)]
			
			if user_choice == _ "Buy Resources" then
				town_buy(found_town)
			elseif user_choice == _ "Sell Resources" then
				town_sell(found_town)
			elseif user_choice == _ "Tavern" then
				town_recruit(found_town)
			elseif user_choice == _ "Attack" then
				start_town_battle(found_town)
				return
			elseif user_choice == _ "Talk" then
				town_talk(found_town)
			end
		end
	end
end

-- start a battle with bandits, moving on to the next map
function start_bandit_battle()
	battle_data = {}
	battle_data.encounter_type = "Bandits"
	battle_data.number_enemies = #wesnoth.get_recall_units({side = 1}) + helper.random(-2, 2)
	if battle_data.number_enemies < 1 then battle_data.number_enemies = 1 end
	save_overworld()
	
	helper.dialog("You're attacked by a brigade of bandits!")
	helper.quitlevel("plain_fields")
end

function start_elf_battle()
	battle_data = {}
	battle_data.encounter_type = "Elves"
	battle_data.number_enemies = #wesnoth.get_recall_units({side = 1}) + helper.random(-2, 2)
	if battle_data.number_enemies < 1 then battle_data.number_enemies = 1 end
	save_overworld()
	
	helper.dialog("You're attacked by a wandering group of elves.")
	helper.quitlevel("plain_fields")
end

-- start a battle with a town
function start_town_battle(town)
	battle_data = {}
	battle_data.encounter_type = "Town"
	battle_data.number_enemies = town.guards
	battle_data.town = town.name
	
	save_overworld()
	
	helper.dialog("As you attempt to loot the town, the guards challenge you!")
	helper.quitlevel("town")
end

-- generic movement handler
function player_moved(x1, y1)

	local max_moves = wesnoth.get_variable("unit.max_moves")
	local tiles_moved = max_moves - wesnoth.get_variable("unit.moves")
	local movement_percentage = tiles_moved / max_moves
	local previous_time = player.time
	
	
	-- full movement is how far you can get in one full day(24 hours)
	player.time = player.time + math.ceil(movement_percentage * 24)
	

	for key, quest in ipairs(quests) do
		-- If a battle started or the like, do not process anything else
		if quest_handle_move(quest, V.x1, V.y1, movement_percentage) then
			return
		end
	end
	
	if(get_town(V.x1, V.y1)) then
		interact_town(V.x1, V.y1)
	elseif get_day(player.time) ~= get_day(previous_time) then
		for key, town in ipairs(towns) do
			town_month_passed(town)
		end
		
		wesnoth.message( _ "A day has passed, it is now "..get_time_string(player.time))
		local n = helper.random(1, 5)
		if n == 1 and get_faction_relation(player, "Bandits") < 0 then
			start_bandit_battle()
			return
		elseif n == 2 and get_faction_relation(player, "Elves") < 0 then
			start_elf_battle()
			return
		end
	end
	
    wesnoth.set_variable("unit.moves", wesnoth.get_variable("unit.max_moves"))
	W.unstore_unit({variable = "unit"})
	update_labels()
end

-- save the overworld metadata
function save_overworld()
	local leader = helper.get_leader(1)
	local savegame = { player = player, towns = towns }
	savegame.player.x = leader.x
	savegame.player.y = leader.y
	savegame.player.gold = helper.get_gold(1)
	savegame.towns = towns
	savegame.battle_data = battle_data
	savegame.quests = quests
	savegame.unique_npcs = unique_npcs
	V.savegame = pickle(savegame)
end

-- load the overworld metadata
function load_overworld()
	-- if there's no savegame yet, abort
	if type(V.savegame) ~= "string" or V.savegame == "" then
		return
	end
	
	local savegame = unpickle(V.savegame)
	local leader = helper.get_leader(1)
	towns = savegame.towns
	quests = savegame.quests
	unique_npcs = savegame.unique_npcs
	
	player = savegame.player
	helper.set_gold(1, player.gold)
	wesnoth.put_unit(player.x, player.y, leader)
end

load_overworld()
add_player_overview_button()

function scenario_start()

end