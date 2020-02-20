local colors = {
	["white"]	= { desc = "White", 	color = "#ffffffff" },
	["black"]	= { desc = "Black", 	color = "#0f0f0fff" },
	["blue"]	= { desc = "Blue", 		color = "#0000ffff" },
	["cyan"]	= { desc = "Cyan", 		color = "#00ffffff" },
	["green"]	= { desc = "Green", 	color = "#00ff00ff" },
	["magenta"]	= { desc = "Magenta", 	color = "#ff00ffff" },
	["orange"]	= { desc = "Orange", 	color = "#ff8000ff" },
	["red"]		= { desc = "Red", 		color = "#ff0000ff" },
	["violet"]	= { desc = "Violet", 	color = "#8f00ffff" },
	["yellow"]	= { desc = "Yellow", 	color = "#ffff00ff" },
}

local facedir_under = {
	[4] = {x= 1,y=0,z=0},
	[3] = {x=-1,y=0,z=0},
	[5] = {x=0,y= 1,z=0},
	[0] = {x=0,y=-1,z=0},
	[2] = {x=0,y=0,z= 1},
	[1] = {x=0,y=0,z=-1},
}

for name,data in pairs(colors) do
	-- beam
	minetest.register_node("beacon:"..name.."beam", {
		description = data.desc.." Beacon Beam",
		tiles = {"beacon_beam.png^[multiply:"..data.color},
		inventory_image = "beacon_beam.png^[multiply:"..data.color,
		groups = {beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beam.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		climbable = beacon.config.beam_climbable,
		selection_box = { type = "fixed", fixed = {0.125, 0.5, 0.125, -0.125, -0.5, -0.125} },
		on_rotate = function(pos, node, user, mode, new_param2)
			return false -- no rotation with screwdriver
		end,
	})

	-- beam base
	minetest.register_node("beacon:"..name.."base", {
		description = data.desc.." Beacon Beam Base",
		tiles = {"beacon_beambase.png^[multiply:"..data.color},
		inventory_image = "beacon_beambase.png^[multiply:"..data.color,
		groups = {beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beambase.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		climbable = beacon.config.beam_climbable,
		selection_box = { type = "fixed", fixed = {0.125, 0.5, 0.125, -0.125, -0.5, -0.125} },
		on_rotate = function(pos, node, user, mode, new_param2)
			return false -- no rotation with screwdriver
		end,
	})

	-- beacon node
	minetest.register_node("beacon:"..name, {
		description = data.desc.." Beacon",
		tiles = {"(beacon_baseglow.png^[multiply:"..data.color..")^beacon_base.png"},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, beacon = 1},
		drawtype = "normal",
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 13,
		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			if not beacon.allow_change(pos, player)
					or not minetest.get_meta(pos):get_inventory():get_stack(to_list, to_index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if not beacon.allow_change(pos, player) or stack:get_name() ~= beacon.config.upgrade_item
					or not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if not beacon.allow_change(pos, player) then
				return 0
			end
			return 1
		end,
		on_place = beacon.on_place,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			beacon.set_default_meta(pos)
			if placer and not vector.equals(pointed_thing.above, pointed_thing.under) then
				beacon.activate(pos, placer:get_player_name())
			end
		end,
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			beacon.show_formspec(pos, player:get_player_name())
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			beacon.show_formspec(pos, player:get_player_name())
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			beacon.show_formspec(pos, player:get_player_name())
		end,
		on_timer = function(pos, elapsed)
			return beacon.update(pos, data.color)
		end,
		can_dig = function(pos, player)
			local meta = minetest.get_meta(pos)
			return not beacon.showing_formspec(pos) and meta:get_inventory():is_empty("beacon_upgrades")
		end,
		on_destruct = beacon.remove_beam,
		on_rotate = function(pos, node, user, mode, new_param2)
			if not beacon.allow_change(pos, user) then
				return false
			end
			node.param2 = new_param2
			minetest.swap_node(pos, node)
			return true
		end,
	})

	-- coloring recipe
	minetest.register_craft({
		type = "shapeless",
		output = "beacon:"..name,
		recipe = { "group:beacon", "dye:"..name },
	})
end

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
		local under_pos = vector.add(pos, facedir_under[(node.param2-(node.param2%4))/4])
		local under_node = minetest.get_node(under_pos)
		if under_node then
			local def = minetest.registered_nodes[under_node.name]
			if def and def.drawtype == "airlike" then
				minetest.set_node(pos, {name = "air"})
			end
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
		beacon.set_default_meta(pos)
		meta:set_string("beam_dir", "+Y")
		-- old beacon effects
		if node.name == "beacon:green" then
			meta:set_string("effect", "fly")
			meta:set_int("range", 30)
			meta:set_string("active", "true")
			minetest.get_node_timer(pos):start(beacon.config.effect_refresh_time)
		elseif node.name == "beacon:red" then
			meta:set_string("effect", "healing2")
			meta:set_int("range", 30)
			meta:set_string("active", "true")
			minetest.get_node_timer(pos):start(beacon.config.effect_refresh_time)
		end
	end
})

-- purple is named violet now
minetest.register_alias("beacon:purplebeam", "beacon:violetbeam")
minetest.register_alias("beacon:purplebase", "beacon:violetbase")
minetest.register_alias("beacon:purple", "beacon:violet")

-- no empty/unactivated beacon
minetest.register_alias("beacon:empty", "beacon:white")
