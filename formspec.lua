
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
		if beacon.has_digilines then
			base_formspec = base_formspec..
			"field[4.285,2.25;2,1;range;;${range}]"..
			"label[6,1.55;Digiline Channel]"..
			"field[6.285,2.25;2,1;channel;;${channel}]"
		else
			base_formspec = base_formspec..
			"field[4.285,2.25;4,1;range;;${range}]"
		end
	end
	return base_formspec
end

function beacon.update_formspec(pos)
	local meta = minetest.get_meta(pos)
	local level = beacon.get_level(pos)
	local effect_names, effect_ids = beacon.get_effects_for_level(level)
	local max_range = beacon.config["effect_range_"..level]
	local effect = meta:get_string("effect")

	meta:set_int("range", beacon.limit_range(meta:get_int("range"), level))

	effect_names = table.concat(effect_names, ",")

	local index = 1
	for i=1, #effect_ids do
		if effect_ids[i] == effect then
			index = i
			break
		end
	end

	local formspec =
		get_base_formspec()..
		"textlist[0,0.5;3.8,2.225;effects;"..effect_names..";"..index.."]"..
		"label[4,1.55;Effect Radius (1-"..max_range..")]"

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
	local meta = minetest.get_meta(pos)
	if minetest.is_protected(pos, name) and name ~= meta:get_string("owner") then
		return
	end
	local level = beacon.get_level(pos)

	if fields.range then
		meta:set_int("range", beacon.limit_range(fields.range, level))
	end

	if fields.channel then
		meta:set_string("channel", fields.channel)
	end

	local event = minetest.explode_textlist_event(fields.effects)
	if event.type == "CHG" then
		local _,effect_list = beacon.get_effects_for_level(level)
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
