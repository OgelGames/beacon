
local shown_formspecs = {}

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

function beacon.show_formspec(pos, name)
	local meta = minetest.get_meta(pos)
	if not meta:get_inventory():get_lists().beacon_upgrades then
		shown_formspecs[name] = nil
		return
	end
	local spos = pos.x..","..pos.y..",".. pos.z
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
		"size[8,7.5]" ..
		"label[0,0;Beacon Effect]"..
		"textlist[0,0.5;3.5,2.475;effects;"..effects_string..";"..index.."]"..
		"label[4,0;Upgrades]"..
		"list[nodemeta:"..spos..";beacon_upgrades;4,0.5;4,1;]"..
		"listring[nodemeta:"..spos..";beacon_upgrades]"..
		"label[4,1.8;Effect Radius (1-"..max_range..")]"..
		"field[4.3,2.5;2,1;range;;"..set_range.."]"..
		"list[current_player;main;0,3.75;8,4;]"..
		"listring[current_player;main]"

	if meta:get_string("active") == "true" then
		minetest.show_formspec(name, "beacon_activated_formspec",
			formspec.."button_exit[6,2.175;2,1;deactivate;Deactivate Beacon]")
	else
		minetest.show_formspec(name, "beacon_deactivated_formspec",
			formspec.."button_exit[6,2.175;2,1;activate;Activate Beacon]")
	end
	shown_formspecs[name] = {list = effects_list, pos = pos}
end

function beacon.showing_formspec(pos)
	for _,data in pairs(shown_formspecs) do
		if vector.equals(data.pos, pos) then
			return true
		end
	end
	return false
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not player then return end
	local name = player:get_player_name()
	if not shown_formspecs[name] then return end
	local pos = shown_formspecs[name].pos
	if minetest.is_protected(pos, name) then return end
	local meta = minetest.get_meta(pos)

	if formname == "beacon_deactivated_formspec" then
		if meta:get_string("active") == "true" then return end

		-- set range
		local level = get_beacon_level(pos)
		meta:set_int("range", limit_range(fields.range, level))

		-- set effect
		local effect = meta:get_string("effect")
		local event = minetest.explode_textlist_event(fields.effects)
		if event.type == "CHG" then
			effect = shown_formspecs[name].list[event.index] or effect
		end
		if effect ~= "none" then
			local def = beacon.effects[effect]
			if not def or def.min_level > level then
				effect = "none"
			end
		end
		meta:set_string("effect", effect)

		-- activate beacon
		if fields.activate then
			beacon.activate(pos, name)
		end

		-- check if formspec should be shown again
		if fields.quit then
			shown_formspecs[name] = nil
		else
			beacon.show_formspec(pos, name)
		end
		return true

	elseif formname == "beacon_activated_formspec" then
		if meta:get_string("active") ~= "true" then return end

		-- deactivate beacon
		if fields.deactivate then
			beacon.deactivate(pos)
		end

		-- check if formspec should be shown again
		if fields.quit then
			shown_formspecs[name] = nil
		else
			beacon.show_formspec(pos, name)
		end
		return true
	end
end)

minetest.register_on_leaveplayer(function(player)
	shown_formspecs[player:get_player_name()] = nil
end)

minetest.register_on_dieplayer(function(player)
	shown_formspecs[player:get_player_name()] = nil
end)
