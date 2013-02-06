-- Helpers determining how someone should talk,
-- what relations they have to a player etc.

-- Used both for team units and unique npc's

function get_message(personality, message)
	local overwrite = personality.talk_overwrite[message.id]
	
	return overwrite or message.default
end

function create_human_citizen_personality()
	return {
		faction = "Humans",
		faction_relations = factions.Humans.relations,
		player_relation = 0,
		talk_overwrite = { }
	}
end

sayings = {
	normal_quest_reward = {
		id = "normal_quest_reward",
		default = "Take this as reward.."
	},
	smalltalk = {
		id = "smalltalk",
		default = "Nice weather today, huh?"
	}
}