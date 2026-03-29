local harvested = {}
local stepped = {}
local prepared = {}
local machineData = {}

local QBCore = exports["qb-core"]:GetCoreObject()
local Config = require("shared.shared")

local ox_inventory = exports.ox_inventory
local occupiedStations = {}

local function isItemAllowlisted(id, name)
	for k, v in pairs(Config.standaloneStore[id].items) do
		if name == v.itemName then
			return true
		end
	end

	return false
end

lib.callback.register("wtr_vineyard:server:initHooks", function(source, id)
	for k,v in pairs(Config.standaloneStore) do
		ox_inventory:registerHook('swapItems', function(payload)
			if payload.toInventory == id then
				if payload.fromSlot then
					local isAllow = isItemAllowlisted(k, payload.fromSlot.name, v)

					if not isAllow then return false end
				end
			end
			return true
		end, {
			inventoryFilter = {
				id,
			}
		})
	end
end)

lib.callback.register("wtr_vineyard:server:getInventoryItems", function(source, id)
	local src = source
	local items = ox_inventory:GetInventoryItems(id)

	return items
end)

lib.callback.register("wtr_vineyard:server:canBoughtStandaloneItems", function(source, id, item, amount, price)
	local src = source

	if ox_inventory:CanCarryItem(src, item, amount) then
		if ox_inventory:GetItemCount(src, "money") >= (amount * price) then
			ox_inventory:AddItem(src, item, amount)
			ox_inventory:RemoveItem(id, item, amount)
			ox_inventory:RemoveItem(src, "money", amount * price)
			exports['Renewed-Banking']:addAccountMoney("vineyard", amount * price)
		else
			TriggerClientEvent("ox_lib:notify", src, {description = "Vous n'avez pas les fonds nécessaires (Argent comptant)", type = "error"})
			return
		end
	else
		TriggerClientEvent("ox_lib:notify", src, {description = "Vous ne pouvez en porter autant", type = "error"})
		return
	end
end)

lib.callback.register("wtr_vineyard:server:getMachineData", function()
	return machineData
end)

lib.callback.register("wtr_vineyard:server:collectAutomatic", function(source, item, amount)
	local src = source
	if ox_inventory:CanCarryItem(src, tostring(item), tonumber(amount)) then
		if machineData.juices[tostring(item)] then
			if machineData.juices[tostring(item)] - amount == 0 then
				ox_inventory:AddItem(src, item, amount)
				machineData.juices[tostring(item)] = nil
			else
				ox_inventory:AddItem(src, item, amount)
				machineData.juices[tostring(item)] -= amount
			end
		end
	else
		TriggerClientEvent("ox_lib:notify", src, {description = "Vous ne pouvez en porter autant", type = "error"})
		return
	end
end)

lib.callback.register("wtr_vineyard:server:sellAutomatic", function(source, item, amount, price)
	local src = source
	local companyAmount = exports['Renewed-Banking']:getAccountMoney("vineyard")

	if companyAmount >= (amount * price) then
		ox_inventory:RemoveItem(src, item, amount)
		ox_inventory:AddItem(src, "money", (amount * price))
		exports['Renewed-Banking']:removeAccountMoney("vineyard", amount * price)

		if machineData.process and machineData.process[tostring(item)] then
			machineData.process[tostring(item)] += amount
		else
			if machineData.process then
				machineData.process[tostring(item)] = amount
			else
				machineData.process = {}
				machineData.process[tostring(item)] = amount
			end
		end
	else
		TriggerClientEvent("ox_lib:notify", src, {description = "Le vignoble n'a pas assez de fonds pour vous payer", type = "error"})
	end
end)

lib.callback.register("wtr_vineyard:server:proceedFilling", function(source, id, amountPreload, data)
	if not source then return false end
	if not id then return false end
	if not Config.fill.props.barrel.locations[id] then return false end
	if not amountPreload then return false end
	if not data then return false end

	local src = source

	occupiedStations.filled = occupiedStations.filled or {}

	if occupiedStations?.filled?[id] then 
		Writer.Notify(src, "Cette station de remplissage est déjà occupée", "error")
		return 
	end

	occupiedStations.filled[id] = true
	local passed = lib.callback.await("wtr_vineyard:client:proceedFilling", src, id, amountPreload, data)
	if not passed then occupiedStations.filled[id] = nil return false end

	local canPass, denyTable = Writer.CanCraft(src, data.required, amountPreload)
	if not canPass then 
		Writer.Notify(src, "Vous n'avez pas les items requis pour faire cela", "error")
		occupiedStations.filled[id] = nil
		return 
	end

	for k, v in pairs(data.required) do
		if v.remove then
			ox_inventory:RemoveItem(src, v.name, v.count * amountPreload)
		end
	end

	for k, v in pairs(data.add) do
		ox_inventory:AddItem(src, v.name, v.count * amountPreload)
	end

	occupiedStations.filled[id] = nil
	return true
end)

