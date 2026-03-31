local Config = require("shared.shared")
local Utils = require("client.utils")

local amountPreload = 1

local function setAmountPreload(amount)
	amountPreload = amount
	SetResourceKvpInt("wtr_vineyard:amountPreload", amountPreload)
end
exports("setAmountPreload", setAmountPreload)

local function getAmountPreload(_type)
	return amountPreload >= Config.maxPredefinedAmount[_type] and Config.maxPredefinedAmount[_type] or amountPreload
end
exports("getAmountPreload", getAmountPreload)

local function inputPredefinedAmount(_type)
	local input = lib.inputDialog('Définir', {
		{type = 'slider', label = 'Montant pré-défini', description = '', required = true, min = 1, max = Config.maxPredefinedAmount[_type], default = 1},
	})
	if not input or not input[1] then return false, nil end

	return true, input[1]
end
exports("predefinedAmount", inputPredefinedAmount)

local function processDrink(data)
	local progress = Writer.SendProgress({
		label = data.label,
		duration = data.duration * 1000,
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = false,
			combat = true,
			car = true,
			mouse = false
		},
		anim = data.anim,
		prop = data.prop
	})

	return progress
end
lib.callback.register("wtr_vineyard:client:processDrink", processDrink)

local function selectDrinkOption(data)
	local alert = lib.alertDialog({
		header = 'Option',
		content = ('Choisissez entre verser et boire votre bouteille. \n\n**Pré-requis pour le versage**: \n%s.'):format(Writer.GetLabelDescription(data.required, 1, " \n", false)),
		centered = true,
		cancel = true,
		labels = {
			confirm = "Verser",
			cancel = "Boire"
		}
	})
	if not alert then return end
	return alert == "confirm" and "pour" or "drink"
end
lib.callback.register("wtr_vineyard:client:selectDrinkOption", selectDrinkOption)

CreateThread(function()
	while not LocalPlayer.state.isLoggedIn do Wait(5000) end

	local kvp = GetResourceKvpInt("wtr_vineyard:amountPreload")
	amountPreload = kvp ~= 0 and kvp or 1

	for k, v in pairs(Config.stashes) do
		exports.ox_target:addBoxZone({
			coords = v.zone.coords,
			size = v.zone.size,
			rotation = v.zone.rotation,
			debug = Config.debug,
			options = {
				{
					label = v.label,
					icon = "fas fa-box",
					groups = v.job.active and {[v.job.name] = v.job.grade} or nil,
					onSelect = function()
						exports.ox_inventory:openInventory("stash", ("wtr_vineyard:stash:%s"):format(v.id))
					end,
					distance = 2.0
				}
			}
		})
	end

	for k, v in pairs(Config.blips) do
		local blip = Writer.AddBlip({
			coords = v.coords,
			sprite = v.sprite,
			scale = v.scale,
			display = 4,
			color = v.color,
			label = v.label,
			shortRange = true,
		})
	end
end)