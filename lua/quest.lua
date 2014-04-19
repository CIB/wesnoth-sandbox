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
	local bandit_camps = {}
	for key, location in ipairs(locations) do
		if location.location_type == "bandit_camp" then
			table.insert(bandit_camps, location)
		end
	end
	
	local location = helper.pick(bandit_camps)
	
	if location then
		return create_bandit_quest(location.x, location.y, 10*DAY, giver)
	end
end

-- add a quest to the player
function add_quest(quest)
	table.insert(savegame.quests, quest)
	quest.taken = player.time
end

-- remove a quest from the player
function remove_quest(quest)
	for key, value in ipairs(savegame.quests) do
		if value == quest then table.remove(savegame.quests, key); break end
	end
end

-- handler called on all quests to update map meta-info
function quest_handle_map(quest)
	if quest.completed then
		return
	end
	
	if quest.type == "kill bandits" then
		W.label({x=quest.target_x, y=quest.target_y, text="Quest: Destroy Bandit Camp", color="255,0,0"})
	elseif quest.type == "orc invasion" then
		W.label({x=quest.target_x, y=quest.target_y, text="Quest: Repel Orc Invasion", color="255,0,0"})
	end
end

-- handler called on all quests when the player moves to x,y on the world map
function quest_handle_move(quest, x, y, movement_percentage)
	if quest.type == "orc invasion" and x == quest.target_x and y == quest.target_y and not quest.completed then
		-- prepare for a battle
		battle_data = {}
		battle_data.army = quest.army    
		battle_data.allied_army = quest.allied_army
		battle_data.battle_handler = "default"
		battle_data.quest = quest
		save_overworld()
		
		helper.quitlevel("forest")
		
		return true
	end

	-- return false to not interrupt the movement
	return false
end

-- handler called when a battle starts
function quest_handle_battle_start(quest, battle_data)
	--[[if 
		quest.type == "kill bandits" 				and
		battle_data.location 						and 
		battle_data.location.x == quest.target_x 	and
		battle_data.location.y == quest.target_y 	and
		battle_data.location.location_type == "bandit_camp"
	then
		battle_data.quest = quest
	end]]
	
	if quest.type == "orc invasion" then
		-- get the leader of our allies
		local allied_leader = wesnoth.get_units { side = 3, canrecruit = true }[1]
		local enemy_leader = wesnoth.get_units { side = 2, canrecruit = true }[1]
		
		helper.get_user_choice({ speaker = allied_leader.id, message = "You shall go no further, foul creatures! We will end your menace right here." }, { })
		helper.get_user_choice({ speaker = enemy_leader.id, message = "What's this, you hired some mercenaries, eh? We will roast you over a fire!" }, { })
		helper.get_user_choice({ speaker = "narrator", message = "You wonder what you've gotten yourself into this time.." }, { })
	end
end

-- handler called on all quests when the player wins a battle
function quest_handle_victory(quest, battle_data)
	if quest and (quest.type == "kill bandits" or quest.type == "orc invasion") then
		quest.completed = true
	end
end


-- create a new quest
function create_orc_invasion_quest(x, y, deadline, giver)
	local quest = {
		type = "orc invasion",
		deadline = deadline,
		target_x = x, 
		target_y = y,
		giver = giver,
		completed = false,
		mission_text = {
			id = "orc_invasion_quest_give",
			default = _ "Those stinking orcs are planning another raid. We plan to repel them, but we could use some sturdy men. If your troops would help us out, we might reward you."
		},
		completion_text = {
			id = "orc_invasion_quest_complete",
			default = _ "Oh, you survived the battle? Well, I guess that makes you eligible for pay.."
		},
		taken = nil -- time the quest was taken
	}
	
	-- generate orc and allied army
	local leader = create_unique_NPC("Orcish Ruler", nil, "Orcs", nil, nil, false, true)
	local army = create_army("Orcs", leader, "orcs")
	populate_army(army, {"Orcish Archer", "Orcish Assassin", "Orcish Grunt", "Goblin Spearman"}, 8)
	quest.army = army.id
	
	leader = create_unique_NPC("Lieutenant", nil, "Humans", nil, nil, false, true)
	army = create_army("Humans", leader, "humans")
	populate_army(army, {"Spearman", "Bowman", "Mage", "Fencer", "Cavalryman", "Horseman", "Heavy Infantryman"}, 8)
	quest.allied_army = army.id
	
	return quest
end
