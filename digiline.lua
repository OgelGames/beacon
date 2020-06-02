
function beacon.digiline_effector(pos, _, channel, msg)
	if type(msg) ~= "table" then
		return
	end

	local meta = minetest.get_meta(pos)
	local set_channel = meta:get_string("channel")
	if channel ~= set_channel then
		return
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
