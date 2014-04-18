
wesnoth.dofile "~add-ons/Sandbox/lua/setup_helpers.lua"

function scenario_start()
	add_select_leader_button()
	
	helper.dialog("Welcome to the wesnoth sandbox: Citizen of Wesnoth!\nThis is not a regular campaign. Instead of leading your troops through a set of pre-determined scenarios, you will be able to travel on an overmap and determine your own battles and destinations. You can also visit towns and other locations.")
	helper.dialog("We'll start off by selecting your leader. Your leader will represent your troops on the overmap and in towns and other peaceful locations. In battle, however, you will have a variety of troops in addition to your leader.")
	helper.dialog("Please right-click any of the presented units to select your leader.")
end

function player_moved(x, y)
end

function select_leader()
	local unit_at_location = wesnoth.get_units { x = V.x1, y = V.y1 }[1]
	local previous_leader = wesnoth.get_units { canrecruit = true }
	
	-- make new unit leader
	local new_leader = wesnoth.create_unit { type = unit_at_location.type, name = previous_leader.name, side = 1, canrecruit = true, id="player1_leader", role="player1_leader" }
	
	-- delete all other units by making them private and then not
	-- doing anything with them
	for _, unit in ipairs(wesnoth.get_units { side = 1 }) do
		wesnoth.extract_unit(unit)
	end
	
	wesnoth.put_unit(1, 1, new_leader)
	
	wesnoth.fire("clear_menu_item", { id = "select_leader_button" })
	
	helper.quitlevel("overmap")
end

function add_select_leader_button()
	helper.menu_item("select_leader_button", _ "Choose", nil, "select_leader", {{"have_unit", { x = "$x1", y = "$y1", side = 1, {"filter_adjacent", { side = 1}}}}})
end
