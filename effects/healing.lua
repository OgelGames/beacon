
-- Healing - +1 HP every 5, 10, or 15 seconds
--------------------------------------------------

local timer = {}

local function on_step(player, name, seconds)
	if not timer[name] then
		timer[name] = 0
	end
	if timer[name] >= seconds then
		timer[name] = 0
		local hp = player:get_hp() + 1
		local hp_max = player:get_properties().hp_max
		if hp <= hp_max then player:set_hp(hp) end
	else
		timer[name] = timer[name] + 1
	end
end

beacon.register_effect("healing1", {
	desc_name = "Healing LV1",
	info = "Heals health by +1 HP every 15 seconds",
	min_level = 2,
	on_step = function(player, name)
		on_step(player, name, 15)
	end,
	on_remove = function(player, name)
		timer[name] = nil
	end,
})

beacon.register_effect("healing2", {
	desc_name = "Healing LV2",
	info = "Heals health by +1 HP every 10 seconds",
	min_level = 3,
	overrides = {"healing1"},
	on_step = function(player, name)
		on_step(player, name, 10)
	end,
	on_remove = function(player, name)
		timer[name] = nil
	end,
})

beacon.register_effect("healing3", {
	desc_name = "Healing LV3",
	info = "Heals health by +1 HP every 5 seconds",
	min_level = 4,
	overrides = {"healing1", "healing2"},
	on_step = function(player, name)
		on_step(player, name, 5)
	end,
	on_remove = function(player, name)
		timer[name] = nil
	end,
})
