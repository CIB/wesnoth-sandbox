-- Helpers determining how someone should talk,
-- what relations they have to a player etc.

-- Used both for team units and unique npc's

-- Get the message a specific personality would say in a situation.
-- If the personality has no override defined, uses the default.
function get_message(personality, message)
	local overwrite = personality.talk_overwrite[message.id]
	
	local rval = overwrite or message.default
	
	-- If the message to use is a list, randomly pick
	-- a message from the list.
	if type(rval) == "table" then
		return rval[math.random(1, #rval)]
	end
	
	return rval
end

-- Create a new wesnothian citizen standard personality.
function create_human_citizen_personality()
	return {
		faction = "Humans",
		faction_relations = factions.Humans.relations,
		player_relation = 0,
		talk_overwrite = { }
	}
end

-- Generic things NPC's might want to say. The defaults are
-- defined here, overrides can be defined in individual personalities.
sayings = {
	normal_quest_reward = {
		id = "normal_quest_reward",
		default = { "Take this as reward..", "Please take this as my thanks." }
	},
	smalltalk = {
		id = "smalltalk",
		default = "Nice weather today, huh?"
	}
}