
-- Gravity - 25%, 50% or 200% of the current gravity
--------------------------------------------------

local function on_apply(player, multiplier, id)
	if beacon.has_player_monoids then
		player_monoids.gravity:add_change(player, multiplier, id)
	else
		local physics = player:get_physics_override()
		physics.gravity = physics.gravity * multiplier
		player:set_physics_override(physics)
	end
end

local function on_remove(player, multiplier, id)
	if beacon.has_player_monoids then
		player_monoids.gravity:del_change(player, id)
	else
		local physics = player:get_physics_override()
		physics.gravity = physics.gravity / multiplier
		player:set_physics_override(physics)
	end
end

beacon.register_effect("gravityquarter", {
	desc_name = "Quarter Gravity",
	info = "25% of the current gravity",
	min_level = 1,
	on_apply = function(player)
		on_apply(player, 0.25, "beacon_gravityquarter")
	end,
	on_remove = function(player)
		on_remove(player, 0.25, "beacon_gravityquarter")
	end,
})

beacon.register_effect("gravityhalf", {
	desc_name = "Half Gravity",
	info = "50% of the current gravity",
	min_level = 1,
	on_apply = function(player)
		on_apply(player, 0.5, "beacon_gravityhalf")
	end,
	on_remove = function(player)
		on_remove(player, 0.5, "beacon_gravityhalf")
	end,
})

beacon.register_effect("gravitydouble", {
	desc_name = "Double Gravity",
	info = "200% of the current gravity",
	min_level = 1,
	on_apply = function(player)
		on_apply(player, 2, "beacon_gravitydouble")
	end,
	on_remove = function(player)
		on_remove(player, 2, "beacon_gravitydouble")
	end,
})