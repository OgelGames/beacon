beacon = {}

beacon.effects = {}

beacon.player_effects = {}

beacon.config = {
	beam_break_nodes = minetest.settings:get_bool("beacon_beam_break_nodes") or false,
	beam_climbable = minetest.settings:get_bool("beacon_beam_climbable") or true,
	beam_length = tonumber(minetest.settings:get("beacon_beam_length")) or 200,
	effect_range_0 = tonumber(minetest.settings:get("beacon_effect_range_0")) or 10,
	effect_range_1 = tonumber(minetest.settings:get("beacon_effect_range_1")) or 20,
	effect_range_2 = tonumber(minetest.settings:get("beacon_effect_range_3")) or 30,
	effect_range_3 = tonumber(minetest.settings:get("beacon_effect_range_4")) or 40,
	effect_range_4 = tonumber(minetest.settings:get("beacon_effect_range_5")) or 50,
	effect_refresh_time = tonumber(minetest.settings:get("beacon_effect_refresh_time")) or 3,
	upgrade_item = minetest.settings:get("beacon_upgrade_item") or "default:diamondblock",
}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/api.lua")
dofile(modpath.."/functions.lua")
dofile(modpath.."/formspec.lua")
dofile(modpath.."/effects.lua")
dofile(modpath.."/register.lua")

minetest.after(0, function()
	if minetest.registered_items[beacon.config.upgrade_item] == nil then
		beacon.config.upgrade_item = "default:diamondblock"
	end
end)

print("[OK] Beacons")
