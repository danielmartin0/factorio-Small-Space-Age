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
	if settings.global["smallspage-indestructible-enemy-bases"].value then -- If false, don't mess with map gen at all
		local spawners = event.surface.find_entities_filtered({ area = event.area, type = "unit-spawner" })

		set_destructibility(spawners)
	end
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

local function is_position_out_of_bounds(position, radius)
	-- Check if position is outside the radius
	local distance_squared = position.x * position.x + position.y * position.y
	return distance_squared > radius * radius
end

local function is_demolisher(entity)
	-- Check if entity is a demolisher
	return entity.name:find("demolisher") ~= nil
end

local function is_demolisher_by_name(entity_name)
	-- Check if entity name indicates it's a demolisher
	return entity_name:find("demolisher") ~= nil
end

local function get_planet_radius(surface_name)
	return prototypes.mod_data["Small-Space-Age"].data.radius_settings.overrides[surface_name]
		or prototypes.mod_data["Small-Space-Age"].data.radius_settings.default
end

local function try_scan_planet_chunks(surface, force, print)
	-- Check if auto-scan is enabled
	if not settings.global["smallspage-auto-scan-planets"].value then
		return
	end

	if not surface.planet then
		return
	end

	if print then
		game.print("[SMALL SPACE AGE]: Scanning planet: " .. surface.planet.name)
	end

	local radius = get_planet_radius(surface.planet.name)
	local chunk_size = 32 -- Factorio chunk size is 32x32 tiles

	-- Calculate the chunk radius (planet radius + 1 chunk border)
	local chunk_radius = math.ceil(radius / chunk_size) + 1

	-- Scan all chunks within the radius
	for x = -chunk_radius, chunk_radius do
		for y = -chunk_radius, chunk_radius do
			local chunk_center_x = x * chunk_size + chunk_size / 2
			local chunk_center_y = y * chunk_size + chunk_size / 2
			local distance_squared = chunk_center_x * chunk_center_x + chunk_center_y * chunk_center_y

			-- Only scan chunks that are within or just outside the planet radius
			if distance_squared <= (radius + chunk_size) * (radius + chunk_size) then
				force.chart(
					surface,
					{ { x * chunk_size, y * chunk_size }, { (x + 1) * chunk_size, (y + 1) * chunk_size } }
				)
			end
		end
	end
end

local function remove_out_of_bounds_demolishers(surface)
	if not surface or not surface.valid then
		return
	end

	local radius = get_planet_radius(surface.name)
	local removed_count = 0

	-- Find all segmented units (demolishers) on the surface
	local entities = surface.find_entities_filtered({
		type = "segmented-unit",
	})

	for _, entity in pairs(entities) do
		if entity.valid and is_demolisher(entity) then
			if is_position_out_of_bounds(entity.position, radius) then
				-- Check if the entity is on an out-of-map tile
				local tile = surface.get_tile(entity.position)
				if tile.name:find("smallspage-out-of-map") or tile.name == "out-of-map" then
					entity.destroy()
					removed_count = removed_count + 1
				end
			end
		end
	end
end

-- Event handler for when segmented units (demolishers) are created
local function on_segmented_unit_created(event)
	local entity = event.segmented_unit
	if not entity or not entity.valid then
		return
	end

	-- Use prototype.name for segmented units
	local entity_name = entity.prototype.name
	local body_nodes = entity.get_body_nodes()
	local front_position = body_nodes[1] -- First node is the front/head position

	-- Only check demolishers on surfaces with planets
	local surface = entity.surface
	if not surface or not surface.planet then
		return
	end

	-- Check if this is a demolisher
	if is_demolisher_by_name(entity_name) then
		local radius = get_planet_radius(surface.name)

		-- Check if it's outside the radius using front position
		if is_position_out_of_bounds(front_position, radius) then
			-- Remove the demolisher since it's outside radius
			entity.destroy()
		end
	end
end

-- Event handler for periodic cleanup (every 60 seconds)
local function on_nth_tick_cleanup(event)
	-- Clean up any demolishers that might have been missed
	for _, surface in pairs(game.surfaces) do
		if surface.planet and surface.planet.name then
			local planet_name = surface.planet.name
			-- Only run cleanup on planets with custom radii
			if prototypes.mod_data["Small-Space-Age"].data.radius_settings.overrides[planet_name] then
				remove_out_of_bounds_demolishers(surface)
			end
		end
	end
end

-- Register event handlers
script.on_event(defines.events.on_segmented_unit_created, on_segmented_unit_created)
script.on_event(defines.events.on_entity_spawned, on_segmented_unit_created)

-- Periodic cleanup every 60 seconds (3600 ticks)
script.on_nth_tick(3600, on_nth_tick_cleanup)

-- Initial cleanup when mod is loaded/player joins
script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.get_player(event.player_index)
	if player and player.surface then
		remove_out_of_bounds_demolishers(player.surface)
		-- Scan the planet if auto-scan is enabled
		try_scan_planet_chunks(player.surface, player.force)
	end
end)

-- Cleanup when any mod changes
script.on_configuration_changed(function()
	for _, surface in pairs(game.surfaces) do
		if surface.planet and surface.planet.name then
			remove_out_of_bounds_demolishers(surface)
		end
	end
end)

-- Scan planet when player changes surface
script.on_event(defines.events.on_player_changed_surface, function(event)
	local player = game.get_player(event.player_index)
	if player and player.surface then
		-- Scan the new planet if auto-scan is enabled
		try_scan_planet_chunks(player.surface, player.force)
	end
end)

commands.add_command("scan-planet", "Scan and reveal the entire current planet", function(command)
	local player = game.get_player(command.player_index)
	if player and player.surface then
		if player.surface.planet then
			try_scan_planet_chunks(player.surface, player.force, true)
		else
			player.print("[SMALL SPACE AGE]: Not on a planet surface!")
		end
	end
end)
