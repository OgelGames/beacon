
-- Water Breathing - allows swiming in water without losing breath
--------------------------------------------------

local water_nodes = {
	"default:water_source",
	"default:water_flowing",
	"default:river_water_source",
	"default:river_water_flowing",
}

beacon.register_effect("breathing", {
	desc_name = "Water Breathing",
	min_level = 3,
	overrides = {},
	on_step = function(player, name)
		if player:get_breath() < 10 then
			local pos = vector.round(player:get_pos())
			pos.y = pos.y + 1
			local node = minetest.get_node(pos)
			for _,name in ipairs(water_nodes) do
				if node.name == name then
					player:set_breath(10)
					return
				end
			end
		end
	end,
})
