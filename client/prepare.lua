local Config = require("shared.shared")
local Utils = require("client.utils")

local propsLoaded = {}
local function canCraft(items)
	local itemsIn = 0

	for i = 1, #items do
		local count = exports.ox_inventory:GetItemCount(items[i].itemName)

		if count >= (items[i].count * exports.wtr_vineyard:getAmountPreload("prepare")) then itemsIn += 1 end
	end

	return #items == itemsIn
end

local function getRequiredLabel(items)
	a = 0
	label = ""

	for _, v in pairs(items) do
		label = string.format("%s%sx %s", label, (v.count * exports.wtr_vineyard:getAmountPreload("prepare")), exports.ox_inventory:Items(v.itemName).label)
		if a ~= #items - 1 then label = ("%s\n"):format(label) end
		a += 1
	end

	return label
end

local function initPrepareMenu(coords, id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("prepare")

	options[#options + 1] = {
		title = ("Montant pré-défini: %d"):format(amountPreload),
		icon = "fas fa-circle-info",
		arrow = true,
		onSelect = function()
			local input = lib.inputDialog('Définir', {
				{type = 'slider', label = 'Montant pré-défini', description = '', required = true, min = 1, max = 60},
			})
			if not input or not input[1] then return end

			exports.wtr_vineyard:setAmountPreload(input[1])
			Wait(10)
			lib.notify({title = "Notification", description = ("Montant pré-défini ajusté à %d"):format(input[1]), type = "success"})
			initPrepareMenu(coords, id)
		end
	}
	for i = 1, #Config.prepare.types do
		local prepareInfo = Config.prepare.types
		local itemCount = exports.ox_inventory:GetItemCount(prepareInfo[i].itemName)
		local itemInfo = exports.ox_inventory:Items(prepareInfo[i].add.itemName)

		options[#options + 1] = {
			title = ("%dx %s"):format((prepareInfo[i].add.count * amountPreload), itemInfo.label),
			description = getRequiredLabel(prepareInfo[i].required),
			icon = itemInfo.client.image,
			arrow = canCraft(prepareInfo[i].required),
			disabled = not canCraft(prepareInfo[i].required),
			onSelect = function()
				if canCraft(prepareInfo[i].required) then
					local isPrepared = lib.callback.await("wtr_vineyard:server:isPrepared", false, id)
					if isPrepared then lib.notify({description = "Cette station est occupée", type = "error"}) return end

					for k, v in pairs(prepareInfo[i].required) do
						if v.remove then
							lib.callback.await("wtr_vineyard:server:setupItems", false, "remove", v.itemName, v.count * exports.wtr_vineyard:getAmountPreload("prepare"))
						end
					end

					lib.callback.await("wtr_vineyard:server:setPrepared", false, id, true)
					exports.ox_target:disableTargeting(true)

					SetEntityCoords(cache.ped, coords)
					SetEntityHeading(cache.ped, coords.w)
					if lib.progressCircle({
						label = "Préparation des raisins",
						duration = (Config.prepare.duration * 1000) * exports.wtr_vineyard:getAmountPreload("prepare"),
						position = 'bottom',
						useWhileDead = false,
						canCancel = false,
						disable = {
							move = true,
							combat = true,
							car = true,
						},
						anim = {
							dict = 'mp_arresting',
							clip = 'a_uncuff'
						},
						prop = {
							{
								model = prepareInfo[i].propsTable[1].prop,
								bone = 18905,
								pos = prepareInfo[i].propsTable[1].coords,
								rot = prepareInfo[i].propsTable[1].rotation,
							},
							{
								model = prepareInfo[i].propsTable[2].prop,
								bone = 57005,
								pos = prepareInfo[i].propsTable[2].coords,
								rot = prepareInfo[i].propsTable[2].rotation,
							},
						},
					}) 
					then 
						exports.ox_target:disableTargeting(false)
						lib.callback.await("wtr_vineyard:server:setupItems", false, "give", prepareInfo[i].add.itemName, prepareInfo[i].add.count * exports.wtr_vineyard:getAmountPreload("prepare"))
						lib.callback.await("wtr_vineyard:server:setPrepared", false, id, nil)
					end
				end
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:prepareMenu",
		title = "Préparation",
		options = options
	})
	lib.showContext("wtr_vineyard:prepareMenu")
end

function initPrepare()
	for i = 1, #Config.prepare.props.table.locations do
		local prop = Utils.createProp(Config.prepare.props.table.model, Config.prepare.props.table.locations[i].spawn, true)
		propsLoaded[#propsLoaded + 1] = prop

		exports.ox_target:addLocalEntity(prop, {
			{
				label = "Préparation de raisins",
				groups = Config.prepare.job.active and {[Config.prepare.job.name] = Config.prepare.job.grade} or nil,
				icon = "fas fa-leaf",
				onSelect = function()
					initPrepareMenu(Config.prepare.props.table.locations[i].player, i)
				end,
				distance = 2.0,
			}
		})
	end

	for i = 1, #Config.prepare.props.box.locations do
		local prop = Utils.createProp(Config.prepare.props.box.model, Config.prepare.props.box.locations[i], false)
		propsLoaded[#propsLoaded + 1] = prop
	end
end
exports("InitPrepare", initPrepare)

function destroyPrepare()
	for k, v in pairs(propsLoaded) do
		if DoesEntityExist(v) then DeleteEntity(v) end
	end
end
exports("DestroyPrepare", destroyPrepare)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() == resource then
		for k, v in pairs(propsLoaded) do
			if DoesEntityExist(v) then DeleteEntity(v) end
		end
	end
end)