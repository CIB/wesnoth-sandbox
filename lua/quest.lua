quests = { }
create_quest = { }

-- create a new quest
function create_bandit_quest(x, y, deadline, giver)
	local quest = {
		type = "kill bandits",
		deadline = deadline,
		target_x = x, 
		target_y = y,
		giver = giver,
		completed = false,
		mission_text = {
			id = "bandit_quest_give",
			default = _ "A certain group of bandits have been causing us much hardship. Will you go and destroy their camp?"
		},
		completion_text = {
			id = "bandit_quest_complete",
			default = _ "Ah, you have vanquished those bandits! Now we can travel our roads without fear again."
		},
		taken = nil -- time the quest was taken
	}
	
	return quest
end

-- generate a bandit quest
function generate_bandit_quest(giver)
	return create_bandit_quest(2, 2, 10*DAY, giver)
end

-- add a quest to the player
function add_quest(quest)
	table.insert(quests, quest)
	quest.taken = player.time
end

-- handler called on all quests to update map meta-info
function quest_handle_map(quest)
	if quest.type == "kill bandits" then
		W.label({x=quest.target_x, y=quest.target_y, text="Bandit Camp", color="255,0,0"})
	end
end

-- handler called on all quests when the player moves to x,y on the world map
function quest_handle_move(quest, x, y, movement_percentage)
	if quest.type == "kill bandits" then
		if quest.target_x == x and quest.target_y == y then
			wesnoth.message("Good job.")
			quest.completed = true
			return true
		end
	end
	
	-- return false to not interrupt the movement
	return false
end

-- handler called on all quests when the player wins a battle
function quest_handle_victory(battle_data)
	local quest = battle_data.quest
	
	if quest.type == "kill bandits" then
		quest.completed = true
	end
end