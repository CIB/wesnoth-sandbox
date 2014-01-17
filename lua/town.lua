-- manage towns

function create_human_npc_function(town)
	return function(recruit_type)
		return create_unique_NPC(recruit_type, nil, town.faction, town, create_human_citizen_personality())
	end
end

function populate_town(town)
	local leader = create_unique_NPC("Peasant", nil, "Humans", nil, create_human_citizen_personality(), 2)
	local army = create_army("Town Populace", leader, nil)
	populate_army(army, town.possible_recruits, 5, create_human_npc_function(town))
	town.army = army.id
	
	local civilians = create_army("Town Populace", nil, nil)
	populate_army(civilians, town.civilian_types, 10, create_human_npc_function(town))
	town.civilians = civilians.id
	
	local recruits = create_army("Recruits", nil, nil)
	populate_army(recruits, town.possible_recruits, 2, create_human_npc_function(town))
	town.recruits = recruits.id
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
			Crops = 20
		},
		npcs = {},
		recruits = nil,
		guards = 5,
		faction = "Humans",
		type = "Human Town",
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
			Crops = helper.random(200, 1000)
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
		recruits = nil,
		guards = 5,
		faction = "Humans",
		type = "Human City",
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


function on_month_passed.town(town)
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
	
	-- feed citizens
	local citizens_fed = town.population
	if town.population > town.resources["Crops"] then
		citizens_fed = town.resources["Crops"]
	end
	town.resources["Crops"] = town.resources["Crops"] - citizens_fed
	
	-- TODO: actually do some morale related stuff, rather than just killing citizens
	town.population = citizens_fed
	
	-- guard wages
	local guard_wage = 5
	local can_pay_guards = math.min(town.guards, town.resources.Gold / guard_wage)
	town.resources.Gold = town.resources.Gold - can_pay_guards * guard_wage
	town.guards = can_pay_guards
	
	-- NPC's coming and going
	if #town.npcs == 0 then
		local npc_type = town.possible_recruits[math.random(1, #town.possible_recruits)]
		local new_npc = create_unique_NPC(npc_type, nil, town.faction, town, create_human_citizen_personality())
		local bandit_quest =  generate_bandit_quest(new_npc)
		if bandit_quest then
			add_quest_to_npc(new_npc, bandit_quest)
		end
		table.insert(town.npcs, new_npc)
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
				local recruited_unit_name = create_unique_NPC(recruited.unit_type, recruited.name, "player", nil, create_human_citizen_personality(), 1)
				local npc = unique_npcs[recruited_unit_name]
				helper.add_gold(1, - cost)
				S.name = recruited.name; S.unit_type = recruited.unit_type; S.cost = cost
				wesnoth.message( _ "You recruited {name}, the {unit_type} for {cost} gold!" )
				local msg = get_message(npc.personality, sayings.join_player)
				helper.dialog(msg, get_npc_name(npc.name), get_unit_portrait(npc.name))
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
function on_move.town(found_town)
	if found_town then
		local user_choice = nil
		while user_choice ~= "Done" do
			S.town_name = found_town.name
			S.relation = get_faction_relation(player, found_town.faction)
			S.population = found_town.population
			S.faction = found_town.faction
			local message = _ "You enter {town_name}, a village of {faction}.\n";
			message = message .. _ "Population: {population}\n"
			message = message .. _ "Relation: {relation}\n"
			message = message .. _ "Town Resources: \n"
			
			for resource_name, amount in pairs(found_town.resources) do
				S.resource_name = resource_name; S.amount = amount
				message = message .. _ "\t{resource_name}\t\t{amount}\n"
			end
			
			local choices = { _ "Buy Resources", _ "Sell Resources", _ "Tavern", _ "Talk", _ "Attack", _ "Enter", _ "Done" }
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
			elseif user_choice == _ "Enter" then
				town_enter(found_town)
				return
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
             
