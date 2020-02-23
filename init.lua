local load_start = os.clock()

beacon = {}

beacon.effects = {}

beacon.player_effects = {}

beacon.sorted_effect_ids = {}

beacon.config = {
	beam_break_nodes = minetest.settings:get_bool("beacon_beam_break_nodes") or false,
	beam_climbable = minetest.settings:get_bool("beacon_beam_climbable") or true,
	beam_length = tonumber(minetest.settings:get("beacon_beam_length")) or 200,
	default_effect = minetest.settings:get("beacon_default_effect") or "none",
	effect_range_0 = tonumber(minetest.settings:get("beacon_effect_range_0")) or 10,
	effect_range_1 = tonumber(minetest.settings:get("beacon_effect_range_1")) or 20,
	effect_range_2 = tonumber(minetest.settings:get("beacon_effect_range_3")) or 30,
	effect_range_3 = tonumber(minetest.settings:get("beacon_effect_range_4")) or 40,
	effect_range_4 = tonumber(minetest.settings:get("beacon_effect_range_5")) or 50,
	upgrade_item = minetest.settings:get("beacon_upgrade_item") or "default:diamondblock",
}

beacon.colors = {
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

beacon.dir_to_vector = {
	["+X"] = {x= 1,y=0,z=0},
	["-X"] = {x=-1,y=0,z=0},
	["+Y"] = {x=0,y= 1,z=0},
	["-Y"] = {x=0,y=-1,z=0},
	["+Z"] = {x=0,y=0,z= 1},
	["-Z"] = {x=0,y=0,z=-1},
}

beacon.dir_to_param2 = {
	["+X"] = 12,
	["-X"] = 16,
	["+Y"] = 0,
	["-Y"] = 20,
	["+Z"] = 4,
	["-Z"] = 8,
}

beacon.param2_to_under = {
	[ 0] = {x= 0,y=-1,z= 0}, [ 1] = {x= 0,y=-1,z= 0},
	[ 2] = {x= 0,y=-1,z= 0}, [ 3] = {x= 0,y=-1,z= 0},
	[ 4] = {x= 0,y= 0,z=-1}, [ 5] = {x= 0,y= 0,z=-1},
	[ 6] = {x= 0,y= 0,z=-1}, [ 7] = {x= 0,y= 0,z=-1},
	[ 8] = {x= 0,y= 0,z= 1}, [ 9] = {x= 0,y= 0,z= 1},
	[10] = {x= 0,y= 0,z= 1}, [11] = {x= 0,y= 0,z= 1},
	[12] = {x=-1,y= 0,z= 0}, [13] = {x=-1,y= 0,z= 0},
	[14] = {x=-1,y= 0,z= 0}, [15] = {x=-1,y= 0,z= 0},
	[16] = {x= 1,y= 0,z= 0}, [17] = {x= 1,y= 0,z= 0},
	[18] = {x= 1,y= 0,z= 0}, [19] = {x= 1,y= 0,z= 0},
	[20] = {x= 0,y= 1,z= 0}, [21] = {x= 0,y= 1,z= 0},
	[22] = {x= 0,y= 1,z= 0}, [23] = {x= 0,y= 1,z= 0},
}


beacon.param2_to_dir = {
	[ 0] = "+Y", [ 1] = "+Y", [ 2] = "+Y", [ 3] = "+Y",
	[ 4] = "+Z", [ 5] = "+Z", [ 6] = "+Z", [ 7] = "+Z",
	[ 8] = "-Z", [ 9] = "-Z", [10] = "-Z", [11] = "-Z",
	[12] = "+X", [13] = "+X", [14] = "+X", [15] = "+X",
	[16] = "-X", [17] = "-X", [18] = "-X", [19] = "-X",
	[20] = "-Y", [21] = "-Y", [22] = "-Y", [23] = "-Y",
}

beacon.has_player_monoids = minetest.global_exists("player_monoids")

beacon.modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(beacon.modpath.."/api.lua")
dofile(beacon.modpath.."/functions.lua")
dofile(beacon.modpath.."/formspec.lua")
dofile(beacon.modpath.."/effects.lua")
dofile(beacon.modpath.."/register.lua")
dofile(beacon.modpath.."/chatcommands.lua")

dofile(beacon.modpath.."/effects/init.lua")

minetest.after(0, function()
	-- check if upgrade item is registered
	if not minetest.registered_items[beacon.config.upgrade_item] then
		beacon.config.upgrade_item = "default:diamondblock"
	end
	-- check if default effect is registered
	if not beacon.effects[beacon.config.default_effect] then
		beacon.config.default_effect = "none"
	end
	-- sort effect ids
	for id,_ in pairs(beacon.effects) do
		table.insert(beacon.sorted_effect_ids, id)
	end
	table.sort(beacon.sorted_effect_ids)
end)

print(("[Beacon] Loaded in %f seconds"):format(os.clock() - load_start))
