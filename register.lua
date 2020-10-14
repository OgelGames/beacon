
-- default beacon colors
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

-- base beacon recipe
minetest.register_craft({
	output = "beacon:white",
	recipe = {
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
		{"default:mese_crystal_fragment", "default:torch", "default:mese_crystal_fragment"},
		{"default:obsidian", "default:obsidian", "default:obsidian"},
	}
})

-- floating beam cleanup
minetest.register_lbm({
	label = "Floating beacon beam cleanup",
	name = "beacon:beam_cleanup",
	nodenames = {"group:beacon_beam"},
	run_at_every_load = true,
	action = function(pos, node)
		local under_pos = vector.add(pos, beacon.param2_to_under[node.param2])
		if beacon.is_airlike_node(under_pos) then
			minetest.set_node(pos, { name = "air" })
		end
	end,
})

-- conversion for beacons from the original mod
minetest.register_lbm({
	label = "Old beacon conversion",
	name = "beacon:old_conversion",
	nodenames = {"group:beacon"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_string("effect") ~= "" then
			return -- already converted
		end
		beacon.set_default_meta(pos, "")
		meta:set_string("beam_dir", "+Y")
		meta:set_string("active", "true")
		minetest.get_node_timer(pos):start(3)
		-- old beacon effects
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

-- purple is named violet now
minetest.register_alias("beacon:purplebeam", "beacon:violetbeam")
minetest.register_alias("beacon:purplebase", "beacon:violetbase")
minetest.register_alias("beacon:purple", "beacon:violet")

-- no empty/unactivated beacon
minetest.register_alias("beacon:empty", "beacon:white")
