-- set up our standard lua environment
helper = wesnoth.require "lua/helper.lua"
W = helper.set_wml_action_metatable {}
_ = wesnoth.textdomain "my-campaign"

V = {}
helper.set_wml_var_metatable(V)
wesnoth.dofile "~add-ons/Sandbox/lua/sandbox_helpers.lua"

-- set up the player's variables
if player == nil then
	player = { }
	player.resources = {
		Crops = 100
	}
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
			"Peasant", "Spearman", "Bowman", "Mage"
		},
		recruits = nil
	}
	
	towns[2] = { 
		x = 6, y = 2,
		name = "Forloss",
		resources = {
			Gold = 150,
			Crops = 50
		},
		possible_recruits = {
			"Peasant", "Spearman", "Bowman", "Mage"
		},
		recruits = nil
	}
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
				town.recruits[i] = wesnoth.create_unit { type = unit_type, side = 2, placement = "recall", random_traits = yes }
			end
		end
		
		local choices = { }
		local choice_values = { }
		local i = 1
		for _, recruit in ipairs(town.recruits) do
			local unit_type = wesnoth.unit_types[recruit.type]
			choices[i] = "Recruit " .. recruit.name .. " the " .. unit_type.name .. " for " .. unit_type.cost .. " gold pieces."
			choice_values[i] = recruit
			i = i + 1
		end
		choices[i] = "Done"
		
		user_choice = helper.get_user_choice({ speaker = "narrator", message = "Whom do you wish to recruit?"}, choices)
		local recruited = choice_values[user_choice]
		
		if recruited then
			local cost = wesnoth.unit_types[recruited.type].cost
			
			if cost > helper.get_gold(1) then
				helper.get_user_choice({ speaker = "narrator", message = "You can't afford that." }, { })
			else
				helper.remove(town.recruits, recruited)
				recruited.side = 1
				wesnoth.put_recall_unit(recruited)
				helper.add_gold(1, - cost)
			end
		else
			break
		end
	end
end

-- main town dialog, called when moving on the town's tile
function interact_town(x, y)
	local found_town = nil
	for _, town in ipairs(towns) do
		if town.x == x and town.y == y then
			found_town = town
			break
		end
	end
	
	if found_town then
		local user_choice = nil
		while user_choice ~= "Done" do
			V.town_name = found_town.name
			V.message = _ "Welcome to $town_name!\n"
			V.message = V.message .. _ "Town Resources: \n"
			
			for key, value in pairs(found_town.resources) do
				V.resource_name = key
				V.amount = value
				
				V.message = V.message .. _ "\t".. V.resource_name .. "\t\t" .. V.amount .. "\n"
			end
			
			local choices = { "Buy Resources", "Sell Resources", "Tavern", "Done" }
			user_choice = choices[helper.get_user_choice({ speaker = "narrator", message = V.message}, choices)]
			
			if user_choice == "Buy Resources" then
				town_buy(found_town)
			elseif user_choice == "Sell Resources" then
				town_sell(found_town)
			elseif user_choice == "Tavern" then
				town_recruit(found_town)
			end
		end
	end
end

-- start a battle, moving on to the next map
function start_battle()
	helper.quitlevel("plain_fields")
end

-- generic movement handler
function player_moved(x1, y1)
	interact_town(V.x1, V.y1)
	
	if helper.random(1, 5) == 1 then
		helper.dialog("You're attacked by a troup of bandits!")
		start_battle()
	end
end