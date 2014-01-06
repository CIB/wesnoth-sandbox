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
	elseif type(rval) == "function" then
		return rval(personality, message)
	end
	
	return rval
end

-- Check how nice an NPC is towards a player. This is a function of
-- both their relation to the player, as well as their inherent
-- "niceness". Only use this when the NPC is addressing the player.
function personality_get_player_nicety(personality, player)
	return personality.attributes.nice + 2 * personality.player_relation
end

-- Check how nice an NPC is towards another NPC. This is a function of
-- both their relation to the other NPC, as well as their inherent
-- "niceness". Only use this when they are addressing the other NPC.
function personality_get_npc_nicety(personality, npc_name)
	local rval = personality.attributes.nice
	if npc_relations[npc_name] then
		rval = rval + personality.npc_relations[npc_name]
	end
	return rval
end

-- Create a new wesnothian citizen standard personality.
function create_human_citizen_personality()
	return {
		faction = "Humans",
		faction_relations = factions.Humans.relations,
		player_relation = 0,
		attributes = {
			proud = math.random(-50,50), -- proud-humble scale
			nice = math.random(-50,50), -- nice-mean scale
			shy = math.random(-50,50) -- shy-extrovert scale
		},
		npc_relations = { },
		talk_overwrite = { }
	}
end

-- get the highest attribute for this character, useful for selecting
-- a message
function get_highest_attribute(personality, select_from)
	local highest_value = nil
	local highest_attribute = nil
	local sign = nil -- "plus" for a positive attribute, "minus" for a negative attribute
	
	for attribute, value in pairs(personality.attributes) do
		-- only consider attributes contained in select_from
		if select_from[attribute] then
			if (highest_value == nil) or (math.abs(value) > highest_value) then
				highest_value = math.abs(value)
				highest_attribute = attribute
				
				if math.abs(value) >= 0 then
					sign = "plus"
				else
					sigh = "minus"
				end
			end
		end
	end
	
	return highest_attribute, sign
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
	},
	join_player = {
		id = "join_player",
		default = function(personality, message)
			local highest_attribute, sign = get_highest_attribute(personality, {shy=true, proud=true, nice=true})
			if highest_attribute == "shy" and sign == "plus" then
				return "..." -- Too shy to speak!
			elseif highest_attribute == "proud" and sign == "plus" then
				return "It was a wise choice to hire me! You won't regret it!"
			elseif highest_attribute == "nice" and sign == "plus" then
				return "I shall serve you to my best ability."
			elseif highest_attribute == "nice" and sign == "minus" then
				return "Eh.. Be sure that I'll only stick around if the pay is good."
			else
				return "Let's set out, then."
			end
		end
	}
}
