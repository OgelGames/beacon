
-- Speed Bosst - increases movement speed by +50%, +100%, +150%, or +200%
--------------------------------------------------

local function on_apply(player, multiplier, id)
	if beacon.has_player_monoids then
		player_monoids.speed:add_change(player, multiplier, id)
	else
		local physics = player:get_physics_override()
		physics.speed = physics.speed * multiplier
		player:set_physics_override(physics)
	end
end

local function on_remove(player, multiplier, id)
	if beacon.has_player_monoids then
		player_monoids.speed:del_change(player, id)
	else
		local physics = player:get_physics_override()
		physics.speed = physics.speed / multiplier
		player:set_physics_override(physics)
	end
end

beacon.register_effect("speed1", {
	desc_name = "Speed Boost LV1",
	info = "Increases speed by +50%",
	min_level = 1,
	on_apply = function(player)
		on_apply(player, 1.5, "beacon_speed1")
	end,
	on_remove = function(player)
		on_remove(player, 1.5, "beacon_speed1")
	end,
})

beacon.register_effect("speed2", {
	desc_name = "Speed Boost LV2",
	info = "Increases speed by +100%",
	min_level = 2,
	overrides = {"speed1"},
	on_apply = function(player)
		on_apply(player, 2.0, "beacon_speed2")
	end,
	on_remove = function(player)
		on_remove(player, 2.0, "beacon_speed2")
	end,
})

beacon.register_effect("speed3", {
	desc_name = "Speed Boost LV3",
	info = "Increases speed by +150%",
	min_level = 3,
	overrides = {"speed1", "speed2"},
	on_apply = function(player)
		on_apply(player, 2.5, "beacon_speed3")
	end,
	on_remove = function(player)
		on_remove(player, 2.5, "beacon_speed3")
	end,
})

beacon.register_effect("speed4", {
	desc_name = "Speed Boost LV4",
	info = "Increases speed by +200%",
	min_level = 4,
	overrides = {"speed1", "speed2", "speed3"},
	on_apply = function(player)
		on_apply(player, 3.0, "beacon_speed4")
	end,
	on_remove = function(player)
		on_remove(player, 3.0, "beacon_speed4")
	end,
})
