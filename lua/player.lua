-- when starting a new game, this will be called
function generate_player()
	player = { }
	player.resources = {
		Crops = 100
	}
	player.fame = 0
	player.karma = 0
	player.time = store_time(1000, 1, 1, 1)
	
	player.faction_relations = {
		Humans = 50,
		Elves = -50,
		Dwarves = 0,
		Bandits = -50
	}
end

function get_maximum_recruits(player)
	return math.floor(2 + math.log(1+player.fame))
end

function get_number_units(player)
	return #wesnoth.get_recall_units({side = 1})
end

function display_overview()
	S.fame = player.fame
	S.karma = player.karma
	S.gold = savegame.player.gold
	S.units = get_number_units(player)
	S.max_units = get_maximum_recruits(player)
	local message = _ "Fame: {fame}\nKarma: {karma}\nGold: {gold}\nUnits: {units}/{max_units}\n"
	helper.dialog(message)
end

function add_player_overview_button()
	helper.menu_item("player_overview_button", _ "Player Overview", nil, "display_overview")
end

function get_faction_relation(player, faction)
	return math.floor(player.faction_relations[faction])
end

function change_faction_relation(player, faction, value)
	player.faction_relations[faction] = player.faction_relations[faction] + value
	if player.faction_relations[faction] < -100 then player.faction_relations[faction] = -100 end
	if player.faction_relations[faction] >  100 then player.faction_relations[faction] =  100 end
end

function set_faction_relation(player, faction, value)
	player.faction_relations[faction] = value
	if player.faction_relations[faction] < -100 then player.faction_relations[faction] = -100 end
	if player.faction_relations[faction] >  100 then player.faction_relations[faction] =  100 end
end

function player_adjust_resources(player, deltas)
	-- true if the player had as many resources as he had to give, false otherwise
	local rval = true

	for key, value in pairs(deltas) do
		if key == "Gold" then
			if helper.get_gold(1) < (-value) then
				value = - helper.get_gold(1)
				rval = false
			end
			helper.add_gold(1, value)
			if value > 0 then
				S.gold = value
				helper.message(_ "You get {gold} gold pieces.")
			else
				S.gold = -value
				helper.message(_ "You lose {gold} gold pieces.")
			end
		else
			if player.resources[key] < - value then
				value = - player.resources[key]
				rval = false
			end
			player.resources[key] = player.resources[key] + value
			
			S.resource = key
			if value > 0 then
				S.cargos = value
				helper.message(_ "You get {cargos} cargos of {resource}.")
			else
				S.cargos = -value
				helper.message(_ "You lose {cargos} cargos of {resource}.")
			end
		end
	end
	
	
	return rval
end