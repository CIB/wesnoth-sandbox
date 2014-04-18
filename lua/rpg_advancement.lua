function post_advance()
	local unit = wesnoth.get_units({x=V.x1,y=V.y1})[1]
	if unit.side == 1 then
		strengthen(unit)
	end
end

function strengthen(unit)
	local choices = { _ "Extra HP", _ "Extra Melee Damage", _ "Extra Ranged Damage" }
	local choice_values = { "hp", "melee", "ranged" }
	local tags = { speaker = "narrator", 
		caption = "Advance", 
		image = helper.get_portrait(unit), 
		message =  "Which benefit do you choose?"
	}
	local user_choice = choice_values[helper.get_user_choice(tags, choices)]
	
	local effect = nil
	if user_choice == "hp" then
		effect = { apply_to = "hitpoints", increase = "5%", increase_total = "5%" }
	elseif user_choice == "melee" then
		effect = { apply_to = "attack", range = "melee", increase_damage = 1 }
	else
		effect = { apply_to = "attack", range = "ranged", increase_damage = 1 }
	end
	
	wesnoth.fire("object", { silent = true, duration = "forever", { "effect", effect }, { "filter", { id = unit.id } } })
end
