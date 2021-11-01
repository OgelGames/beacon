
local active_beacons = {}
local forget_time = beacon.config.cache_time

local function get_beacon_info(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("active") ~= "true" then
		return -- not active
	end
	local range = meta:get_int("range")
	if range < 1 then
		return -- zero range
	end
	local effect = meta:get_string("effect")
	if not beacon.effects[effect] then
		return -- no effect
	end
	return {
		effect = effect,
		range = range + 0.5, -- 0.5 to reach node edge
		owner = meta:get_string("owner"),
		pos = pos,
		timer = 0,
	}
end

function beacon.mark_active(pos)
	local spos = pos.x..","..pos.y..",".. pos.z
	active_beacons[spos] = get_beacon_info(pos)
end

function beacon.mark_inactive(pos)
	local spos = pos.x..","..pos.y..",".. pos.z
	active_beacons[spos] = nil
end

function beacon.check_beacon(pos)
	local spos = pos.x..","..pos.y..",".. pos.z
	local info = get_beacon_info(pos)
	if info then
		active_beacons[spos] = info
		return true
	end
	active_beacons[spos] = nil
	return false
end

local function within_range(a, b, range)
	return b.x <= a.x + range and
		   b.x >= a.x - range and
		   b.y <= a.y + range and
		   b.y >= a.y - range and
		   b.z <= a.z + range and
		   b.z >= a.z - range
end

local function update_beacons(players)
	-- get player positions
	local player_positions = {}
	for _,player in pairs(players) do
		player_positions[player:get_player_name()] = player:get_pos()
	end
	-- clear old beacons
	for name in pairs(player_positions) do
		if not beacon.players[name] then
			beacon.players[name] = {beacons = {}, effects = {}}
		else
			beacon.players[name].beacons = {}
		end
	end
	-- check active beacons
	for spos,info in pairs(active_beacons) do
		local loaded = minetest.get_node_or_nil(info.pos)
		local in_range = false
		if info.timer >= 5 and loaded then
			-- loaded but not updated by node timer, check it
			info = get_beacon_info(info.pos)
			active_beacons[spos] = info
		else
			info.timer = info.timer + 1
		end
		if info then
			-- add to player beacons
			for name,player_pos in pairs(player_positions) do
				if within_range(info.pos, player_pos, info.range) then
					beacon.players[name].beacons[spos] = {
						effect = info.effect,
						owner = info.owner,
						pos = info.pos
					}
					in_range = true
				end
			end
			if not loaded and in_range then
				info.timer = 0
			elseif info.timer > forget_time then
				-- unloaded and out of range too long, remove it
				active_beacons[spos] = nil
			end
		end
	end
end

local function get_useable_effects(name, pos)
	local effects = {}
	-- check each of the nearby beacons
	for _,info in pairs(beacon.players[name].beacons) do
		if not effects[info.effect] then
			if info.owner == "" or beacon.can_effect(pos, info.owner) then
				effects[info.effect] = true
			end
		end
	end
	-- clear any overridden effects
	for effect in pairs(effects) do
		if beacon.effects[effect].overrides then
			for _,override in pairs(beacon.effects[effect].overrides) do
				effects[override] = nil
			end
		end
	end
	return effects
end

local function get_all_effect_ids(effects1, effects2)
	local effect_ids = {}
	for id in pairs(effects1) do
		effect_ids[id] = true
	end
	for id in pairs(effects2) do
		effect_ids[id] = true
	end
	return effect_ids
end

local timer = 0

minetest.register_globalstep(function(dtime)
	-- update the timer
	timer = timer + dtime
	if timer < 1 then return end
	timer = 0
	-- update effects for all players
	local players = minetest.get_connected_players()
	update_beacons(players)
	for _,player in pairs(players) do
		local name = player:get_player_name()
		local useable = get_useable_effects(name, player:get_pos())
		local active = beacon.players[name].effects
		-- check the player's effects
		for id in pairs(get_all_effect_ids(active, useable)) do
			-- remove effect
			if active[id] and not useable[id] then
				active[id] = nil
				if beacon.effects[id].on_remove then
					beacon.effects[id].on_remove(player, name)
				end
			-- add effect
			elseif useable[id] and not active[id] then
				active[id] = true
				if beacon.effects[id].on_apply then
					beacon.effects[id].on_apply(player, name)
				end
			-- update effect
			else
				if beacon.effects[id].on_step then
					beacon.effects[id].on_step(player, name)
				end
			end
		end
		beacon.players[name].effects = active
	end
end)

minetest.register_on_joinplayer(function(player)
	beacon.players[player:get_player_name()] = {beacons = {}, effects = {}}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if not beacon.players[name] then return end
	for id in pairs(beacon.players[name].effects) do
		-- remove all effects before leaving
		if beacon.effects[id].on_remove then
			beacon.effects[id].on_remove(player, name)
		end
	end
	beacon.players[name] = nil
end)
