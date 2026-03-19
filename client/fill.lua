local Config = require("shared.shared")
local Utils = require("client.utils")

local propsLoaded = {}

local function canCraft(items)
	local itemsIn = 0

	for i = 1, #items do
		local count = exports.ox_inventory:GetItemCount(items[i].itemName)

		if count >= (items[i].count * exports.wtr_vineyard:getAmountPreload("fill")) then itemsIn += 1 end
	end

	return #items == itemsIn
end

local function getRequiredLabel(items)
	a = 0
	label = ""

	for _, v in pairs(items) do
		label = string.format("%s%sx %s", label, (v.count * exports.wtr_vineyard:getAmountPreload("fill")), exports.ox_inventory:Items(v.itemName).label)
		if a ~= #items - 1 then label = ("%s\n"):format(label) end
		a += 1
	end

	return label
end

local function initFillMenu(coords, tapCoords, id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("fill")

	options[#options + 1] = {
		title = ("Montant pré-défini: %d"):format(amountPreload),
		icon = "fas fa-circle-info",
		arrow = true,
		onSelect = function()
			local input = lib.inputDialog('Définir', {
				{type = 'slider', label = 'Montant pré-défini', description = '', required = true, min = 1, max = 20},
			})
			if not input or not input[1] then return end

			exports.wtr_vineyard:setAmountPreload(input[1])
			Wait(10)
			lib.notify({title = "Notification", description = ("Montant pré-défini ajusté à %d"):format(input[1]), type = "success"})
			initFillMenu(coords, tapCoords, id)
		end
	}
	for i = 1, #Config.fill.types do
		local fillInfo = Config.fill.types
		local itemCount = exports.ox_inventory:GetItemCount(fillInfo[i].itemName)
		local itemInfo = exports.ox_inventory:Items(fillInfo[i].add.itemName)

		options[#options + 1] = {
			title = ("%dx %s"):format((fillInfo[i].add.count* exports.wtr_vineyard:getAmountPreload("fill")), itemInfo.label),
			description = getRequiredLabel(fillInfo[i].required),
			icon = itemInfo.client.image,
			arrow = canCraft(fillInfo[i].required),
			disabled = not canCraft(fillInfo[i].required),
			onSelect = function()
				if canCraft(fillInfo[i].required) then
					local isFilled = lib.callback.await("wtr_vineyard:server:isFilled", false, id)
					if isFilled then lib.notify({description = "Cette station est occupée", type = "error"}) return end

					for k, v in pairs(fillInfo[i].required) do
						if v.remove then
							lib.callback.await("wtr_vineyard:server:setupItems", false, "remove", v.itemName, (v.count * exports.wtr_vineyard:getAmountPreload("fill")))
						end
					end

					lib.callback.await("wtr_vineyard:server:setFilled", false, id, true)
					exports.ox_target:disableTargeting(true)

					SetEntityCoords(cache.ped, coords)
					SetEntityHeading(cache.ped, coords.w)
					FreezeEntityPosition(cache.ped, true)
					local newProgress = nil
					for i= 1, exports.wtr_vineyard:getAmountPreload("fill") do
						lib.requestAnimDict('pickup_object')
						TaskPlayAnim(cache.ped, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
						local prop = Utils.createProp("prop_wine_bot_01", vec3(tapCoords.x + 0.02, tapCoords.y - 0.232, coords.z -10), false, true)
						FreezeEntityPosition(prop, false)
						AttachEntityToEntity(prop, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.087, -0.121, -0.102, -73.06, 0.84, -10.62, true, true, false, false, 0, true)
						Wait(980)
						DeleteEntity(prop)
						local prop = Utils.createProp("prop_wine_bot_01", vec3(tapCoords.x + 0.02, tapCoords.y - 0.232, coords.z), false, true)
						SetTimeout(5000, function()
							DeleteEntity(prop)
						end)

						for k = 1, 5 do
							local progress = newProgress or ((math.floor((k * 100) / (exports.wtr_vineyard:getAmountPreload("fill")))) / 5)
						
							lib.showTextUI(("**Vignoble**  \n*Remplissage en cours:* **%s%%**"):format(tostring(progress)), {position = "left-center", icon = "fas fa-leaf", iconColor = "#FFFFFF"}) 
							newProgress = progress + (((math.floor((1 * 100) / (exports.wtr_vineyard:getAmountPreload("fill")))) / 5))
							Wait(1000)
						end
					end
					lib.showTextUI(("**Vignoble**  \n*Remplissage en cours:* **%s%%**"):format(tostring(100.0)), {position = "left-center", icon = "fas fa-leaf", iconColor = "#FFFFFF"}) 
					Wait(300)
					lib.hideTextUI()
					FreezeEntityPosition(cache.ped, false)
					exports.ox_target:disableTargeting(false)
					lib.callback.await("wtr_vineyard:server:setupItems", false, "give", fillInfo[i].add.itemName, (fillInfo[i].add.count * exports.wtr_vineyard:getAmountPreload("fill")))
					lib.callback.await("wtr_vineyard:server:setFilled", false, id, nil)
				end
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:fillMenu",
		title = "Remplissage",
		options = options
	})
	lib.showContext("wtr_vineyard:fillMenu")
end

function initFill()
	for i = 1, #Config.fill.props.barrel.locations do
		local prop = Utils.createProp(Config.fill.props.barrel.model, Config.fill.props.barrel.locations[i].spawn, true)
		propsLoaded[#propsLoaded + 1] = prop

		exports.ox_target:addLocalEntity(prop, {
			{
				label = "Remplissage",
				groups = Config.fill.job.active and {[Config.fill.job.name] = Config.fill.job.grade} or nil,
				icon = "fas fa-leaf",
				onSelect = function()
					initFillMenu(Config.fill.props.barrel.locations[i].player, Config.fill.props.tap.locations[i], i)
				end,
				distance = 2.0,
			}
		})
	end

	for i = 1, #Config.fill.props.tap.locations do
		local prop = Utils.createProp(Config.fill.props.tap.model, Config.fill.props.tap.locations[i], false)

		propsLoaded[#propsLoaded + 1] = prop
	end
end
exports("InitFill", initFill)

function destroyFill()
	for k, v in pairs(propsLoaded) do
		if DoesEntityExist(v) then DeleteEntity(v) end
	end
end
exports("DestroyFill", destroyFill)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() == resource then
		for k, v in pairs(propsLoaded) do
			if DoesEntityExist(v) then DeleteEntity(v) end
		end
	end
end)