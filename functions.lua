local directions = {
	["+X"] = {vector = {x= 1,y=0,z=0}, param2 = 12},
	["-X"] = {vector = {x=-1,y=0,z=0}, param2 = 16},
	["+Y"] = {vector = {x=0,y= 1,z=0}, param2 = 0},
	["-Y"] = {vector = {x=0,y=-1,z=0}, param2 = 20},
	["+Z"] = {vector = {x=0,y=0,z= 1}, param2 = 4 },
	["-Z"] = {vector = {x=0,y=0,z=-1}, param2 = 8 },
}

local function get_node(pos)
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		minetest.get_voxel_manip():read_from_map(pos, pos)
		node = minetest.get_node(pos)
	end
	return node
end

function can_place(pos, placer)
	if not minetest.is_protected(pos, placer:get_player_name()) then
		local node = get_node(pos)
		if node then
			local def = minetest.registered_nodes[node.name]
			if beacon.config.beam_break_nodes or (def and def.drawtype == "airlike") then
				return true
			end
		end
	end
	return false
end

local function get_dir(pointed_thing)
	local pointed_dir = vector.subtract(pointed_thing.above, pointed_thing.under)
	if pointed_dir.x ~= 0 then
		return pointed_dir.x > 0 and "+X" or "-X"
	elseif pointed_dir.y ~= 0 then
		return pointed_dir.y > 0 and "+Y" or "-Y"
	elseif pointed_dir.z ~= 0 then
		return pointed_dir.z > 0 and "+Z" or "-Z"
	end
	return "+Y" -- default to up if pointed_thing is invalid
end

function beacon.allow_change(pos, player)
	if minetest.is_protected(pos, player:get_player_name()) then return false end
	if minetest.get_meta(pos):get_string("active") == "true" then return false end
	return true
end

function beacon.set_default_meta(pos)
	local meta = minetest.get_meta(pos)
	meta:set_int("range", beacon.config.effect_range_0)
	meta:set_string("effect", "none")
	meta:set_string("active", "false")
	meta:get_inventory():set_size("beacon_upgrades", 4)
end

function beacon.place(itemstack, placer, pointed_thing)
	if not pointed_thing.above or not pointed_thing.under then return itemstack end
	local dir = get_dir(pointed_thing)
	local pos = vector.add(pointed_thing.above, directions[dir].vector)
	if not can_place(pos, placer) then
		minetest.chat_send_player(
			placer:get_player_name(),
			"Not enough room to place beacon pointing in "..dir.." direction!"
		)
		return itemstack
	end
	return minetest.item_place(itemstack, placer, pointed_thing)
end

function beacon.place_beam(pos, placer, pointed_thing, color)
	local dir = get_dir(pointed_thing)
	minetest.get_meta(pos):set_string("beam_dir", dir)

	-- place base
	pos = vector.add(pos, directions[dir].vector)
	if not can_place(pos, placer) then return end
	minetest.add_node(pos, {
		name = "beacon:"..color.."base",
		param2 = directions[dir].param2
	})

	-- place beam
	for _=1, beacon.config.beam_length - 1 do
		pos = vector.add(pos, directions[dir].vector)
		if not can_place(pos, placer) then
			break -- stop placing beam
		else
			minetest.add_node(pos, {
				name = "beacon:"..color.."beam",
				param2 = directions[dir].param2
			})
		end
	end
end

function beacon.remove_beam(pos)
	local dir = minetest.get_meta(pos):get_string("beam_dir")
	if not dir or not directions[dir] then
		return -- invalid meta
	end
	-- remove beam (no need to remove beam base seperately)
	for _=1, beacon.config.beam_length do
		pos = vector.add(pos, directions[dir].vector)
		local node = get_node(pos)
		if node and minetest.get_item_group(node.name, "beacon_beam") == 1 then
			minetest.set_node(pos, {name = "air"})
		else
			break -- end of beam
		end
	end
end

local function get_max_distance(pos1, pos2)
	local offset = vector.subtract(pos1, pos2)
	return math.max(math.abs(offset.x), math.abs(offset.y), math.abs(offset.z))
end

function beacon.update(pos, color)
	-- get beacon metadata
	local meta = minetest.get_meta(pos)
	local range = meta:get_int("range")
	local effect = meta:get_string("effect")
	local beam_dir = meta:get_string("beam_dir")
	if not effect or effect == "none" then
		return false -- stop node timer (inactive beacon)
	end

	-- set effect for each player in range of the beacon
	if range and range > 0 then
		for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local distance = get_max_distance(player:get_pos(), pos)
			if distance <= range and beacon.effects[effect] then
				if not beacon.player_effects[name] then
					beacon.player_effects[name] = {}
				end
				beacon.player_effects[name].avalible[effect] = beacon.config.effect_refresh_time
			end
		end
	end

	-- spawn active beacon particles
	if directions[beam_dir] and directions[beam_dir].vector then
		pos = vector.add(pos, directions[beam_dir].vector)
		minetest.add_particlespawner(
			32, --amount
			3, --time
			{x=pos.x-0.25, y=pos.y-0.25, z=pos.z-0.25}, --minpos
			{x=pos.x+0.25, y=pos.y+0.25, z=pos.z+0.25}, --maxpos
			{x=-0.8, y=-0.8, z=-0.8}, --minvel
			{x=0.8, y=0.8, z=0.8}, --maxvel
			{x=0,y=0,z=0}, --minacc
			{x=0,y=0,z=0}, --maxacc
			0.5, --minexptime
			1, --maxexptime
			1, --minsize
			2, --maxsize
			false, --collisiondetection
			"beacon_particle.png^[multiply:"..color --texture
		)
	end
	return true
end
