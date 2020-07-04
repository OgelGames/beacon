
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
