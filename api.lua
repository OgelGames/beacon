
local function is_def_valid(def)
	if type(def) ~= "table" then
		return false
	end
	if (def.desc_name and type(def.desc_name) ~= "string")
			or (def.info and type(def.info) ~= "string")
			or (def.min_level and type(def.min_level) ~= "number")
			or (def.overrides and type(def.overrides) ~= "table")
			or (def.on_apply and type(def.on_apply) ~= "function")
			or (def.on_step and type(def.on_step) ~= "function")
			or (def.on_remove and type(def.on_remove) ~= "function") then
		return false
	end
	return true
end

function beacon.register_effect(name, def)
	if name == nil then
		minetest.log("warning", "[Beacon] Not registering effect, name is nil")
		return
	end
	if beacon.effects[name] then
		minetest.log("warning", "[Beacon] Not registering effect \""..name.."\", effect already exsists")
		return
	end
	if not is_def_valid(def) then
		minetest.log("warning", "[Beacon] Not registering effect \""..name.."\", definition is invalid")
		return
	end

	beacon.effects[name] = {
		desc_name = def.desc_name or "Unnamed Effect",
		info = def.info or "?",
		min_level = def.min_level or 0,
		overrides = def.overrides,
		on_apply = def.on_apply,
		on_step = def.on_step,
		on_remove = def.on_remove,
	}
end

function beacon.override_effect(name, redef)
	if name == nil then
		minetest.log("warning", "[Beacon] Not overriding effect, name is nil")
		return
	end
	if not beacon.effects[name] then
		minetest.log("warning", "[Beacon] Not overriding effect \""..name.."\", effect does not exsist")
		return
	end
	if not is_def_valid(redef) then
		minetest.log("warning", "[Beacon] Not overriding effect \""..name.."\", redefinition is invalid")
		return
	end
	local def = beacon.effects[name]
	for k, v in pairs(redef) do
		rawset(def, k, v)
	end
	beacon.effects[name] = nil
	beacon.register_effect(name, def)
end

function beacon.unregister_effect(name)
	if name == nil then
		minetest.log("warning", "[Beacon] Not unregistering effect, name is nil")
		return
	end
	if not beacon.effects[name] then
		minetest.log("warning", "[Beacon] Not unregistering effect \""..name.."\", effect does not exsist")
		return
	end
	beacon.effects[name] = nil
end

function beacon.register_color(name, colorstring, coloring_item)
	if type(name) ~= "string" or name == "" then
		minetest.log("warning", "[Beacon] Not registering color, name is invalid")
		return
	end
	if type(colorstring) ~= "string" or colorstring:sub(1, 1) ~= "#" then
		minetest.log("warning", "[Beacon] Not registering color, colorstring is invalid")
		return
	end

	local id = name:gsub("[%c%p%s]", ""):lower()
	if id == "" then
		minetest.log("warning", "[Beacon] Not registering color, name must contain alphanumeric characters")
		return
	end

	beacon.colors[id] = { desc = name, color = colorstring }

	-- beam
	minetest.register_node("beacon:"..id.."beam", {
		description = name.." Beacon Beam",
		tiles = {"beacon_beam.png^[multiply:"..colorstring},
		use_texture_alpha = "blend",
		inventory_image = "beacon_beam.png^[multiply:"..colorstring,
		groups = {beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beam.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		climbable = beacon.config.beam_climbable,
		selection_box = { type = "fixed", fixed = {0.125, 0.5, 0.125, -0.125, -0.5, -0.125} },
		on_place = beacon.on_place,
		on_rotate = false,  -- no rotation with screwdriver
	})

	-- beam base
	minetest.register_node("beacon:"..id.."base", {
		description = name.." Beacon Beam Base",
		tiles = {"beacon_beambase.png^[multiply:"..colorstring},
		use_texture_alpha = "blend",
		inventory_image = "beacon_beambase.png^[multiply:"..colorstring,
		groups = {beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beambase.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		climbable = beacon.config.beam_climbable,
		selection_box = { type = "fixed", fixed = {0.125, 0.5, 0.125, -0.125, -0.5, -0.125} },
		on_place = beacon.on_place,
		on_rotate = false,  -- no rotation with screwdriver
	})

	-- beacon node
	minetest.register_node("beacon:"..id, {
		description = name.." Beacon",
		tiles = {"(beacon_baseglow.png^[multiply:"..colorstring..")^beacon_base.png"},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, beacon = 1},
		drawtype = "normal",
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 13,
		on_place = beacon.on_place,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local player_name = placer and placer:get_player_name() or ""
			beacon.set_default_meta(pos, player_name)
			if not vector.equals(pointed_thing.above, pointed_thing.under) then
				beacon.activate(pos, player_name)
			end
			beacon.update_formspec(pos)
		end,
		on_timer = function(pos, elapsed)
			return beacon.update(pos)
		end,
		on_rotate = function(pos, node, user, mode, new_param2)
			if minetest.get_meta(pos):get_string("active") == "true" then
				return false
			end
			node.param2 = new_param2
			minetest.swap_node(pos, node)
			return true
		end,
		on_rightclick = beacon.update_formspec,
		on_receive_fields = beacon.receive_fields,
		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			if minetest.is_protected(pos, player:get_player_name())
					or not minetest.get_meta(pos):get_inventory():get_stack(to_list, to_index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) or stack:get_name() ~= beacon.config.upgrade_item
					or not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			return 1
		end,
		on_metadata_inventory_put = beacon.update_formspec,
		on_metadata_inventory_take = beacon.update_formspec,
		on_destruct = beacon.remove_beam,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			if oldmetadata.inventory and oldmetadata.inventory.beacon_upgrades then
				for _,item in ipairs(oldmetadata.inventory.beacon_upgrades) do
					local stack = ItemStack(item)
					if not stack:is_empty() then
						minetest.add_item(pos, stack)
					end
				end
			end
		end,
		digiline = {
			receptor = {},
			effector = {
				action = beacon.digiline_effector
			},
		},
	})

	-- coloring recipe
	if type(coloring_item) == "string" and coloring_item ~= "" and minetest.registered_items[coloring_item] then
		minetest.register_craft({
			type = "shapeless",
			output = "beacon:"..id,
			recipe = { "group:beacon", coloring_item },
		})
	end
end

