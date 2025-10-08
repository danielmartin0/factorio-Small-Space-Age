data:extend({
	{
		type = "mod-data",
		name = "Small-Space-Age",
		data = {
			radius_settings = {
				default = settings.startup["smallspage-radius"] and settings.startup["smallspage-radius"].value or 300,
				overrides = {
					["nauvis"] = settings.startup["smallspage-radius-nauvis"]
							and settings.startup["smallspage-radius-nauvis"].value
						or nil,
					["vulcanus"] = settings.startup["smallspage-radius-vulcanus"]
							and settings.startup["smallspage-radius-vulcanus"].value
						or nil,
					["fulgora"] = settings.startup["smallspage-radius-fulgora"]
							and settings.startup["smallspage-radius-fulgora"].value
						or nil,
					["gleba"] = settings.startup["smallspage-radius-gleba"]
							and settings.startup["smallspage-radius-gleba"].value
						or nil,
					["aquilo"] = settings.startup["smallspage-radius-aquilo"]
							and settings.startup["smallspage-radius-aquilo"].value
						or nil,
				},
			},
			hyperbolic_radius_settings = {
				default = 1,
				overrides = {
					["vulcanus"] = 1.2,
					["fulgora"] = 0.6,
					["gleba"] = 1.25,
					["aquilo"] = 0.6,
				},
			},
		},
	},
})
