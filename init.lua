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
	effect_refresh_time = tonumber(minetest.settings:get("beacon_effect_refresh_time")) or 3,
	upgrade_item = minetest.settings:get("beacon_upgrade_item") or "default:diamondblock",
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
