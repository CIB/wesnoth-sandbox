-- manage towns

function create_human_npc_function(town, recruitable)
	return function(recruit_type)
		return create_unique_NPC(recruit_type, nil, town.faction, town, create_human_citizen_personality(), recruitable)
	end
end

function populate_town(town)
	local army = create_army("Town Populace", leader, nil)
	populate_army(army, town.possible_recruits, town.guards, create_human_npc_function(town))
	army.persistent = true
	town.armies.guard = army.id
	
	local civilians = create_army("Town Populace", nil, nil)
	populate_army(civilians, town.civilian_types, #town.unit_positions.civilians, create_human_npc_function(town))
	civilians.persistent = true
	town.armies.civilians = civilians.id
	
	local recruits = create_army("Recruits", nil, nil)
	populate_army(recruits, town.possible_recruits, #town.unit_positions.recruits, create_human_npc_function(town, true))
	recruits.persistent = true
	town.armies.recruits = recruits.id
end

function generate_human_town(name, x, y)
	local rval = { 
		x = x, y = y,
		name = name,
		resources = {
			Gold = helper.random(50, 200),
			Crops = helper.random(100, 200)
		},
		population = helper.random(50, 100),
		possible_recruits = {
			"Peasant"
		},
		civilian_types = {
			"Peasant"
		},
		production = {
			Crops = 200
		},
		npcs = {},
		armies = {},
		recruits = nil,
		guards = 5,
		faction = "Humans",
		type = "Human Town",
		explore_scenario = "town_explore",
		battle_scenario = "town",
		location_type = "town",
		unit_positions = {
			guards = {
				{ x = 7, y = 14 },
				{ x = 5, y = 13 },
				{ x = 5, y = 9  },
				{ x = 7, y = 9  }
			},
			civilians = {
				{ x = 8, y = 12 },
				{ x = 14, y = 12 },
				{ x = 11, y = 9 },
				{ x = 9, y = 10 }
			},
			recruits = {
				{ x = 5, y = 11 },
				{ x = 7, y = 11 }
			},
			nobles = {
				{ x = 17, y = 9}
			}
		}
	}
	
	populate_town(rval)
	
	return rval
end

function generate_human_city(name, x, y)
	local rval = { 
		x = x, y = y,
		name = name,
		resources = {
			Gold = helper.random(100, 1000),
			Crops = nil -- fill in once we know population
		},
		population = helper.random(100, 1000),
		possible_recruits = {
			"Peasant", "Spearman", "Bowman", "Mage", "Fencer", "Horseman", "Heavy Infantryman", "Cavalryman"
		},
		civilian_types = {
			"Peasant"
		},
		production = {
			Crops = 0,
			Gold = 1000
		},
		npcs = {},
		armies = {},
		recruits = nil,
		guards = 8,
		faction = "Humans",
		type = "Human City",
		explore_scenario = "human_city_explore",
		battle_scenario = "human_city",
		location_type = "town",
		unit_positions = {
			guards = {
				{ x = 7, y = 25 },
				{ x = 10, y = 24 },
				{ x = 4, y = 15  },
				{ x = 4, y = 12  },
				{ x = 22, y = 12  },
				{ x = 22, y = 16  },
				{ x = 22, y = 19  }
			},
			civilians = {
				{ x = 10, y = 12 },
				{ x = 9, y = 19 },
				{ x = 16, y = 19 },
				{ x = 9, y = 18 },
				{ x = 12, y = 12 }
			},
			recruits = {
				{ x = 8, y = 8 },
				{ x = 6, y = 10 },
				{ x = 6, y = 7 }
			},
			nobles = {
				{ x = 17, y = 9}
			}
		}
	}
	
	rval.resources.Crops = rval.population * 20
	
	populate_town(rval)
	
	return rval
end

function add_town(town)
	local x,y = town.x, town.y
	add_location(x, y, town)
	table.insert(towns, town)
end

function on_draw.town(town)
	W.label({x=town.x, y=town.y, text=town.name, color="255,255,255"})
	--wesnoth.add_tile_overlay(location.x, location.y, { image = "terrain/castle/encampment/tent2.png" })
end

-- set up towns
function generate_towns()
	towns = {}
	
	add_town(generate_human_town("Forloss", 30, 26))
	add_town(generate_human_town("Aedinn", 34, 25))
	add_town(generate_human_town("Scaldyn", 30, 24))
	add_town(generate_human_city("Weldyn", 35, 28))
end

function npc_trade(army, town)
	-- trade away food if we have more of it than we need in 3 months
	local food = town.resources.Crops
	town.production.Crops = town.production.Crops or 0
	helper.message(town.name.." Food: "..town.resources.Crops.." Gold: "..town.resources.Gold.." Population: "..town.population.." Production: "..town.production.Crops.."/"..town.population)
	if food > town.population * 2 and town.production.Crops > town.population then
		local trade_away = food - town.population * 2
		
		if army.resources.Gold < trade_away * 0.5 then
			trade_away = math.floor(army.resources.Gold / 2)
		end
		
		if trade_away > 0 then
			helper.message("Buying "..tostring(trade_away).." crops from "..town.name)
			town.resources.Crops = town.resources.Crops - trade_away
			town.resources.Gold = town.resources.Gold + trade_away * 0.5
			army.resources.Crops = army.resources.Crops + trade_away
			army.resources.Gold = army.resources.Gold - trade_away * 0.5
		end
	end
	
	-- buy food if we don't have enough of it
	if food < town.population * 30 and town.production.Crops < town.population then
		local buy = town.population * 30 - food
		
		if town.resources.Gold < buy then
			buy = town.resources.Gold
		end
		if army.resources.Crops < buy then
			buy = army.resources.Crops
		end
		
		if town.resources.Gold >= buy and army.resources.Crops >= buy then
			helper.message("Selling "..tostring(buy).." crops to "..town.name)
			town.resources.Crops = town.resources.Crops + buy
			town.resources.Gold = town.resources.Gold - buy
			army.resources.Crops = army.resources.Crops - buy
			army.resources.Gold = army.resources.Gold + buy
		end
	end
end

function on_month_passed.town(town)
	-- production
	for resource, amount in pairs(town.production) do
		town.resources[resource] = (town.resources[resource] or 0) + town.production[resource]
	end
	
	-- consumption
	town.resources.Crops = town.resources.Crops - town.population
	if town.resources.Crops < 0 then
		local death = - town.resources.Crops
		town.resources.Crops = 0
		town.population = town.population - death
	end
	
	-- check guards, hire new ones if we don't have enough
	local guard = savegame.armies[town.armies.guard]
	if #guard.units < town.guards then
		local recruit_type = town.possible_recruits[helper.random(1, #town.possible_recruits)]
		local unit_id, unit = create_human_npc_function(town, false)(recruit_type)
		table.insert(guard.units, unit_id)
		unit.variables.army = town.armies.guard.id
	end
	
	-- NPC's coming and going
	if #town.npcs == 0 then
		-- create a unique quest giver NPC
		local quest_giver_id, quest_giver = create_unique_NPC("Javelineer", nil, town.faction, town, create_human_citizen_personality(), false)
			
		table.insert(town.npcs, quest_giver_id)
	end
	
	-- update NPC quests
	for _, npc_id in ipairs(town.npcs) do
		local npc = unique_npcs[npc_id]
		if not npc.quest then
			if helper.random(1, 2) == 1 then
				local bandit_quest = generate_bandit_quest(npc_id)
				
				if bandit_quest then
					add_quest_to_npc(npc_id, bandit_quest)
				end
			else			
				local orc_quest = create_orc_invasion_quest(nil, npc_id)
				
				if orc_quest then
					add_quest_to_npc(npc_id, orc_quest)
				end
			end
		end
	end
	

	-- temporary for testing
	if not town.armies.bandit_occupation then
		if helper.random(1, 100) == 1 then
			local leader = create_unique_NPC("Bandit", nil, "Bandits", nil, create_human_citizen_personality(), false, true)
			local army = create_army("Bandits", leader, "bandits")
			populate_army(army, {"Footpad", "Thug", "Thief"}, math.random(2, 6))
			town.armies.bandit_occupation = army.id
		end
	end
end

-- town interaction helpers
---------------------------

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

function show_town_info(town)
	S.town_name = town.name
	S.relation = get_faction_relation(player, town.faction)
	S.population = town.population
	S.faction = town.faction
	local message = _ "You enter {town_name}, a village of {faction}.\n";
	message = message .. _ "Population: {population}\n"
	message = message .. _ "Relation: {relation}\n"
	message = message .. _ "Town Resources: \n"
	
	for resource_name, amount in pairs(town.resources) do
		S.resource_name = resource_name; S.amount = amount
		message = message .. _ "\t{resource_name}\t\t{amount}\n"
	end
	
	helper.get_user_choice { speaker = "narrator", message = message}
end

function town_attack(town, army, allied_army)
	-- prepare for a battle
	battle_data = {}
	battle_data.location = town
	battle_data.army = army
	battle_data.allied_army = allied_army
	battle_data.battle_handler = "default"
	save_overworld()
	
	helper.quitlevel(town.battle_scenario)
	return true
end

-- main town dialog, called when moving on the town's tile
function on_move.town(found_town)
	if found_town then
		if found_town.armies.bandit_occupation then
			local choices = { _ "Drive out the bandits", _ "Leave" }
			local choice_values = { true, false }
			local tags = { speaker = "narrator", 
				message = "This town is occupied by bandits. Drive them out?"
			}
			local user_choice = choice_values[helper.get_user_choice(tags, choices)]
			if user_choice == true then
				town_attack(found_town, found_town.armies.bandit_occupation, found_town.armies.guard)
			end
		else
			local choices = { _"Enter", _ "Attack Town", _ "Leave" }
			local choice_values = { 1, 2, 3 }
			local tags = { speaker = "narrator", 
				message = "Attack or enter?"
			}
			
			local user_choice = choice_values[helper.get_user_choice(tags, choices)]
			if user_choice == 2 then
				town_attack(found_town, found_town.armies.guard, nil)
			elseif user_choice == 1 then
				town_enter(found_town)
			end
		end
	end
end

-- get a town by its name
function get_town_by_name(towns, name)
	local town = nil
	for key, t in ipairs(towns) do
		if t.name == savegame.battle_data.town then
			town = t
			break
		end
	end
	return town
end
             
