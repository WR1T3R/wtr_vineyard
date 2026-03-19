local Config = require("shared.shared")
local Utils = require("client.utils")

local entitiesLoaded = {}
local propsLoaded = {}

function initShop()
	for i = 1, #Config.shop do
		local entity = Utils.createEntity(Config.shop[i].peds.model, Config.shop[i].peds.coords, true)
		TaskStartScenarioInPlace(entity, "WORLD_HUMAN_CLIPBOARD", -1, true)
		entitiesLoaded[#entitiesLoaded + 1] = entity

		exports.ox_target:addLocalEntity(entity, {
			{
				label = "Magasin",
				icon = "fas fa-cash-register",
				groups = Config.shop[i].job.active and {[Config.shop[i].job.name] = Config.shop[i].job.grade} or nil,
				onSelect = function()
					local shopId = lib.callback.await("wtr_vineyard:server:registerShop", false, i)
					exports.ox_inventory:openInventory("shop", {type = ('wtr_vineyard:shop:%d'):format(i), id = 1})
				end,
				distance = 2.0,
			}
		})
	end

	for k, v in pairs(Config.standaloneStore) do
		local stash = lib.callback.await("wtr_vineyard:server:registerStash", false, ("wtr_vineyard:stash:%s"):format(v.stash.id), v.stash.label, v.stash.slots, v.stash.weight, v.stash.owner)
		lib.callback.await("wtr_vineyard:server:initHooks", false, ("wtr_vineyard:stash:%s"):format(v.stash.id))

		local entity = Utils.createEntity(v.peds.model, v.peds.coords, true)
		entitiesLoaded[#entitiesLoaded + 1] = entity

		exports.ox_target:addLocalEntity(entity, {
			{
				label = "Magasin autonome",
				icon = "fas fa-cash-register",
				onSelect = function()
					local options = {}
					local items = lib.callback.await("wtr_vineyard:server:getInventoryItems", false, ("wtr_vineyard:stash:%s"):format(v.stash.id))
					local countItems = {}

					for i = 1, #v.items do

						for id, data in pairs(items) do
							if data.name and data.count then
								if v.items[i].itemName == data.name then
									if not countItems[tostring(data.name)] then 
										countItems[tostring(data.name)] = {amount = data.count, price = v.items[i].price}
									else
										countItems[tostring(data.name)].amount += data.count
									end
								end
							end

							if not countItems[tostring(v.items[i].itemName)] then
								countItems[tostring(v.items[i].itemName)] = {amount = 0, price = v.items[i].price}
							end
						end
					end

					for itemName, value in pairs(countItems) do
						options[#options + 1] = {
							title = exports.ox_inventory:Items(itemName).label,
							icon = exports.ox_inventory:Items(itemName).client.image,
							arrow = value.amount > 0,
							disabled = not (value.amount > 0),
							description = (value.amount > 0) and ("Stock disponible: %s \n Prix: %d$"):format(value.amount, value.price) or ("Stock disponible: %s"):format(value.amount),
							onSelect = function()
								local input = lib.inputDialog(exports.ox_inventory:Items(itemName).label, {
									{type = 'number', label = 'Montant souhaité', description = ("Montant disponible: %d"):format(value.amount), min = 1},
								})
								if not input or not input[1] then return end

								local alert = lib.alertDialog({
									header = 'Achat',
									content = ('Souhaitez-vous acheter %d %s pour %d$'):format(input[1], exports.ox_inventory:Items(itemName).label:lower(), (input[1] * value.price)),
									centered = true,
									cancel = true
								})

								if alert == "confirm" then
									lib.callback.await("wtr_vineyard:server:canBoughtStandaloneItems", false, ("wtr_vineyard:stash:%s"):format(v.stash.id), itemName, input[1], value.price)
								end
							end
						}
					end

					lib.registerContext({
						id = "wtr_vineyard:standaloneStore",
						title = "Magasin autonome",
						options = options
					})
					lib.showContext("wtr_vineyard:standaloneStore")
				end,
				distance = 2.0,
			},
			{
				label = "Ravitailler",
				icon = "fas fa-box",
				groups = v.job.active and {[v.job.name] = v.job.grade} or nil,
				onSelect = function()
					exports.ox_inventory:openInventory("stash", ("wtr_vineyard:stash:%s"):format(v.stash.id))
				end,
				distance = 2.0,
			}
		})
	end
end
exports("InitShop", initShop)

function destroyShop()
	for k, v in pairs(entitiesLoaded) do
		if DoesEntityExist(v) then DeleteEntity(v) end
	end
end
exports("DestroyShop", destroyShop)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() == resource then
		for k, v in pairs(entitiesLoaded) do
			if DoesEntityExist(v) then DeleteEntity(v) end
		end
	end
end)