
local function get_useable_effects(name)
	local useable_effects = {}
	-- check the avalible effects
	for effect,timer in pairs(beacon.player_effects[name].avalible) do
		if timer < 0 then
			-- remove the expired effect
			beacon.player_effects[name].avalible[effect] = nil
		else
			-- remove the effects overridden by the effect
			for _,override in ipairs(beacon.effects[effect].overrides) do
				useable_effects[override] = nil
			end
			-- add the effect
			useable_effects[effect] = true
			-- update the timer
			beacon.player_effects[name].avalible[effect] = timer - 1
		end
	end
	return useable_effects
end

local function get_all_effect_ids(tabs)
	local effect_ids = {}
	for _,tab in ipairs(tabs) do
		for id,_ in pairs(tab) do
			effect_ids[id] = true
		end
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
			for id,_ in pairs(get_all_effect_ids({active, useable})) do
				-- remove effect
				if active[id] and not useable[id] then
					beacon.effects[id].on_remove(player)
					active[id] = nil
				-- add effect
				elseif useable[id] and not active[id] then
					beacon.effects[id].on_apply(player)
					active[id] = true
				-- update effect
				else
					beacon.effects[id].on_step(player)
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
	beacon.player_effects[player:get_player_name()] = nil
end)



-- basic effects for testing
--------------------------------------------------

beacon.register_effect("fly", {
	desc_name = "Fly",
	min_level = 0,
	overrides = {},
	on_apply = function(player)
		player_monoids.fly:add_change(player, true, "beacon_fly")
	end,
	on_step = function(player) end,
	on_remove = function(player)
		player_monoids.fly:del_change(player, "beacon_fly")
	end,
})

beacon.register_effect("jump1", {
	desc_name = "Jump Boost",
	min_level = 1,
	overrides = {},
	on_apply = function(player)
		player_monoids.jump:add_change(player, 1.5, "beacon_jump1")
	end,
	on_step = function(player) end,
	on_remove = function(player)
		player_monoids.jump:del_change(player, "beacon_jump1")
	end,
})

beacon.register_effect("jump2", {
	desc_name = "Jump Boost LV2",
	min_level = 1,
	overrides = {"jump1"},
	on_apply = function(player)
		player_monoids.jump:add_change(player, 2, "beacon_jump2")
	end,
	on_step = function(player) end,
	on_remove = function(player)
		player_monoids.jump:del_change(player, "beacon_jump2")
	end,
})

beacon.register_effect("speed1", {
	desc_name = "Speed Boost",
	min_level = 2,
	overrides = {},
	on_apply = function(player)
		player_monoids.speed:add_change(player, 2, "beacon_speed1")
	end,
	on_step = function(player) end,
	on_remove = function(player)
		player_monoids.speed:del_change(player, "beacon_speed1")
	end,
})

beacon.register_effect("speed2", {
	desc_name = "Speed Boost LV2",
	min_level = 3,
	overrides = {"speed1"},
	on_apply = function(player)
		player_monoids.speed:add_change(player, 4, "beacon_speed2")
	end,
	on_step = function(player) end,
	on_remove = function(player)
		player_monoids.speed:del_change(player, "beacon_speed2")
	end,
})
