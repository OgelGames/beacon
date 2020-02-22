
function beacon.get_node(pos)
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		minetest.get_voxel_manip():read_from_map(pos, pos)
		node = minetest.get_node(pos)
	end
	return node
end

function beacon.is_airlike_node(pos, name)
	local node = beacon.get_node(pos)
	if node.name == "air" or node.name == "vacuum:vacuum" then return true end
	local def = minetest.registered_nodes[node.name]
	if def and def.drawtype == "airlike" and def.buildable_to then return true end
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
	-- calculate param2 direction from pointed_thing
	local param2 = 0
	local pointed_dir = vector.subtract(pointed_thing.above, pointed_thing.under)
	if pointed_dir.x ~= 0 then
		param2 = pointed_dir.x > 0 and 12 or 16
	elseif pointed_dir.y ~= 0 then
		param2 = pointed_dir.y > 0 and 0 or 20
	elseif pointed_dir.z ~= 0 then
		param2 = pointed_dir.z > 0 and 4 or 8
	end
	-- place beacon
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

function beacon.place_beam(pos, player_name, dir)
	local node_name = minetest.get_node(pos).name
	local offset = beacon.dir_to_vector[dir]
	local param2 = beacon.dir_to_param2[dir]
	local can_break_nodes = beacon.config.beam_break_nodes
	-- place base
	pos = vector.add(pos, offset)
	minetest.add_node(pos, { name = node_name.."base", param2 = param2 })
	-- place beam
	for _=1, beacon.config.beam_length - 1 do
		pos = vector.add(pos, offset)
		if minetest.is_protected(pos, player_name) then return end
		if not can_break_nodes then
			if not beacon.is_airlike_node(pos) then return end
		end
		minetest.add_node(pos, { name = node_name.."beam", param2 = param2 })
	end
end

function beacon.remove_beam(pos)
	local dir = minetest.get_meta(pos):get_string("beam_dir")
	if not dir or not beacon.dir_to_vector[dir] then
		return -- invalid meta
	end
	local offset = beacon.dir_to_vector[dir]
	-- remove beam (no need to remove beam base seperately)
	for _=1, beacon.config.beam_length do
		pos = vector.add(pos, offset)
		if minetest.get_item_group(beacon.get_node(pos).name, "beacon_beam") ~= 1 then
			break -- end of beam
		end
		minetest.set_node(pos, {name = "air"})
	end
end

function beacon.activate(pos, player_name)
	local dir = beacon.param2_to_dir[minetest.get_node(pos).param2]
	local pos1 = vector.add(pos, beacon.dir_to_vector[dir])
	if minetest.is_protected(pos1, player_name) or not beacon.is_airlike_node(pos1) then
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
	if dir and beacon.dir_to_vector[dir] then
		pos = vector.add(pos, beacon.dir_to_vector[dir])
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
