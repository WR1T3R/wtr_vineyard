local QBCore = exports["qb-core"]:GetCoreObject()
local Config = require("shared.shared")

local ox_inventory = exports.ox_inventory

local occupiedStations = {}

local harvested = {}

local function isItemAllowlisted(id, name)
	for k, v in pairs(Config.standaloneStore[id].items) do
		if name == k then
			return true
		end
	end

	return false
end

local function convertStandaloneInventory(stashId, id)
	local stashItems = ox_inventory:GetInventoryItems(stashId)
	local shopItems = {}

	local convertInventory = {}

	for _, data in pairs(stashItems or {}) do
		shopItems[data.name] = shopItems[data.name] or {}
		shopItems[data.name].count = shopItems[data.name].count or 0

		shopItems[data.name].count += data.count
	end

	for k, v in pairs(shopItems or {}) do
		convertInventory[#convertInventory + 1] = {name = k, count = v.count, price = Config.standaloneStore[id].items[k]}
	end

	return convertInventory
end

local function updateStandaloneShop(stashId, id)
	local items = convertStandaloneInventory(stashId, id)
	local shopData = Config.standaloneStore[id]

	local shopId = ox_inventory:RegisterShop(("wtr_vineyard:standaloneStore:%s"):format(id), {
		name = shopData.label,
		inventory = items,
		groups = shopData.job.active and {[shopData.job.name] = shopData.job.grade} or nil,
		locations = {vec3(shopData.peds.coords.x, shopData.peds.coords.y, shopData.peds.coords.z)},
	})
end

local function initStandaloneShopHook(stashId, id)
	ox_inventory:registerHook('buyItem', function(payload)
		if payload.shopType == ("wtr_vineyard:standaloneStore:%s"):format(id) then
			ox_inventory:RemoveItem(stashId, payload.itemName, payload.count)
			Writer.UpdateSocietyMoney("add", payload.totalPrice, Config.standaloneStore[id].society)
			updateStandaloneShop(stashId, id)
			return true
		end
		return true
	end, {})

	ox_inventory:registerHook('swapItems', function(payload)
		if payload.toInventory == stashId then
			if payload.fromSlot then
				local isAllow = isItemAllowlisted(id, payload.fromSlot.name)

				if not isAllow then return false end

				SetTimeout(50, function()
					updateStandaloneShop(stashId, id)
				end)
			end
		elseif payload.fromInventory == stashId then
			SetTimeout(50, function()
				updateStandaloneShop(stashId, id)
			end)

			return true
		end
		return true
	end, {
		inventoryFilter = {stashId}
	})
end

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

lib.callback.register("wtr_vineyard:server:proceedStep", function(source, id, amountPreload, data)
	if not source then return false end
	if not id then return false end
	if not Config.step.props.locations[id] then return false end
	if not amountPreload then return false end
	if not data then return false end

	local src = source

	occupiedStations.step = occupiedStations.step or {}

	if occupiedStations?.step?[id] then
		Writer.Notify(src, "Cette station de presse est déjà occupée", "error")
		return
	end

	occupiedStations.step[id] = true
	local passed = lib.callback.await("wtr_vineyard:client:proceedStep", src, id, amountPreload, data)
	if not passed then occupiedStations.step[id] = nil return false end

	local canPass, denyTable = Writer.CanCraft(src, data.required, amountPreload)
	if not canPass then
		Writer.Notify(src, "Vous n'avez pas les items requis pour faire cela", "error")
		occupiedStations.step[id] = nil
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

	occupiedStations.step[id] = nil
	return true
end)

RegisterNetEvent("wtr_vineyard:server:proceedHarvest", function(harvestInfo, spotId, spotCoords, zoneName)
	local src = source

	if harvested?[zoneName]?[spotId]?.active then Writer.Notify(src, ("Cette vigne a déjà été récolté. Revenez dans %s"):format(Writer.FormatTime(harvested[zoneName][spotId].cooldown)), "error") return end
	if Player(src).state["vineyard:collecting"] then return end

	harvested[zoneName] = harvested[zoneName] or {}
	harvested[zoneName][spotId] = {active = true, cooldown = harvestInfo.cooldown}

	Player(src).state:set("vineyard:collecting", true, true)

	local passed = lib.callback.await("wtr_vineyard:client:proceedHarvest", src, spotCoords, harvestInfo)
	if not passed then 
		harvested[zoneName][spotId] = nil
		Player(src).state:set("vineyard:collecting", false, true)
		return 
	end

	Player(src).state:set("vineyard:collecting", false, true)

	for k, v in pairs(harvestInfo.items) do
		ox_inventory:AddItem(src, v.name, math.random(v.count.min, v.count.max))
	end
end)

CreateThread(function()
	while true do
		for zoneName, spots in pairs(harvested) do
			for spotId, data in pairs(spots) do
				if harvested[zoneName][spotId].cooldown == 0 then
					harvested[zoneName][spotId] = nil
				else
					harvested[zoneName][spotId].cooldown -= 1
				end
			end
		end
		Wait(1000)
	end
end)

lib.callback.register("wtr_vineyard:server:setupItems", function(source, func, item, amount, meta, slot)
	local src = source

	if func == "give" then
		ox_inventory:AddItem(src, item, amount, meta, slot)
	elseif func == "remove" then
		ox_inventory:RemoveItem(src, item, amount, meta, slot)
	end
end)

lib.callback.register("wtr_vineyard:server:registerStash", function(source, id, label, slots, weight, owner)
	ox_inventory:RegisterStash(id, label, slots, weight, owner)
end)

CreateThread(function()
	for k, v in pairs(Config.standaloneStore) do
		local stashId = ("wtr_vineyard:standaloneShop:%s"):format(k)

		ox_inventory:RegisterStash(stashId, v.shop.label, Writer.GetTableSize(v.items), v.shop.weight, nil)
		initStandaloneShopHook(stashId, k)

		local shopItems = convertStandaloneInventory(stashId, k)

		local shopId = ox_inventory:RegisterShop(('wtr_vineyard:standaloneStore:%s'):format(k), {
			name = v.label,
			inventory = shopItems,
			groups = nil,
			locations = {vec3(v.peds.coords.x, v.peds.coords.y, v.peds.coords.z)},
		})
	end

	for k, v in pairs(Config.shop) do
		local shopId = ox_inventory:RegisterShop(('wtr_vineyard:shop:%s'):format(k), {
			name = v.label,
			inventory = v.items,
			groups = v.job.active and {[v.job.name] = v.job.grade} or nil,
			locations = {vec3(v.peds.coords.x, v.peds.coords.y, v.peds.coords.z)},
		})
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