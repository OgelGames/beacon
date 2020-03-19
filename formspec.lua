
local base_formspec = ""

local function get_base_formspec()
	if base_formspec == "" then
		base_formspec =
			"size[8,8]" ..
			"label[0,0;Beacon Effect]"..
			"label[4,0;Upgrades]"..
			"list[context;beacon_upgrades;4,0.5;4,1;]"..
			"listring[context;beacon_upgrades]"..
			"list[current_player;main;0,4.25;8,4;]"..
			"listring[current_player;main]"..
			"item_image[4,0.5;1,1;"..beacon.config.upgrade_item.."]"..
			"item_image[5,0.5;1,1;"..beacon.config.upgrade_item.."]"..
			"item_image[6,0.5;1,1;"..beacon.config.upgrade_item.."]"..
			"item_image[7,0.5;1,1;"..beacon.config.upgrade_item.."]"..
			"button_exit[4,2.875;4,1;save;Save]"
	end
	return base_formspec
end

local function get_beacon_level(pos)
	local inv = minetest.get_meta(pos):get_inventory()
	local level = 0
	for i = 1, inv:get_size("beacon_upgrades") do
		local stack = inv:get_stack("beacon_upgrades", i)
		if not stack:is_empty() then
			level = level + 1
		end
	end
	return level
end

local function get_effects_for_level(level)
	local str = "None"
	local list = {"none"}
	for _,id in ipairs(beacon.sorted_effect_ids) do
		if beacon.effects[id].min_level <= level then
			str = str..","..minetest.formspec_escape(beacon.effects[id].desc_name)
			table.insert(list, id)
		end
	end
	return str, list
end

local function limit_range(range, level)
	if not level then return 0 end
	local max_range = beacon.config["effect_range_"..level]
	range = tonumber(range)
	if not range then return max_range end
	range = math.min(range, max_range)
	range = math.max(range, 1)
	return range
end

function beacon.update_formspec(pos)
	local meta = minetest.get_meta(pos)
	local level = get_beacon_level(pos)
	local effects_string, effects_list = get_effects_for_level(level)
	local max_range = beacon.config["effect_range_"..level]
	local set_range = meta:get_int("range")
	local effect = meta:get_string("effect")

	local index = 1
	for i=1, #effects_list do
		if effects_list[i] == effect then
			index = i
			break
		end
	end

	local formspec =
		get_base_formspec()..
		"textlist[0,0.5;3.8,2.225;effects;"..effects_string..";"..index.."]"..
		"label[4,1.55;Effect Radius (1-"..max_range..")]"..
		"field[4.285,2.25;4,1;range;;"..set_range.."]"

	if meta:get_string("active") == "true" then
		formspec = formspec.."button_exit[0,2.875;4,1;deactivate;Deactivate Beacon]"
	else
		formspec = formspec.."button_exit[0,2.875;4,1;activate;Activate Beacon]"
	end
	meta:set_string("formspec", formspec)
end

function beacon.receive_fields(pos, formname, fields, player)
	if not player then return end
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then return end
	local meta = minetest.get_meta(pos)
	local level = get_beacon_level(pos)

	if fields.range then
		meta:set_int("range", limit_range(fields.range, level))
	end

	local event = minetest.explode_textlist_event(fields.effects)
	if event.type == "CHG" then
		local _,effect_list = get_effects_for_level(level)
		local effect = effect_list[event.index] or "none"
		meta:set_string("effect", effect)
	end

	if fields.activate then
		beacon.activate(pos, name)
	elseif fields.deactivate then
		beacon.deactivate(pos)
	end

	beacon.update_formspec(pos)
end