lib.callback.register("wtr_vineyard:server:proceedLabeling", function(source, id, amountPreload, data)
	if not source then return false end
	if not id then return false end
	if not Config.labeling.props.table.locations[id] then return false end
	if not amountPreload then return false end
	if not data then return false end

	local src = source

	occupiedStations.labeling = occupiedStations.labeling or {}

	if occupiedStations?.labeling?[id] then 
		Writer.Notify(src, "Cette station d'étiquettage est déjà occupée", "error")
		return 
	end

	occupiedStations.labeling[id] = true
	local passed = lib.callback.await("wtr_vineyard:client:proceedLabeling", src, id, amountPreload, data)
	if not passed then occupiedStations.labeling[id] = nil return false end

	local canPass, denyTable = Writer.CanCraft(src, data.required, amountPreload)
	if not canPass then 
		Writer.Notify(src, "Vous n'avez pas les items requis pour faire cela", "error")
		occupiedStations.labeling[id] = nil
		return 
	end

	for k, v in pairs(data.required) do
		if v.remove then
			ox_inventory:RemoveItem(src, v.name, v.count * amountPreload)
		end
	end

	for k, v in pairs(data.add) do
		ox_inventory:AddItem(src, v.name, v.count * amountPreload)
	end

	occupiedStations.labeling[id] = nil
	return true
end)

lib.callback.register("wtr_vineyard:server:proceedPrepare", function(source, id, amountPreload, data)
	if not source then return false end
	if not id then return false end
	if not Config.prepare.props.table.locations[id] then return false end
	if not amountPreload then return false end
	if not data then return false end

	local src = source

	occupiedStations.prepare = occupiedStations.prepare or {}

	if occupiedStations?.prepare?[id] then 
		Writer.Notify(src, "Cette station de préparation est déjà occupée", "error")
		return 
	end

	occupiedStations.prepare[id] = true
	local passed = lib.callback.await("wtr_vineyard:client:proceedPrepare", src, id, amountPreload, data)
	if not passed then occupiedStations.prepare[id] = nil return false end

	local canPass, denyTable = Writer.CanCraft(src, data.required, amountPreload)
	if not canPass then 
		Writer.Notify(src, "Vous n'avez pas les items requis pour faire cela", "error")
		occupiedStations.prepare[id] = nil
		return 
	end

	for k, v in pairs(data.required) do
		if v.remove then
			ox_inventory:RemoveItem(src, v.name, v.count * amountPreload)
		end
	end

	for k, v in pairs(data.add) do
		ox_inventory:AddItem(src, v.name, v.count * amountPreload)
	end

	occupiedStations.prepare[id] = nil
	return true
end)

lib.callback.register("wtr_vineyard:server:setupItems", function(source, func, item, amount, meta, slot)
	local src = source

	if func == "give" then
		ox_inventory:AddItem(src, item, amount, meta, slot)
	elseif func == "remove" then
		ox_inventory:RemoveItem(src, item, amount, meta, slot)
	end
end)

lib.callback.register("wtr_vineyard:server:isStepped", function(source, id)
	local src = source
	local newId = tostring(id)

	return stepped[newId]
end)

lib.callback.register("wtr_vineyard:server:setStepped", function(source, id, bool)
	local src = source
	local newId = tostring(id)

	stepped[newId] = bool
end)

lib.callback.register("wtr_vineyard:server:isPrepared", function(source, id)
	local src = source
	local newId = tostring(id)

	return prepared[newId]
end)

lib.callback.register("wtr_vineyard:server:setPrepared", function(source, id, bool)
	local src = source
	local newId = tostring(id)

	prepared[newId] = bool
end)

lib.callback.register("wtr_vineyard:server:registerShop", function(source, id)
	local shopId = ox_inventory:RegisterShop(('wtr_vineyard:shop:%d'):format(id), {
        name = Config.shop[id].label,
        inventory = Config.shop[id].items,
        groups = Config.shop[id].job.active and {[Config.shop[id].job.name] = Config.shop[id].job.grade} or nil,
        locations = {vec3(Config.shop[id].peds.coords.x, Config.shop[id].peds.coords.y, Config.shop[id].peds.coords.z)},
    })

	return shopId
end)

lib.callback.register("wtr_vineyard:server:isHarvested", function(source, name, areasId, harvestId)
	local src = source
	local newName = tostring(name)
	local newAreasID = tostring(areasId)
	local newHarvestID = tostring(harvestId)

	if harvested[newName] then
		if harvested[newName][newAreasID] then
			if harvested[newName][newAreasID][newHarvestID] then
				if harvested[newName][newAreasID][newHarvestID].active then
					return true, harvested[newName][newAreasID][newHarvestID]
				end
			end
		end
	end

	return false
end)

