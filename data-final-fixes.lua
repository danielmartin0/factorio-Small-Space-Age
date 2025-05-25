local lib = require("lib")
local merge = lib.merge

for _, resource in pairs(data.raw.resource) do
	resource.infinite = true
	resource.infinite_depletion_amount = 0
	if not (resource.minimum and resource.minimum > 0) then
		resource.minimum = 200
	end
	if not (resource.normal and resource.normal < 1000) then
		resource.normal = 1000
	end
end

data:extend({
	{ type = "noise-expression", name = "smallspage_D", expression = "300" },

	{ type = "noise-expression", name = "smallspage_y", expression = "y" },
	{ type = "noise-expression", name = "smallspage_x", expression = "x" },

	{ type = "noise-expression", name = "smallspage_xx", expression = "smallspage_x * smallspage_x" },
	{ type = "noise-expression", name = "smallspage_yy", expression = "smallspage_y * smallspage_y" },
	{ type = "noise-expression", name = "smallspage_r2", expression = "smallspage_xx + smallspage_yy" },
	{ type = "noise-expression", name = "smallspage_r", expression = "smallspage_r2 ^ 0.5" },
	{ type = "noise-expression", name = "smallspage_r_over_D", expression = "smallspage_r / smallspage_D" },
})

if settings.startup["smallspage-mode"].value == "spherical" then
	data:extend({
		{ type = "noise-expression", name = "smallspage_term_1", expression = "smallspage_r_over_D" },

		{ type = "noise-expression", name = "smallspage_term_2", expression = "smallspage_term_2b / 6" },
		{ type = "noise-expression", name = "smallspage_term_2b", expression = "smallspage_r_over_D ^ 3" },

		{ type = "noise-expression", name = "smallspage_term_3", expression = "smallspage_term_3b * 3" },
		{ type = "noise-expression", name = "smallspage_term_3b", expression = "smallspage_term_3c / 40" },
		{ type = "noise-expression", name = "smallspage_term_3c", expression = "smallspage_r_over_D ^ 5" },

		{ type = "noise-expression", name = "smallspage_term_4", expression = "smallspage_term_4b * 5" },
		{ type = "noise-expression", name = "smallspage_term_4b", expression = "smallspage_term_4c / 112" },
		{ type = "noise-expression", name = "smallspage_term_4c", expression = "smallspage_r_over_D ^ 7" },

		{
			type = "noise-expression",
			name = "smallspage_series",
			expression = "smallspage_term_1 + smallspage_series_b",
		},
		{
			type = "noise-expression",
			name = "smallspage_series_b",
			expression = "smallspage_term_2 + smallspage_series_c",
		},
		{
			type = "noise-expression",
			name = "smallspage_series_c",
			expression = "smallspage_term_3 + smallspage_term_4",
		},

		{ type = "noise-expression", name = "smallspage_spherical_x", expression = "smallspage_series * x" },
		{ type = "noise-expression", name = "smallspage_spherical_y", expression = "smallspage_series * y" },

		{
			type = "noise-expression",
			name = "smallspage_transformed_x",
			expression = "if(smallspage_r < smallspage_D, smallspage_spherical_x, x)",
		},
		{
			type = "noise-expression",
			name = "smallspage_transformed_y",
			expression = "if(smallspage_r < smallspage_D, smallspage_spherical_y, y)",
		},
	})
else
	data:extend({
		{ type = "noise-expression", name = "smallspage_one_plus_r", expression = "1 + smallspage_r_over_D" },
		{ type = "noise-expression", name = "smallspage_one_minus_r", expression = "1 - smallspage_r_over_D" },
		{
			type = "noise-expression",
			name = "smallspage_frac",
			expression = "smallspage_one_plus_r / smallspage_one_minus_r",
		},

		{ type = "noise-expression", name = "smallspage_factor", expression = "log2(smallspage_frac)" },

		{ type = "noise-expression", name = "smallspage_R", expression = "1.2" }, -- curvature radius
		{ type = "noise-expression", name = "smallspage_ln2", expression = "0.69314718" }, -- ln 2
		{ type = "noise-expression", name = "smallspage_R_ln2", expression = "smallspage_R * smallspage_ln2" },

		{
			type = "noise-expression",
			name = "smallspage_scale_before_D",
			expression = "smallspage_R_ln2 * smallspage_factor",
		},
		{
			type = "noise-expression",
			name = "smallspage_scale",
			expression = "smallspage_scale_before_D * smallspage_D",
		},

		{ type = "noise-expression", name = "smallspage_r_with_safety", expression = "smallspage_r + 0.0000001" },
		{ type = "noise-expression", name = "smallspage_inv_r", expression = "1 / smallspage_r_with_safety" },

		{
			type = "noise-expression",
			name = "smallspage_scale_over_r",
			expression = "smallspage_scale * smallspage_inv_r",
		},

		{ type = "noise-expression", name = "smallspage_hyperbolic_x", expression = "smallspage_scale_over_r * x" },
		{ type = "noise-expression", name = "smallspage_hyperbolic_y", expression = "smallspage_scale_over_r * y" },

		{
			type = "noise-expression",
			name = "smallspage_transformed_x",
			expression = "if(smallspage_r < smallspage_D, smallspage_hyperbolic_x, x)",
		},
		{
			type = "noise-expression",
			name = "smallspage_transformed_y",
			expression = "if(smallspage_r < smallspage_D, smallspage_hyperbolic_y, y)",
		},
	})
end

local function transform_noise_expression(v)
	-- Handle x/y at start of string
	v = v:gsub("^x([^%w_])", "smallspage_transformed_x%1")
	v = v:gsub("^y([^%w_])", "smallspage_transformed_y%1")
	-- Handle x/y after non-{ and non-, character
	v = v:gsub("([^,{]) x([^%w_])", "%1 smallspage_transformed_x%2")
	v = v:gsub("([^,{]) y([^%w_])", "%1 smallspage_transformed_y%2")
	-- Revert cases involving multiple spaces and then {
	v = v:gsub("({%s+)smallspage_transformed_x", "%1x")
	v = v:gsub("({%s+)smallspage_transformed_y", "%1y")
	-- Revert cases involving commas and then {
	v = v:gsub("(,%s*)smallspage_transformed_x", "%1x")
	v = v:gsub("(,%s*)smallspage_transformed_y", "%1y")
	-- Handle "(x, y,"
	v = v:gsub("%(x, y,", "(smallspage_transformed_x, smallspage_transformed_y,")
	return v
end

for _, prototype_type in pairs({ "noise-expression", "noise-function" }) do
	for _, prototype in pairs(data.raw[prototype_type]) do
		if prototype.expression and type(prototype.expression) == "string" then
			prototype.expression = transform_noise_expression(prototype.expression)
		end

		if prototype.local_expressions then
			for key, value in pairs(prototype.local_expressions) do
				if type(value) == "string" then
					prototype.local_expressions[key] = transform_noise_expression(value)
				end
			end
		end

		-- log(serpent.block(prototype))
	end
end

data:extend({
	merge(data.raw.tile["out-of-map"], {
		name = "smallspage-out-of-map",
		autoplace = { probability_expression = "if((x^2 + y^2)>smallspage_D^2,inf,-inf)" },
	}),
})

for _, planet in pairs(data.raw.planet) do
	planet.map_gen_settings.autoplace_settings.tile.settings["smallspage-out-of-map"] = {}
end
