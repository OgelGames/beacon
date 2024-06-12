
-- Default beacon colors
beacon.register_color("White", "#ffffffff", "dye:white")
beacon.register_color("Black", "#0f0f0fff", "dye:black")
beacon.register_color("Blue", "#0000ffff", "dye:blue")
beacon.register_color("Cyan", "#00ffffff", "dye:cyan")
beacon.register_color("Green", "#00ff00ff", "dye:green")
beacon.register_color("Magenta", "#ff00ffff", "dye:magenta")
beacon.register_color("Orange", "#ff8000ff", "dye:orange")
beacon.register_color("Red", "#ff0000ff", "dye:red")
beacon.register_color("Violet", "#8f00ffff", "dye:violet")
beacon.register_color("Yellow", "#ffff00ff", "dye:yellow")

-- Base beacon recipe
minetest.register_craft({
	output = "beacon:white",
	recipe = {
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
		{"default:mese_crystal_fragment", "default:torch", "default:mese_crystal_fragment"},
		{"default:obsidian", "default:obsidian", "default:obsidian"},
	}
})

-- Floating beam cleanup
local function cleanup_leftovers(pos, param2, dir)
	local origin, count = pos, 0
	while true do
		local node = beacon.get_node(pos)
		if node.param2 ~= param2 or minetest.get_item_group(node.name, "beacon_beam") ~= 1 then
			break
		end
		minetest.set_node(pos, {name = "air"})
		pos = vector.subtract(pos, dir)
		count = count + 1
	end
	if count == 0 then
		return
	end
	minetest.log("action", string.format(
		"[beacon] Removed %i floating beacon beam nodes from %s to %s",
		count, minetest.pos_to_string(origin), minetest.pos_to_string(pos)
	))
end

minetest.register_lbm({
	label = "Floating beacon beam cleanup",
	name = "beacon:beam_cleanup",
	nodenames = {"group:beacon_beam"},
	run_at_every_load = true,
	action = function(pos, node)
		local dir = beacon.param2_to_under[node.param2 % 32 % 24]
		local under_pos = vector.add(pos, dir)
		if beacon.is_airlike_node(under_pos) then
			minetest.set_node(pos, {name = "air"})
			-- Depending on the direction of the beam, the LBM will only cleanup one node each time it runs,
			-- so after the LBM runs, check for leftover beacon beam nodes above and remove them.
			local above_pos = vector.subtract(pos, dir)
			minetest.after(1, cleanup_leftovers, above_pos, node.param2, dir)
		end
	end,
})

-- Conversion for beacons from the original mod
minetest.register_lbm({
	label = "Old beacon conversion",
	name = "beacon:old_conversion",
	nodenames = {"group:beacon"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_string("effect") ~= "" then
			return  -- Already converted
		end
		beacon.set_default_meta(pos, "")
		meta:set_string("beam_dir", "+Y")
		meta:set_string("active", "true")
		minetest.get_node_timer(pos):start(3)
		-- Old beacon effects
		if node.name == "beacon:green" then
			meta:set_string("effect", "fly")
			meta:set_int("range", 30)
		elseif node.name == "beacon:red" then
			meta:set_string("effect", "healing2")
			meta:set_int("range", 30)
		end
		beacon.update_formspec(pos)
	end
})

-- Purple is named violet now
minetest.register_alias("beacon:purplebeam", "beacon:violetbeam")
minetest.register_alias("beacon:purplebase", "beacon:violetbase")
minetest.register_alias("beacon:purple", "beacon:violet")

-- No empty/unactivated beacon
minetest.register_alias("beacon:empty", "beacon:white")
