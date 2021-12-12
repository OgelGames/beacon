
-- Flying - grants "fly" privilage
--------------------------------------------------

local fly_affects_admins = beacon.config.fly_affects_admins

beacon.register_effect("fly", {
	desc_name = "Flying",
	info = "Temporarily grants the \"fly\" privilage",
	on_apply = function(player, name)
		local privs = minetest.get_player_privs(name)
		if privs.privs and not fly_affects_admins then
			return   -- Don't affect admins
		end

		if beacon.has_player_monoids then
			player_monoids.fly:add_change(player, true, "beacon_fly")
		else
			privs.fly = true
			minetest.set_player_privs(name, privs)
		end
	end,
	on_remove = function(player, name)
		local privs = minetest.get_player_privs(name)
		if privs.privs and not fly_affects_admins then
			return   -- Don't affect admins
		end

		if beacon.has_player_monoids then
			player_monoids.fly:del_change(player, "beacon_fly")
		else
			privs.fly = nil
			minetest.set_player_privs(name, privs)
		end
	end,
})
