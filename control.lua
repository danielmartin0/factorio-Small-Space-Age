local function set_destructibility(spawners)
	for _, spawner in pairs(spawners) do
		local distance_from_center = math.sqrt(spawner.position.x ^ 2 + spawner.position.y ^ 2)
		if
			settings.global["smallspage-indestructible-enemy-bases"].value
			and distance_from_center > settings.global["smallspage-indestructible-enemy-bases-radius"].value
		then
			spawner.destructible = false
		else
			spawner.destructible = true
		end
	end
end

script.on_event(defines.events.on_chunk_generated, function(event)
	local spawners = event.surface.find_entities_filtered({ area = event.area, type = "unit-spawner" })

	set_destructibility(spawners)
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if
		event.setting_type == "runtime-global"
		and (
			event.setting == "smallspage-indestructible-enemy-bases"
			or event.setting == "smallspage-indestructible-enemy-bases-radius"
		)
	then
		for _, surface in pairs(game.surfaces) do
			local spawners = surface.find_entities_filtered({ type = "unit-spawner" })
			set_destructibility(spawners)
		end
	end
end)
