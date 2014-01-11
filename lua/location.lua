-- locations represent objects on the overmap that you can interact with
-- there should only be one location per tile

locations = {}
bandit_camp_positions = {
	{x = 31, y = 21},
	{x = 15, y = 23},
	{x = 43, y = 31},
	{x = 23, y = 30}
}	

function get_location(x, y)
	for _, value in ipairs(locations) do
		if value.x == x and value.y == y then
			return value
		end
	end
end

function add_location(x, y, location)
	if get_location(x, y) then
		error("There's already something at "..tostring(x)..", "..tostring(y))
	end
	
	table.insert(locations, location)
end

on_draw = { }
on_move = { }
on_month_passed = { }

function on_month_passed.bandit_camp(location)
	-- spawn a small bandit army every now and then
	if math.random(0, 30) == 0 then
		local leader = create_unique_NPC("Bandit", nil, "Bandits", nil, create_human_citizen_personality(), 2)
		local army = create_army("Bandits", leader, "bandits")
		populate_army(army, {"Footpad", "Thug", "Thief"}, math.random(1, 4))
		army.base = { x = location.x, y = location.y }
		army_unit = army_place_on_map(army, location.x, location.y)
	end
end


function on_move.bandit_camp(location)
	local user_choice = helper.get_user_choice({ speaker = "narrator", message = _ "You stumble upon a camp of bandits. They haven't noticed you yet, and you can still leave unchallenged. Will you attack?"}, { _ "Yes", _ "No" })
	
	if user_choice == 1 then
		-- prepare for a battle
		battle_data = {}
		battle_data.encounter_type = "Bandits"
		battle_data.number_enemies = helper.random(5, 10)
		battle_data.location = location
		battle_data.battle_handler = "bandits"
		save_overworld()
		
		helper.dialog(_ "You find a bandit camp and lay siege to it.")
		helper.quitlevel("bandit_camp")
		return true
	end
	
	-- return false to not interrupt the movement
	return false
end

function on_draw.bandit_camp(location)
	W.label({x=location.x, y=location.y, text=location.name, color="255,255,255"})
	wesnoth.add_tile_overlay(location.x, location.y, { image = "terrain/castle/encampment/tent2.png" })
end

function create_bandit_camp(x, y)
	local rval = {
		location_type = "bandit_camp",
		name = "Bandit Camp",
		x = x,
		y = y,
	}
	
	add_location(x, y, rval)
	
	return rval
end
