
local function get_useable_effects(name)
	local useable_effects = beacon.player_effects[name].avalible
	-- check all the effects granted by nearby beacons
	for effect,timer in pairs(beacon.player_effects[name].avalible) do
		if timer < 0 then
			-- remove the expired effect
			beacon.player_effects[name].avalible[effect] = nil
			useable_effects[effect] = nil
		else
			if type(beacon.effects[effect].overrides) == "table" then
				-- remove the effects overridden by the effect
				for _,override in ipairs(beacon.effects[effect].overrides) do
					useable_effects[override] = nil
				end
			end
			-- update the timer
			beacon.player_effects[name].avalible[effect] = timer - 1
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
			local useable = get_useable_effects(name)
			local active = beacon.player_effects[name].active
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
			beacon.player_effects[name].active = active
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	beacon.player_effects[player:get_player_name()] = {avalible = {}, active = {}}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	for id,_ in pairs(beacon.player_effects[name].active) do
		-- remove all effects before leaving
		beacon.effects[id].on_remove(player, name)
	end
	beacon.player_effects[name] = nil
end)
