
local function msg_to_table(str)
	if str == "get" or str == "GET" then
		return {command = "get"}
	elseif str == "activate" or str == "enable" or str == "on" then
		return {command = "set", active = true}
	elseif str == "deactivate" or str == "disable" or str == "off" then
		return {command = "set", active = false}
	elseif beacon.effects[str] or str == "none" then
		return {command = "set", effect = str}
	elseif tonumber(str) then
		return {command = "set", range = tonumber(str)}
	end
	return {}
end

function beacon.digiline_effector(pos, _, channel, msg)

	local meta = minetest.get_meta(pos)
	local set_channel = meta:get_string("channel")
	if channel ~= set_channel then
		return
	end

	if type(msg) ~= "table" then
		if type(msg) == "string" then
			msg = msg_to_table(msg)
		else
			return
		end
	end

	if msg.command == "get" then
		digilines.receptor_send(pos, digilines.rules.default, set_channel, {
			radius = meta:get_int("range"),
			effect = meta:get_string("effect"),
			active = meta:get_string("active") == "true" and true or false,
		})

	elseif msg.command == "get_effects" then
		digilines.receptor_send(pos, digilines.rules.default, set_channel, beacon.sorted_effect_ids)

	elseif msg.command == "set" then
		local level = beacon.get_level(pos)

		if type(msg.effect) == "string" then
			if beacon.effects[msg.effect] and beacon.effects[msg.effect].min_level <= level then
				meta:set_string("effect", msg.effect)
			elseif msg.effect == "none" then
				meta:set_string("effect", "none")
			end
		end

		if type(msg.range) == "number" then
			meta:set_int("range", beacon.limit_range(msg.range, level))
		elseif type(msg.radius) == "number" then
			meta:set_int("range", beacon.limit_range(msg.radius, level))
		end

		if type(msg.active) == "boolean" then
			if msg.active and meta:get_string("active") == "false" then
				beacon.activate(pos, meta:get_string("owner"))
			elseif not msg.active and meta:get_string("active") == "true" then
				beacon.deactivate(pos)
			end
		end
	end
end
