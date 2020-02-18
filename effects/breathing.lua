
-- Water Breathing - allows swiming in water without losing breath
--------------------------------------------------

local water_nodes = {
	["default:water_source"] = true,
	["default:water_flowing"] = true,
	["default:river_water_source"] = true,
	["default:river_water_flowing"] = true,
}

beacon.register_effect("breathing", {
	desc_name = "Water Breathing",
	info = "Allows swiming in water without losing breath",
	min_level = 3,
	overrides = {},
	on_step = function(player, name)
		if player:get_breath() < 10 then
			local pos = vector.round(player:get_pos())
			pos.y = pos.y + 1
			local node = minetest.get_node(pos)
			if water_nodes[node.name] then
				player:set_breath(10)
			end
		end
	end,
})
