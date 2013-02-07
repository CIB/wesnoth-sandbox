-- Global objects holding information about a battle

battle_handlers = { }

battle_handlers.bandits = { get_unit_types = function() return { "Thug", "Footpad", "Thief", "Poacher" } end }
function battle_handlers.bandits.on_victory()
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
end

battle_handlers.elves = { get_unit_types = function() return { "Elvish Fighter", "Elvish Shaman", "Elvish Scout", "Elvish Archer" } end }
function battle_handlers.elves.on_victory()
	S.gold = math.random(1, 10)
	S.fame = math.random(1, 10)
	wesnoth.message( _ "You are victorious!")
	wesnoth.message( _ "You find {gold} gold pieces on your enemies' corpses." )
	wesnoth.message( _ "Songs of your valour on the battlefield spread. You gain {fame} fame." )
	
	player.gold = player.gold + S.gold
	player.fame = player.fame + S.fame
end

battle_handlers.town = { get_unit_types = function() return get_town_by_name(towns, battle_data.town).possible_recruits end }
function battle_handlers.town.on_victory()
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