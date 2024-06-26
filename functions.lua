
function beacon.on_place(itemstack, placer, pointed_thing)
	-- Check for correct pointed_thing
	if not pointed_thing or not pointed_thing.above or not pointed_thing.under or pointed_thing.type ~= "node" then
		return itemstack, false
	end
	-- Calculate param2 direction from pointed_thing
	local param2 = 0
	local pointed_dir = vector.subtract(pointed_thing.above, pointed_thing.under)
	if pointed_dir.x ~= 0 then
		param2 = pointed_dir.x > 0 and 12 or 16
	elseif pointed_dir.y ~= 0 then
		param2 = pointed_dir.y > 0 and 0 or 20
	elseif pointed_dir.z ~= 0 then
		param2 = pointed_dir.z > 0 and 4 or 8
	end
	-- Place beacon
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

function beacon.place_beam(pos, player_name, dir)
	local node_name = minetest.get_node(pos).name
	local offset = beacon.dir_to_vector[dir]
	local param2 = beacon.dir_to_param2[dir]
	local can_break_nodes = beacon.config.beam_break_nodes
	-- Place base
	pos = vector.add(pos, offset)
	minetest.add_node(pos, {name = node_name.."base", param2 = param2})
	-- Place beam
	for _=1, beacon.config.beam_length - 1 do
		pos = vector.add(pos, offset)
		if minetest.is_protected(pos, player_name) then return end
		if not can_break_nodes then
			if not beacon.is_airlike_node(pos) then return end
		end
		minetest.add_node(pos, {name = node_name.."beam", param2 = param2})
	end
end

function beacon.remove_beam(pos)
	local dir = minetest.get_meta(pos):get_string("beam_dir")
	if not dir or not beacon.dir_to_vector[dir] then
		return  -- Invalid meta
	end
	local offset = beacon.dir_to_vector[dir]
	-- Remove beam (no need to remove beam base seperately)
	for _=1, beacon.config.beam_length do
		pos = vector.add(pos, offset)
		local node = beacon.get_node(pos)
		if minetest.get_item_group(node.name, "beacon_beam") ~= 1
				or beacon.param2_to_dir[node.param2 % 32 % 24] ~= dir then
			return  -- End of beam
		end
		minetest.set_node(pos, {name = "air"})
	end
end

function beacon.activate(pos, player_name)
	local dir = beacon.param2_to_dir[minetest.get_node(pos).param2 % 32 % 24]
	local pos1 = vector.add(pos, beacon.dir_to_vector[dir])
	if minetest.is_protected(pos1, player_name) or not beacon.is_airlike_node(pos1) then
		minetest.chat_send_player(player_name, "Not enough room to activate beacon pointing in "..dir.." direction!")
		return
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("beam_dir", dir)
	meta:set_string("active", "true")
	minetest.get_node_timer(pos):start(3)
	minetest.sound_play("beacon_power_up", {
		gain = 2.0,
		pos = pos,
		max_hear_distance = 32,
	})
	beacon.place_beam(pos, player_name, dir)
	beacon.mark_active(pos)
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
	beacon.mark_inactive(pos)
end

function beacon.update(pos)
	if not beacon.check_beacon(pos) then
		return true  -- No particles when not granting any effect
	end
	-- Spawn active beacon particles
	local dir = minetest.get_meta(pos):get_string("beam_dir")
	local colordef = beacon.colors[string.gsub(beacon.get_node(pos).name, "beacon:", "")]
	if dir and beacon.dir_to_vector[dir] and colordef and colordef.color then
		pos = vector.add(pos, beacon.dir_to_vector[dir])
		minetest.add_particlespawner({
			amount = 32,
			time = 3,
			minpos = {x=pos.x-0.25, y=pos.y-0.25, z=pos.z-0.25},
			maxpos = {x=pos.x+0.25, y=pos.y+0.25, z=pos.z+0.25},
			minvel = {x=-0.8, y=-0.8, z=-0.8},
			maxvel = {x=0.8, y=0.8, z=0.8},
			minacc = {x=0,y=0,z=0},
			maxacc = {x=0,y=0,z=0},
			minexptime = 0.5,
			maxexptime = 1,
			minsize = 1,
			maxsize = 2,
			texture = "beacon_particle.png^[multiply:"..colordef.color,
			glow = 14,
		})
	end
	return true
end
