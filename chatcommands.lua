
local function get_player_defs(name)
	local defs = {}
	for id,_ in pairs(beacon.player_effects[name].active) do
		table.insert(defs, beacon.effects[id])
	end
	return defs
end

minetest.register_chatcommand("beacon_effects", {
	params = "all/me/all_info/me_info",
	description = "Get a list of either all, or only your active effects, with or without extra information",
	func = function(name, param)
		if param == "all" then
			local output = {"All avalible beacon effects:"}
			for _,def in pairs(beacon.effects) do
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
			for _,def in pairs(beacon.effects) do
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