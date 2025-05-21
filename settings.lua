data:extend({
	{
		type = "double-setting",
		name = "smallspage-radius",
		setting_type = "startup",
		default_value = 300,
		minimum_value = 20,
		maximum_value = 100000,
	},
	{
		type = "double-setting",
		name = "smallspage-indestructible-enemy-bases-radius",
		setting_type = "runtime-global",
		default_value = 160,
		minimum_value = 0,
		maximum_value = 100000,
	},
	{
		type = "bool-setting",
		name = "smallspage-indestructible-enemy-bases",
		setting_type = "runtime-global",
		default_value = true,
	},
})
