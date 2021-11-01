
minetest.register_chatcommand("beacon_effects", {
	params = "[<player name>]",
	description = "Lists active effects on yourself or another player",
	func = function(caller, param)
		param = param:trim()
		local name = (param ~= "" and param or caller)
		if not minetest.get_player_by_name(name) or not beacon.players[name] then
			return false, "Player "..name.." does not exist or is not online."
		end
		local output = name == caller and {"Your active effects:"} or {name.."'s active effects:"}
		for _,id in ipairs(beacon.sorted_effect_ids) do
			if beacon.players[name].effects[id] then
				table.insert(output, "- "..beacon.effects[id].desc_name)
			end
		end
		return true, table.concat(output, "\n")
	end,
})

minetest.register_chatcommand("beacon_nearby", {
	params = "[<player name>]",
	description = "Lists all beacons granting effects to yourself or another player",
	func = function(caller, param)
		param = param:trim()
		local name = (param ~= "" and param or caller)
		if not minetest.get_player_by_name(name) or not beacon.players[name] then
			return false, "Player "..name.." does not exist or is not online."
		end
		local output = name == caller and {"Beacons near you:"} or {"Beacons near "..name..":"}
		for spos,info in pairs(beacon.players[name].beacons) do
			local node = beacon.get_node(info.pos)
			local def = minetest.registered_nodes[node.name]
			if def and def.description then
				local effect = beacon.effects[info.effect].desc_name
				table.insert(output, "- "..def.description.." @ "..spos.." - "..effect)
			end
		end
		return true, table.concat(output, "\n")
	end,
})

minetest.register_chatcommand("beacon_info", {
	description = "Lists all avalible beacon effects with their descriptions",
	func = function(caller)
		local output = {"All avalible beacon effects:"}
		for _,id in ipairs(beacon.sorted_effect_ids) do
			table.insert(output, "- "..beacon.effects[id].desc_name.." - "..beacon.effects[id].info)
		end
		return true, table.concat(output, "\n")
	end,
})
