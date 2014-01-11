-- custom textdomain function that'll return a translator that
-- does variable substitution as well as translation
helper.textdomain = function(domain)
	local translator = wesnoth.textdomain(domain)
	return function(str)
		local rval = tostring(translator(str)): gsub("{([^{}]+)}", _ENV.S)
		return rval
	end
end

-- add gold to a side, number can be negative to remove gold
function helper.add_gold(side, gold)
	local tags = { side = side, amount = gold }
	W.gold(tags)
end

-- set the gold of a side
function helper.set_gold(side, gold)
	local tags = { side = side, amount = gold - helper.get_gold(side) }
	W.gold(tags)
end

-- get the amount of gold a side has
function helper.get_gold(side)
	local tags = { side = side }
	W.store_gold(tags)
	
	return V.gold
end

-- store the contents of a global variable into a scenario WML variable
function helper.get_global_variable(name, store)
	local tags = { side = "global", namespace = "sandbox", from_global = name, to_local = store }
	W.get_global_variable(tags)
end

-- store a scenario WML variable into a global variable
function helper.set_global_variable(name, from)
	local tags = { side = "global", namespace = "sandbox", from_local = from, to_global = name, immediate = "yes" }
	W.set_global_variable(tags)
end

-- quit the scenario, mostly used for ending the overmap scenario quickly
function helper.quitlevel(next_scenario)
	local tags = { result = "victory", bonus = "no", carryover_report = "no", carryover_percentage = 100, next_scenario = next_scenario }
	W.endlevel(tags)
end

-- place a unit close to a given location without overwriting another unit
function helper.place_unit_nearby(unit, x, y)
	local x, y = wesnoth.find_vacant_tile(x, y, unit)
	wesnoth.put_unit(x, y, unit)
end

-- multiplayer-safe random function
function helper.random(min, max)
  if not max then min, max = 1, min end
  wesnoth.fire("set_variable", { name = "LUA_random", rand = string.format("%d..%d", min, max) })
  local res = wesnoth.get_variable "LUA_random"
  wesnoth.set_variable "LUA_random"
  return res
end

-- pick a random item from a table
function helper.pick(t)
	if #t == 0 then return nil end
	
	return t[helper.random(1, #t)]
end

-- simple dialog with text and no options
function helper.dialog(msg, caption, image)
	helper.get_user_choice({ speaker = "narrator", message = msg, image = image, caption = caption }, { })
end

-- add a menu item
-- note that function_name must refer to a function 
-- in the global environment with the interface: function f()
function helper.menu_item(id, description, image, function_name)
	W.set_menu_item({id = id, description = description, { "command", { { "lua", {
				code = function_name.."()"
	}}}}})
end

-- get the leader of a side
function helper.get_leader(side)
	return wesnoth.get_units({side = side, canrecruit = "yes"})[1]
end

-- remove value from table
function helper.remove(t, item)
	for key, value in pairs(t) do
		if value == item then
			table.remove(t, key)
		end
	end
end


-- get a town by x,y coordinate
function get_town(x, y)
	for _, town in ipairs(towns) do
		if town.x == x and town.y == y then
			return town
		end
	end
end

-- message
function helper.message(msg)
	wesnoth.message(msg)
end

function helper.create_stored_unit(unit_table)
	local unit = wesnoth.create_unit(unit_table)
	local units = helper.get_variable_array("stored_units") or {}
	unit.__cfg.store_index = #units + 1 -- store the index in the unit list
	table.insert(units, unit.__cfg)
	helper.set_variable_array("stored_units", units)
	return unit
end

function helper.update_stored_unit(unit)
	local units = helper.get_variable_array("stored_units") or {}
	table[unit.__cfg.store_index] = unit.__cfg
	helper.set_variable_array("stored_units", units)
end

function helper.unstore_unit_by_id(id)
	wesnoth.fire("unstore_unit", { variable = "stored_units["..id.."]" })
end