lib.callback.register("wtr_vineyard:server:setHarvested", function(source, name, areasId, harvestId, cooldown)
	local src = source
	local newName = tostring(name)
	local newAreasID = tostring(areasId)
	local newHarvestID = tostring(harvestId)

	if harvested[newName] then
		if harvested[newName][newAreasID] then
			harvested[newName][newAreasID][newHarvestID] = {active = true, cooldown = cooldown}
		else
			harvested[newName][newAreasID] = {
				[newHarvestID] = {active = true, cooldown = cooldown}
			}
		end
	else
		harvested[newName] = {
			[newAreasID] = {
				[newHarvestID] = {active = true, cooldown = cooldown}
			}
		}
	end

	return false
end)

lib.callback.register("wtr_vineyard:server:registerStash", function(source, id, label, slots, weight, owner)
	ox_inventory:RegisterStash(id, label, slots, weight, owner)
end)

CreateThread(function()
	while true do
		for name, _ in pairs(harvested) do
			if harvested[name] then
				for areasID, _ in pairs(harvested[name]) do
					if harvested[name][areasID] then
						for harvestID, _ in pairs(harvested[name][areasID]) do
							if harvested[name][areasID][harvestID] and harvested[name][areasID][harvestID].active and harvested[name][areasID][harvestID].cooldown then
								harvested[name][areasID][harvestID].cooldown -= 1

								if harvested[name][areasID][harvestID].cooldown == 0 then
									harvested[name][areasID][harvestID] = nil
								end
							end
						end
					end
				end
			end
		end

		Wait(1000)
	end
end)

local function getRewardItem(item)
	for k,v in pairs(Config.automaticMachine.items) do
		if v.itemName == item then
			return v.give
		end
	end
end

CreateThread(function()
	while true do
		for item, amount in pairs(machineData.process) do
			if machineData.process[tostring(item)] then
				if machineData.process[tostring(item)] == 0 then
					machineData.process[tostring(item)] = nil
				else
					if machineData.juices[tostring(getRewardItem(item))] then
						machineData.juices[tostring(getRewardItem(item))] += 1
						machineData.process[tostring(item)] -= 1
						if machineData.process[tostring(item)] == 0 then
							machineData.process[tostring(item)] = nil
						end
					else
						machineData.juices[tostring(getRewardItem(item))] = 1
						machineData.process[tostring(item)] -= 1
						if machineData.process[tostring(item)] == 0 then
							machineData.process[tostring(item)] = nil
						end
					end
				end
			end
		end
		Wait(Config.automaticMachine.processTime * 1000)
	end
end)

lib.callback.register("wtr_vineyard:server:drink", function(source, data)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)

	player.PlayerData.metadata["thirst"] += data.drink.status.thirst
	player.Functions.SetMetaData("thirst", player.PlayerData.metadata["thirst"])

	ox_inventory:RemoveItem(src, data.itemName, 1)
	TriggerClientEvent('hud:client:UpdateNeeds', src, player.PlayerData.metadata["hunger"], player.PlayerData.metadata["thirst"])
end)

for k, v in pairs(Config.consumables.bottles) do
	QBCore.Functions.CreateUseableItem(v.itemName, function(source, item)
		local src = source
		lib.callback.await("wtr_vineyard:client:preparePour", src, v)
	end)
end

for k, v in pairs(Config.consumables.glass) do
	QBCore.Functions.CreateUseableItem(v.itemName, function(source, item)
		local src = source
		local player = QBCore.Functions.GetPlayer(src)

		local passed = lib.callback.await("wtr_vineyard:client:drinkGlass", src, v)
		if not passed then return end

		Writer.UpdateStatus(src, "add", "thirst", v.drink.status.thirst)

		ox_inventory:AddItem(src, v.add.itemName, v.add.count)
		ox_inventory:RemoveItem(src, v.itemName, 1)
	end)
end

AddEventHandler("onResourceStart", function(resource)
	if GetCurrentResourceName() == resource then
		local data = LoadResourceFile(GetCurrentResourceName(), "./data/machine.json")

		machineData = json.decode(data) ~= "null" and json.decode(data) or {}
		if not machineData.process then machineData.process = {} end
		if not machineData.juices then machineData.juices = {} end
	end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function(delay, author, message)
	SaveResourceFile(GetCurrentResourceName(), "./data/machine.json", json.encode(machineData, {indent = true}))
end)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() == resource then
		SaveResourceFile(GetCurrentResourceName(), "./data/machine.json", json.encode(machineData, {indent = true}))
	end
end)