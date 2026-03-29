return {
	debugPoly = false,

	maxPredefinedAmount = {
		["fill"] = 24,
		["step"] = 20,
		["prepare"] = 60,
		["labeling"] = 60,
	},

	vineZone = {
		{
			points = {
				vec3(-1888.0, 2097.0, 140.0),
				vec3(-1912.0, 2095.0, 140.0),
				vec3(-1922.0, 2085.0, 140.0),
				vec3(-1923.0, 2071.0, 140.0),
				vec3(-1910.0, 2054.0, 140.0),
				vec3(-1882.0, 2040.0, 140.0),
				vec3(-1867.0, 2039.0, 140.0),
				vec3(-1853.0, 2045.0, 140.0),
				vec3(-1845.0, 2055.0, 140.0),
				vec3(-1846.0, 2067.0, 140.0),
				vec3(-1857.0, 2089.0, 140.0),
				vec3(-1877.0, 2098.0, 140.0),
			},
			thickness = 14.0,
		},
	},

	harvest = {
		[1] = {
			label = "Raisins roses",
			color = "#d598ce",
			cooldown = 90,
			job = {
				active = false,
				name = "vineyard",
				grade = 3
			},
			harvestTime = 6, -- in seconds
			areasType = "pink",
			items = {
				{name = "rose_wine_grapes", count = {min = 10, max = 15}},
			}
		},
		[2] = {
			label = "Raisins blancs",
			color = "#ffffff",
			cooldown = 90,
			job = {
				active = false,
				name = "vineyard",
				grade = 3
			},
			harvestTime = 6, -- in seconds
			areasType = "white",
			items = {
				{name = "white_wine_grapes", count = {min = 10, max = 15}},
			}
		},
		[3] = {
			label = "Raisins rouges",
			color = "#d9635b",
			cooldown = 90,
			job = {
				active = false,
				name = "vineyard",
				grade = 3
			},
			harvestTime = 6, -- in seconds
			areasType = "red",
			items = {
				{name = "red_wine_grapes", count = {min = 10, max = 15}},
			}
		},
	},

	step = {
		duration = 2, -- in seconds
		job = {
			active = true,
			name = "vineyard",
			grade = 0
		},
		props = {
			model = "ng_proc_crate_04a",
			locations = {
				["step1"] = {spawn = vec4(-1870.35, 2087.74, 140.99, 233.99)},
				["step2"] = {spawn = vec4(-1865.80, 2084.94, 140.99, 227.63)},
				["step3"] = {spawn = vec4(-1862.44, 2082.41, 140.99, 230.89)},
				["step4"] = {spawn = vec4(-1882.77, 2092.93, 140.99, 258.87)},
				["step5"] = {spawn = vec4(-1886.99, 2093.71, 140.99, 255.89)},
				["step6"] = {spawn = vec4(-1891.45, 2094.21, 140.99, 265.99)}
			}
		},
		types = {
			{
				required = {
					{name = "white_wine_prepared", count = 5, remove = true},
				},
				add = {
					{name = "white_wine_juice", count = 2}
				},
				propName = "wine_grapes_white",
				particles = "water_splash_ped_wade",
			},
			{
				required = {
					{name = "red_wine_prepared", count = 5, remove = true},
				},
				add = {
					{name = "red_wine_juice", count = 2}
				},
				propName = "wine_grapes",
				particles = "trail_splash_oil",
			},
			{
				required = {
					{name = "rose_wine_prepared", count = 5, remove = true},
				},
				add = {
					{name = "rose_wine_juice", count = 2}
				},
				propName = "wine_grapes_pink",
                particles = "trail_splash_blood",
			}
		}
	},

	prepare = {
		duration = 1, -- in seconds
		job = {
			active = false,
			name = "vineyard",
			grade = 0
		},
		animation = {
			dict = 'mp_arresting',
			clip = 'a_uncuff'
		},
		props = {
			table = {
				model = "prop_table_04",
				locations = {
					["prepare1"] = {spawn = vec4(-1862.671, 2068.859, 140.00, 359.86), player = vec4(-1862.67, 2069.71, 140.00, 176.40)},
					["prepare2"] = {spawn = vec4(-1865.082, 2068.863, 140.00, 359.86), player = vec4(-1865.11, 2069.66, 140.01, 176.34)},
					["prepare3"] = {spawn = vec4(-1867.680, 2068.867, 140.00, 359.86), player = vec4(-1867.78, 2069.63, 140.01, 182.68)},
					["prepare4"] = {spawn = vec4(-1870.232, 2068.874, 140.00, 359.86), player = vec4(-1870.37, 2069.67, 140.01, 185.30)}
				}
			},
			box = {
				model = "v_ind_cf_crate2",
				offset = vec3(0.61, 0.0, 0.0)
			}
		},
		types = {
			{
				required = {
					{name = "white_wine_grapes", count = 1, remove = true},
				},
				add = {
					{name = "white_wine_prepared", count = 1}
				},
				propsTable = {
					{
						prop = "wine_grape_white",
						bone = 18905,
						pos = vec3(0.159, 0.018, 0.02),
						rot = vec3(-45.20, -82.39, 37.13)
					},
					{
						prop = "prop_cs_scissors",
						bone = 57005,
						pos = vec3(0.083, 0.020, -0.02),
						rot = vec3(0.0, 0.0, 0.0)
					}
				}
			},
			{
				required = {
					{name = "red_wine_grapes", count = 1, remove = true},
				},
				add = {
					{name = "red_wine_prepared", count = 1}
				},
				propsTable = {
					{
						prop = "wine_grape",
						bone = 18905,
						pos = vec3(0.159, 0.018, 0.02),
						rot = vec3(-45.20, -82.39, 37.13)
					},
					{
						prop = "prop_cs_scissors",
						bone = 57005,
						pos = vec3(0.083, 0.020, -0.02),
						rot = vec3(0.0, 0.0, 0.0)
					}
				}
			},
			{
				required = {
					{name = "rose_wine_grapes", count = 1, remove = true},
				},
				add = {
					{name = "rose_wine_prepared", count = 1}
				},
				propsTable = {
					{
						prop = "wine_grape_pink",
						bone = 18905,
						pos = vec3(0.159, 0.018, 0.02),
						rot = vec3(-45.20, -82.39, 37.13)
					},
					{
						prop = "prop_cs_scissors",
						bone = 57005,
						pos = vec3(0.083, 0.020, -0.02),
						rot = vec3(0.0, 0.0, 0.0)
					}
				}
			}
		}
	},

	fill = {
		duration = 1, -- in seconds
		animation = {
			dict = 'random@shop_tattoo',
			clip = '_idle_a'
		},
		job = {
			active = false,
			name = "vineyard",
			grade = 0
		},
		props = {
			barrel = {
				model = "wine_barrel",
				locations = {
					["filler1"] = {spawn = vec4(-1908.88, 2091.72, 139.39, 276.9268), player = vec4(-1908.63, 2090.55, 139.39, 8.69)},
					["filler2"] = {spawn = vec4(-1904.6711, 2093.0754, 139.35, 276.9268), player = vec4(-1904.48, 2091.83, 139.39, 14.29)},
					["filler3"] = {spawn = vec4(-1900.4412, 2093.7637, 139.35, 276.9268), player = vec4(-1900.26, 2092.35, 139.39, 10.77)},
					["filler4"] = {spawn = vec4(-1895.9293, 2094.2668, 139.35, 276.9268), player = vec4(-1895.86, 2092.83, 139.39, 4.28)}
				}
			},
			tap = {
				model = "wine_tap",
				offset = vec3(0.235, 0.0, -0.8),
			}
		},
		types = {
			{
				required = {
					{name = "white_wine_juice", count = 1, remove = true},
					{name = "empty_wine_bottle_labeled", count = 1, remove = true},
				},
				add = {
					{name = "white_wine_bottle", count = 1}
				}
			},
			{
				required = {
					{name = "red_wine_juice", count = 1, remove = true},
					{name = "empty_wine_bottle_labeled", count = 2, remove = true},
				},
				add = {
					{name = "red_wine_bottle", count = 2}
				}
			},
			{
				required = {
					{name = "rose_wine_juice", count = 1, remove = true},
					{name = "empty_wine_bottle_labeled", count = 2, remove = true},
				},
				add = {
					{name = "rose_wine_bottle", count = 2}
				}
			}
		}
	},

	labeling = {
		duration = 1, -- in seconds
		job = {
			active = false,
			name = "vineyard",
			grade = 0
		},
		props = {
			table = {
				model = "prop_table_04",
				locations = {
					["labeling1"] = {spawn = vec4(-1889.86, 2074.08, 140.01, 71.45), player = vec4(-1890.60, 2074.27, 140.01, 255.12)},
					["labeling2"] = {spawn = vec4(-1897.04, 2079.83, 140.01, 226.89), player = vec4(-1896.46, 2079.30, 140.01, 50.03)},
				}
			},
			box = {
				model = "prop_paint_wpaper01",
				offset = vec3(0.73, -0.3, 0.0)
			}
		},
		types = {
			{
				required = {
					{name = "empty_wine_bottle", count = 1, remove = true},
					{name = "wine_label", count = 1, remove = true},
				},
				add = {
					{name = "empty_wine_bottle_labeled", count = 1},
				}
			}
		}
	},

	shop = {
		["shop1"] = {
			label = "Magasin",
			job = {
				active = true,
				name = "vineyard",
				grade = 0
			},
			peds = {
				model = "mp_m_shopkeep_01",
				scenario = "WORLD_HUMAN_CLIPBOARD",
				coords = vec4(-1907.14, 2084.97, 140.39, 46.36),
			},
			items = {
				{name = 'scissors', price = 300},
				{name = 'empty_wine_bottle', price = 2},
				{name = 'wine_glass', price = 2},
				{name = 'wine_label', price = 2},
			}
		}
	},

	standaloneStore = {
		["standalone1"] = {
			society = "vineyard",
			job = {
				active = true,
				name = "vineyard",
				grade = 0
			},
			stash = {
				id = "standalone1",
				label = "Ravitailler",
				slots = 30,
				weight = 1000000
			},
			shop = {
				weight = 5000000,
				label = "Magasin autonome"
			},
			items = {
				["rose_wine_bottle"] = 100,
				["red_wine_bottle"] = 100,
				["white_wine_bottle"] = 100
			},
			peds = {
				model = "u_m_y_antonb",
				coords = vec4(-1882.13, 2048.76, 141.00, 164.93)
			},
		}
	},

	blips = {
		{
			sprite = 616,
			color = 7,
			coords = vec3(-1887.89, 2050.92, 141.00),
			label = "Vignoble",
			scale = 0.7
		}
	},

	stashes = {
		{
			zone = {coords = vec3(-1931.9, 2040.1, 140.3), size = vec3(0.7, 0.8, 1.0), rotation = 345.0},
			job = {
				active = true,
				name = "vineyard",
				grade = 0
			},
			label = "Stockage",
			id = "stock1",
			slots = 50,
			weight = 10000000,
			owner = false,
		},
	},

	consumables = {
		bottles = {
			{
				itemName = "rose_wine_bottle",
				drink = {
					status = {
						thirst = -10,
					}
				},
				duration = 6,
				animation = {
					dict = 'amb@world_human_drinking@coffee@male@idle_a',
					clip = 'idle_c',
					propName = 'prop_wine_white'
				},
				pour = {
					duration = 4,
					required = {
						{itemName = "wine_glass", count = 4, remove = true},
					},
					add = {itemName = "rose_wine_glass", count = 4}
				}
			},
			{
				itemName = "white_wine_bottle",
				drink = {
					status = {
						thirst = -10,
					}
				},
				duration = 6,
				animation = {
					dict = 'amb@world_human_drinking@coffee@male@idle_a',
					clip = 'idle_c',
					propName = 'prop_wine_white'
				},
				pour = {
					duration = 4,
					required = {
						{itemName = "wine_glass", count = 4, remove = true},
					},
					add = {itemName = "white_wine_glass", count = 4}
				}
			},
			{
				itemName = "red_wine_bottle",
				drink = {
					status = {
						thirst = -10,
					}
				},
				duration = 6,
				animation = {
					dict = 'amb@world_human_drinking@coffee@male@idle_a',
					clip = 'idle_c',
					propName = 'prop_wine_white'
				},
				pour = {
					duration = 4,
					required = {
						{itemName = "wine_glass", count = 4, remove = true},
					},
					add = {itemName = "red_wine_glass", count = 4}
				}
			}
		},
		glass = {
			{
				itemName = "red_wine_glass",
				animation = {
					dict = 'amb@world_human_drinking@coffee@male@idle_a',
					clip = 'idle_c',
					propName = 'prop_drink_redwine'
				},
				duration = 6,
				drink = {
					status = {
						thirst = -5,
						drunk = 10000,
					}
				},
				add = {itemName = "wine_glass", count = 1}
			},
			{
				itemName = "rose_wine_glass",
				animation = {
					dict = 'amb@world_human_drinking@coffee@male@idle_a',
					clip = 'idle_c',
					propName = 'prop_drink_redwine'
				},
				duration = 6,
				drink = {
					status = {
						thirst = -5,
						drunk = 10000,
					}
				},
				add = {itemName = "wine_glass", count = 1}
			},
			{
				itemName = "white_wine_glass",
				animation = {
					dict = 'amb@world_human_drinking@coffee@male@idle_a',
					clip = 'idle_c',
					propName = 'prop_drink_whtwine',
				},
				duration = 6,
				drink = {
					status = {
						thirst = -5,
						drunk = 10000,
					}
				},
				add = {itemName = "wine_glass", count = 1}
			},
		}
	},

	automaticMachine = {
		processTime = 3,
		job = {
			active = true,
			name = "vineyard",
			grade = 2
		},
		peds = {
			model = "ig_bankman",
			coords = vec4(-1925.69, 2058.89, 140.82, 356.48),
		},
		items = {
			{itemName = "red_wine_prepared", price = 18, give = "red_wine_juice"},
			{itemName = "white_wine_prepared", price = 18, give = "white_wine_juice"},
			{itemName = "rose_wine_prepared", price = 18, give = "rose_wine_juice"}
		}
	}
}
