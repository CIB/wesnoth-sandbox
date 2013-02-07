-- maps tiles to battle maps and stores these mappings

battle_maps = { }

function generate_battle_map(x, y)
	local terrain_type = wesnoth.get_terrain(x, y)
	
	wesnoth.message(terrain_type)
	if string.match(terrain_type, "G.*^F.*") then
		return "forest"
	elseif string.match(terrain_type, "G.*") then
		return "grassland"
	else
		return "plain_fields"
	end
end

function get_battle_map(x, y)
	if not battle_maps[x..","..y] then
		battle_maps[x..","..y] = generate_battle_map(x, y)
	end
	return battle_maps[x..","..y]
end