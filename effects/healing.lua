
-- Healing - +1 HP every 5, 10, or 15 seconds
--------------------------------------------------

local fractional_hp_count = {}

local function on_step(player, name, seconds)
	if not fractional_hp_count[name] then
		fractional_hp_count[name] = 0
	end
	if fractional_hp_count[name] >= 1 then
		fractional_hp_count[name] = 0
		local hp = player:get_hp() + 1
		local hp_max = player:get_properties().hp_max
		if hp <= hp_max then player:set_hp(hp) end
	else
		fractional_hp_count[name] = fractional_hp_count[name] + (1 / seconds)
	end
end

beacon.register_effect("healing1", {
	desc_name = "Healing LV1",
	min_level = 2,
	overrides = {},
	on_step = function(player, name)
		on_step(player, name, 15)
	end,
	on_remove = function(player, name)
		fractional_hp_count[name] = nil
	end,
})

beacon.register_effect("healing2", {
	desc_name = "Healing LV2",
	min_level = 3,
	overrides = {"healing1"},
	on_step = function(player, name)
		on_step(player, name, 10)
	end,
	on_remove = function(player, name)
		fractional_hp_count[name] = nil
	end,
})

beacon.register_effect("healing3", {
	desc_name = "Healing LV3",
	min_level = 4,
	overrides = {"healing1", "healing2"},
	on_step = function(player, name)
		on_step(player, name, 5)
	end,
	on_remove = function(player, name)
		fractional_hp_count[name] = nil
	end,
})
