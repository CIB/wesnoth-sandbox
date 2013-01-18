-- add gold to a side, number can be negative to remove gold
function helper.add_gold(side, gold)
	local tags = { side = side, amount = gold }
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
	local tags = { side = "player1", namespace = "sandbox", from_global = name, to_local = store }
	W.get_global_variable(tags)
end

-- store a scenario WML variable into a global variable
function helper.set_global_variable(name, from)
	local tags = { side = "player1", namespace = "sandbox", from_local = from, to_global = name, immediate = "yes" }
	W.get_global_variable(tags)
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

-- simple dialog with text and no options
function helper.dialog(msg)
	helper.get_user_choice({ speaker = "narrator", message = msg }, { })
end

-- remove value from table
function helper.remove(t, item)
	for key, value in pairs(t) do
		if value == item then
			table.remove(t, key)
		end
	end
end