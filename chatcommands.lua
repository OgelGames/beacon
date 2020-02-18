
local function get_all_defs()
	local defs = {}
	for _,id in ipairs(beacon.sorted_effect_ids) do
		table.insert(defs, beacon.effects[id])
	end
	return defs
end

local function get_player_defs(name)
	local defs = {}
	for _,id in ipairs(beacon.sorted_effect_ids) do
		if beacon.player_effects[name].active[id] then
			table.insert(defs, beacon.effects[id])
		end
	end
	return defs
end

minetest.register_chatcommand("beacon_effects", {
	params = "all/me/all_info/me_info",
	description = "Get a list of either all, or only your active effects, with or without extra information",
	func = function(name, param)
		if param == "all" then
			local output = {"All avalible beacon effects:"}
			for _,def in ipairs(get_all_defs()) do
				table.insert(output, "- "..def.desc_name)
			end
			return true, table.concat(output, "\n")
		elseif param == "me" then
			local output = {"Your active effects:"}
			for _,def in ipairs(get_player_defs(name)) do
				table.insert(output, "- "..def.desc_name)
			end
			return true, table.concat(output, "\n")
		elseif param == "all_info" then
			local output = {"All avalible beacon effects:"}
			for _,def in ipairs(get_all_defs()) do
				table.insert(output, "- "..def.desc_name.." -- "..def.info)
			end
			return true, table.concat(output, "\n")
		elseif param == "me_info" then
			local output = {"Your active effects:"}
			for _,def in ipairs(get_player_defs(name)) do
				table.insert(output, "- "..def.desc_name.." -- "..def.info)
			end
			return true, table.concat(output, "\n")
		else
			return false, "Unknown subcommand: "..param
		end
	end,
})