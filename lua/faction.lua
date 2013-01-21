factions = { }

factions["Humans"] = {
	id = "Humans",
	name = _ "Human Empire",
	relations = {
		Humans = 100,
		Elves = 0,
		Dwarves = 0,
		Bandits = -100
	}
}

factions["Elves"] = {
	id = "Elves",
	name = _ "Elvish Alliance",
	relations = {
		Humans = 0,
		Elves = 100,
		Dwarves = -50,
		Bandits = -50
	}
}

factions["Dwarves"] = {
	id = "Dwarves",
	name = _ "Dwarven Kingdom",
	relations = {
		Humans = 0,
		Elves = -50,
		Dwarves = 100,
		Bandits = -50
	}
}

factions["Bandits"] = {
	id = "Bandits",
	name = _ "Outlaws",
	relations = {
		Humans = -50,
		Elves = -50,
		Dwarves = -50,
		Bandits = 100
	}
}

function get_faction_name(faction)
	return factions[faction].name
end