local directions = {
	["+X"] = {vector = {x= 1,y=0,z=0}, param2 = 12},
	["-X"] = {vector = {x=-1,y=0,z=0}, param2 = 16},
	["+Y"] = {vector = {x=0,y= 1,z=0}, param2 = 0},
	["-Y"] = {vector = {x=0,y=-1,z=0}, param2 = 20},
	["+Z"] = {vector = {x=0,y=0,z= 1}, param2 = 4 },
	["-Z"] = {vector = {x=0,y=0,z=-1}, param2 = 8 },
}

function beacon.dir_from_pointed(pointed_thing)
	local pointed_dir = vector.subtract(pointed_thing.above, pointed_thing.under)
	if pointed_dir.x ~= 0 then
		return pointed_dir.x > 0 and "+X" or "-X"
	elseif pointed_dir.y ~= 0 then
		return pointed_dir.y > 0 and "+Y" or "-Y"
	elseif pointed_dir.z ~= 0 then
		return pointed_dir.z > 0 and "+Z" or "-Z"
	end
	return "+Y" -- default to up
end

function beacon.dir_from_param2(param2)
	param2 = type(param2) == "number" and param2-(param2%4) or 0
	for dir,values in pairs(directions) do
		if values.param2 == param2 then
			return dir
		end
	end
	return "+Y" -- default to up
end

function beacon.get_node(pos)
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		minetest.get_voxel_manip():read_from_map(pos, pos)
		node = minetest.get_node(pos)
	end
	return node
end

local function can_place(pos, name)
	if not minetest.is_protected(pos, name) then
		local node = beacon.get_node(pos)
		if node then
			local def = minetest.registered_nodes[node.name]
			if beacon.config.beam_break_nodes or (def and def.drawtype == "airlike") then
				return true
			end
		end
	end
	return false
end

function beacon.allow_change(pos, player)
	if minetest.is_protected(pos, player:get_player_name()) then return false end
	if minetest.get_meta(pos):get_string("active") == "true" then return false end
	return true
end

function beacon.set_default_meta(pos)
	local meta = minetest.get_meta(pos)
	meta:set_int("range", beacon.config.effect_range_0)
	meta:set_string("effect", beacon.config.default_effect)
	meta:set_string("active", "false")
	meta:get_inventory():set_size("beacon_upgrades", 4)
end

function beacon.on_place(itemstack, placer, pointed_thing)
	-- check for correct pointed_thing
	if not pointed_thing or not pointed_thing.above or not pointed_thing.under or pointed_thing.type ~= "node" then
		return itemstack, false
	end
	-- place beacon
	local dir = beacon.dir_from_pointed(pointed_thing)
	return minetest.item_place(itemstack, placer, pointed_thing, directions[dir].param2)
end

function beacon.place_beam(pos, player_name, dir)
	local node_name = minetest.get_node(pos).name
	-- place base
	pos = vector.add(pos, directions[dir].vector)
	if not can_place(pos, player_name) then return end
	minetest.add_node(pos, {
		name = node_name.."base",
		param2 = directions[dir].param2
	})
	-- place beam
	for _=1, beacon.config.beam_length - 1 do
		pos = vector.add(pos, directions[dir].vector)
		if not can_place(pos, player_name) then
			break -- stop placing beam
		else
			minetest.add_node(pos, {
				name = node_name.."beam",
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
		local node = beacon.get_node(pos)
		if node and minetest.get_item_group(node.name, "beacon_beam") == 1 then
			minetest.set_node(pos, {name = "air"})
		else
			break -- end of beam
		end
	end
end

function beacon.activate(pos, player_name)
	local node = minetest.get_node(pos)
	local dir = beacon.dir_from_param2(node.param2)
	if not can_place(vector.add(pos, directions[dir].vector), player_name) then
		minetest.chat_send_player(player_name, "Not enough room to activate beacon pointing in "..dir.." direction!")
		return
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("beam_dir", dir)
	meta:set_string("active", "true")
	minetest.get_node_timer(pos):start(beacon.config.effect_refresh_time)
	minetest.sound_play("beacon_power_up", {
		gain = 2.0,
		pos = pos,
		max_hear_distance = 32,
	})
	beacon.place_beam(pos, player_name, dir)
end

function beacon.deactivate(pos)
	local meta = minetest.get_meta(pos)
	local timer = minetest.get_node_timer(pos)
	meta:set_string("active", "false")
	timer:stop()
	minetest.sound_play("beacon_power_down", {
		gain = 2.0,
		pos = pos,
		max_hear_distance = 32,
	})
	beacon.remove_beam(pos)
end

function beacon.update(pos, color)
	local meta = minetest.get_meta(pos)
	local effect = meta:get_string("effect")
	if effect ~= "none" then
		-- set effect for each player in range of the beacon
		local range = meta:get_int("range")
		if range and range > 0 then
			for _,player in ipairs(minetest.get_connected_players()) do
				local name = player:get_player_name()
				local offset = vector.subtract(player:get_pos(), pos)
				local distance = math.max(math.abs(offset.x), math.abs(offset.y), math.abs(offset.z))
				if distance <= range + 0.5 and beacon.effects[effect] then
					if not beacon.player_effects[name] then
						beacon.player_effects[name] = {}
					end
					beacon.player_effects[name].avalible[effect] = beacon.config.effect_refresh_time
				end
			end
		end
	end
	-- spawn active beacon particles
	local dir = meta:get_string("beam_dir")
	if dir and directions[dir] then
		pos = vector.add(pos, directions[dir].vector)
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
