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
		taken = nil -- time the quest was taken
	}
	
	return quest
end

-- generate a bandit quest
function generate_bandit_quest(giver)
	return create_bandit_quest(2, 2, 10*DAY, giver)
end

-- handler called on all quests when the player moves to x,y on the world map
function quest_handle_move(quest, x, y)

end

-- handler called on all quests when the player wins a battle
function quest_handle_victory(quest, battle_data)

end