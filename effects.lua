local function get_useable_effects(name, pos)
	local useable_effects = {}
	-- check each of the nearby beacons
	for spos,beacon_pos in pairs(beacon.players[name].beacons) do
		local useable = false
		local meta = minetest.get_meta(beacon_pos)
		local active = meta:get_string("active")
		local range = meta:get_int("range")
		if active == "true" and range > 0 then
			local offset = vector.subtract(pos, beacon_pos)
			local distance = math.max(math.abs(offset.x), math.abs(offset.y), math.abs(offset.z))
			if distance <= range + 0.5 then
				local effect = meta:get_string("effect")
				if effect ~= "" and effect ~= "none" and beacon.effects[effect] then
					local owner = meta:get_string("owner")
					if owner == "" or beacon.can_effect(pos, owner) then
						useable_effects[effect] = true
						useable = true
					end
				end
			end
		end
		if not useable then
			beacon.players[name].beacons[spos] = nil
		end
	end
	-- check all the effects granted by in-range beacons
	for effect,_ in pairs(useable_effects) do
		if type(beacon.effects[effect].overrides) == "table" then
			-- remove the effects overridden by the effect
			for _,override in ipairs(beacon.effects[effect].overrides) do
				useable_effects[override] = nil
			end
		end
	end
	return useable_effects
end

local function get_all_effect_ids(effects1, effects2)
	local effect_ids = {}
	for id,_ in pairs(effects1) do
		effect_ids[id] = true
	end
	for id,_ in pairs(effects2) do
		effect_ids[id] = true
	end
	return effect_ids
end

local timer = 0

minetest.register_globalstep(function(dtime)
	-- update the timer
	timer = timer + dtime
	if (timer >= 1) then
		timer = 0
		-- loop through all the players
		local players = minetest.get_connected_players()
		for _,player in ipairs(players) do
			local name = player:get_player_name()
			if beacon.players[name] then
				local useable = get_useable_effects(name, player:get_pos())
				local active = beacon.players[name].effects
				-- check the player's effects
				for id,_ in pairs(get_all_effect_ids(active, useable)) do
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
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	beacon.players[player:get_player_name()] = {beacons = {}, effects = {}}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if not beacon.players[name] then return end
	for id,_ in pairs(beacon.players[name].effects) do
		-- remove all effects before leaving
		if beacon.effects[id].on_remove then
			beacon.effects[id].on_remove(player, name)
		end
	end
	beacon.players[name] = nil
end)
