
-- Jump Bosst - increases jump power by +25%, +50%, +75%, or +100%
--------------------------------------------------

local function on_apply(player, multiplier, id)
	if beacon.has_player_monoids then
		player_monoids.jump:add_change(player, multiplier, id)
	else
		local physics = player:get_physics_override()
		physics.jump = physics.jump * multiplier
		player:set_physics_override(physics)
	end
end

local function on_remove(player, multiplier, id)
	if beacon.has_player_monoids then
		player_monoids.jump:del_change(player, id)
	else
		local physics = player:get_physics_override()
		physics.jump = physics.jump / multiplier
		player:set_physics_override(physics)
	end
end

beacon.register_effect("jump1", {
	desc_name = "Jump Boost LV1",
	info = "Increases jump power by +25%",
	min_level = 1,
	on_apply = function(player)
		on_apply(player, 1.25, "beacon_jump1")
	end,
	on_remove = function(player)
		on_remove(player, 1.25, "beacon_jump1")
	end,
})

beacon.register_effect("jump2", {
	desc_name = "Jump Boost LV2",
	info = "Increases jump power by +50%",
	min_level = 2,
	overrides = {"jump1"},
	on_apply = function(player)
		on_apply(player, 1.5, "beacon_jump2")
	end,
	on_remove = function(player)
		on_remove(player, 1.5, "beacon_jump2")
	end,
})

beacon.register_effect("jump3", {
	desc_name = "Jump Boost LV3",
	info = "Increases jump power by +75%",
	min_level = 3,
	overrides = {"jump1", "jump2"},
	on_apply = function(player)
		on_apply(player, 1.75, "beacon_jump3")
	end,
	on_remove = function(player)
		on_remove(player, 1.75, "beacon_jump3")
	end,
})

beacon.register_effect("jump4", {
	desc_name = "Jump Boost LV4",
	info = "Increases jump power by +100%",
	min_level = 4,
	overrides = {"jump1", "jump2", "jump3"},
	on_apply = function(player)
		on_apply(player, 2.0, "beacon_jump4")
	end,
	on_remove = function(player)
		on_remove(player, 2.0, "beacon_jump4")
	end,
})
