--[[
beacon.register_effect("name", {
	desc_name = "Name",
	min_level = 0,
	overrides = {},
	on_apply = function(player) end,
	on_step = function(player) end,
	on_remove = function(player) end,
})
]]

function beacon.register_effect(name, def)
	if name == nil then
		return -- no name
	end
	if beacon.effects[name] then
		return -- effect already exists
	end
	if def == nil or next(def) == nil then
		return -- no definitions
	end
	beacon.effects[name] = {
		desc_name = def.desc_name or "",
		min_level = def.min_level or 0,
		overrides = def.overrides or {},
		on_apply = def.on_apply or function(player) end,
		on_step = def.on_step or function(player) end,
		on_remove = def.on_remove or function(player) end,
	}
end

function beacon.override_effect(name, redef)
	if name == nil then
		return -- no name
	end
	if not beacon.effects[name] then
		return -- effect doesn't exist
	end
	if redef == nil or next(redef) == nil then
		return -- no new definitions
	end
	local def = beacon.effects[name]
	for k, v in pairs(redef) do
		rawset(def, k, v)
	end
	beacon.effects[name] = def
end

function beacon.unregister_effect(name)
	if name == nil then
		return -- no name
	end
	if not beacon.effects[name] then
		return -- effect doesn't exist
	end
	beacon.effects[name] = nil
end
