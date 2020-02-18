--[[
beacon.register_effect("id_name", {
	desc_name = "Name",
	min_level = 0,
	overrides = {},
	on_apply = function(player, name) end,
	on_step = function(player, name) end,
	on_remove = function(player, name) end,
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
	beacon.effects[name] = nil
	beacon.register_effect(name, def)
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
