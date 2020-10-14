
function beacon.get_node(pos)
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		minetest.get_voxel_manip():read_from_map(pos, pos)
		node = minetest.get_node(pos)
	end
	return node
end

function beacon.is_airlike_node(pos)
	local node = beacon.get_node(pos)
	if node.name == "ignore" then return false end
	if node.name == "air" or node.name == "vacuum:vacuum" then return true end
	local def = minetest.registered_nodes[node.name]
	if def and def.drawtype == "airlike" and def.buildable_to then return true end
	return false
end

function beacon.set_default_meta(pos, player_name)
	local meta = minetest.get_meta(pos)
	meta:set_int("range", beacon.config.effect_range_0)
	meta:set_string("effect", beacon.config.default_effect)
	meta:set_string("active", "false")
	meta:set_string("channel", "beacon"..minetest.pos_to_string(pos))
	meta:get_inventory():set_size("beacon_upgrades", 4)
	meta:set_string("owner", player_name)
end

function beacon.get_level(pos)
	local inv = minetest.get_meta(pos):get_inventory()
	local level = 0
	for i = 1, inv:get_size("beacon_upgrades") do
		local stack = inv:get_stack("beacon_upgrades", i)
		if not stack:is_empty() and stack:get_name() == beacon.config.upgrade_item then
			level = level + 1
		end
	end
	return level
end

function beacon.get_effects_for_level(level)
	local names = {"None"}
	local ids = {"none"}
	for _,id in ipairs(beacon.sorted_effect_ids) do
		if beacon.effects[id].min_level <= level then
			table.insert(names, minetest.formspec_escape(beacon.effects[id].desc_name))
			table.insert(ids, id)
		end
	end
	return names, ids
end

function beacon.limit_range(range, level)
	local max_range = beacon.config["effect_range_"..level]
	range = tonumber(range)
	if not range then return max_range end
	range = math.min(range, max_range)
	range = math.max(range, 1)
	return range
end

function beacon.can_effect(pos, beacon_owner)
	if beacon.has_areas and beacon.config.area_shielding then
		return areas:canInteract(pos, beacon_owner)
	end
	return true
end
