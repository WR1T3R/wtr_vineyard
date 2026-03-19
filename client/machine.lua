local Config = require("shared.shared")
local Utils = require("client.utils")

local entitiesLoaded = {}

local function initSellingMenu()
	local options = {}

	for i = 1, #Config.automaticMachine.items do
		options[#options + 1] = {
			title = exports.ox_inventory:Items(Config.automaticMachine.items[i].itemName).label,
			icon = exports.ox_inventory:Items(Config.automaticMachine.items[i].itemName).client.image,
			arrow = exports.ox_inventory:GetItemCount(Config.automaticMachine.items[i].itemName) > 0,
			disabled = not (exports.ox_inventory:GetItemCount(Config.automaticMachine.items[i].itemName) > 0),
			description = ("Possédés: %d \n Valeur: %d$"):format(exports.ox_inventory:GetItemCount(Config.automaticMachine.items[i].itemName), Config.automaticMachine.items[i].price),
			onSelect = function()
				local input = lib.inputDialog(exports.ox_inventory:Items(Config.automaticMachine.items[i].itemName).label, {
					{type = 'number', label = 'Montant souhaité', description = ("Montant disponible: %d"):format(exports.ox_inventory:GetItemCount(Config.automaticMachine.items[i].itemName)), min = 1},
				})
				if not input or not input[1] then return end

				local alert = lib.alertDialog({
					header = 'Achat',
					content = ('Souhaitez-vous vendre %d %s pour %d$'):format(input[1], exports.ox_inventory:Items(Config.automaticMachine.items[i].itemName).label:lower(), (input[1] * Config.automaticMachine.items[i].price)),
					centered = true,
					cancel = true
				})

				if alert == "confirm" then
					lib.callback.await("wtr_vineyard:server:sellAutomatic", false, Config.automaticMachine.items[i].itemName, input[1], Config.automaticMachine.items[i].price)
				end
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:sellingMenu",
		title = "Vente",
		options = options
	})
	lib.showContext("wtr_vineyard:sellingMenu")
end

local function initCollectMenu()
	local machineData = lib.callback.await("wtr_vineyard:server:getMachineData", false)
	local options = {}
	local amount = 0

	for k, v in pairs(machineData.juices) do
		amount += 1
		options[#options + 1] = {
			title = exports.ox_inventory:Items(k).label,
			description = ("Montant: %s"):format(tostring(v)),
			icon = exports.ox_inventory:Items(k).client.image,
			onSelect = function()
				local input = lib.inputDialog(exports.ox_inventory:Items(k).label, {
					{type = 'number', label = 'Montant souhaité', description = ("Montant disponible: %s"):format(tostring(v)), min = 1},
				})
				if not input or not input[1] then return end

				lib.callback.await("wtr_vineyard:server:collectAutomatic", false, k, input[1])
			end
		}
	end

	if amount == 0 then
		options[#options + 1] = {
			title = "Aucun élément prêt à être collecté",
			icon = "fas fa-circle-xmark",
			readOnly = true
		}
	else
		options[#options + 1] = {
			title = "Rafraîchir",
			icon = "fas fa-rotate-left",
			onSelect = function()
				initCollectMenu()
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:collectMenu",
		title = "Prêt à être collecté",
		options = options
	})
	lib.showContext("wtr_vineyard:collectMenu")
end

local function initProcessMenu()
	local machineData = lib.callback.await("wtr_vineyard:server:getMachineData", false)
	local options = {}
	local amount = 0

	for k, v in pairs(machineData.process) do
		amount += 1
		options[#options + 1] = {
			title = exports.ox_inventory:Items(k).label,
			description = ("Montant en processus: %s"):format(tostring(v)),
			icon = exports.ox_inventory:Items(k).client.image,
		}
	end

	if amount == 0 then
		options[#options + 1] = {
			title = "Aucun élément en processus",
			icon = "fas fa-circle-xmark",
			readOnly = true
		}
	else
		options[#options + 1] = {
			title = "Rafraîchir",
			icon = "fas fa-rotate-left",
			onSelect = function()
				initProcessMenu()
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:processMenu",
		title = "Processus",
		options = options
	})
	lib.showContext("wtr_vineyard:processMenu")
end

local function initManageMenu()
	local options = {
		{
			title = "En processus",
			icon = "fas fa-circle-xmark",
			onSelect = function()
				initProcessMenu()
			end
		},
		{
			title = "Prêt à être ramassé",
			icon = "fas fa-circle-check",
			onSelect = function()
				initCollectMenu()
			end
		}
	}

	lib.registerContext({
		id = "wtr_vineyard:manageMenu",
		title = "Gérer",
		options = options
	})
	lib.showContext("wtr_vineyard:manageMenu")
end

CreateThread(function()
	while not LocalPlayer.state.isLoggedIn do Wait(4000) end

	local zonePoint = lib.points.new({
		coords = Config.automaticMachine.peds.coords,
		distance = 100,
		peds = nil,
		targetOptions = {
			{
				label = "Vendre vos raisins",
				icon = "fas fa-leaf",
				onSelect = function()
					initSellingMenu()
				end
			},
			{
				groups = Config.automaticMachine.job.active and {[Config.automaticMachine.job.name] = Config.automaticMachine.job.grade} or nil,
				label = "Gérer",
				icon = "fas fa-circle-info",
				onSelect = function()
					initManageMenu()
				end
			}
		}
	})

	function zonePoint:onEnter()
		lib.requestModel(Config.automaticMachine.peds.model, 10000)

		self.peds = Utils.createEntity(Config.automaticMachine.peds.model, Config.automaticMachine.peds.coords, true)
		exports.ox_target:addLocalEntity(self.peds, self.targetOptions)
	end

	function zonePoint:onExit()
		exports.ox_target:removeLocalEntity(self.peds)
		if DoesEntityExist(self.peds) then DeleteEntity(self.peds) end

		self.peds = nil
	end
end)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() == resource then
		for k, v in pairs(entitiesLoaded) do
			if DoesEntityExist(v) then DeleteEntity(v) end
		end
	end
end)