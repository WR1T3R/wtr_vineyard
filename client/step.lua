local Config = require("shared.shared")
local Utils = require("client.utils")

local propsLoaded = {}

local function canCraft(items)
	local itemsIn = 0

	for i = 1, #items do
		local count = exports.ox_inventory:GetItemCount(items[i].itemName)

		if count >= (items[i].count * exports.wtr_vineyard:getAmountPreload("step")) then itemsIn += 1 end
	end

	return #items == itemsIn
end

local function getRequiredLabel(items)
	a = 0
	label = ""

	for _, v in pairs(items) do
		label = string.format("%s%sx %s", label, (v.count * exports.wtr_vineyard:getAmountPreload("step")), exports.ox_inventory:Items(v.itemName).label)
		if a ~= #items - 1 then label = ("%s\n"):format(label) end
		a += 1
	end

	return label
end
exports.ox_target:disableTargeting(false)
local function initStepMenu(coords, id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("step")

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
			initStepMenu(coords, id)
		end
	}
	for i = 1, #Config.step.types do
		local itemCount = exports.ox_inventory:GetItemCount(Config.step.types[i].itemName)
		local itemInfo = exports.ox_inventory:Items(Config.step.types[i].add.itemName)

		options[#options + 1] = {
			title = ("%dx %s"):format((Config.step.types[i].add.count * exports.wtr_vineyard:getAmountPreload("step")), itemInfo.label),
			description = getRequiredLabel(Config.step.types[i].required),
			icon = itemInfo.client.image,
			arrow = canCraft(Config.step.types[i].required),
			disabled = not canCraft(Config.step.types[i].required),
			onSelect = function()
				if canCraft(Config.step.types[i].required) then

					local isStepped = lib.callback.await("wtr_vineyard:server:isStepped", false, id)
					if isStepped then lib.notify({description = "Cette station est occupée", type = "error"}) return end

					exports.ox_target:disableTargeting(true)
					lib.callback.await("wtr_vineyard:server:setStepped", false, id, true)
					local entityData = {
						coords = GetEntityCoords(cache.ped),
						heading = GetEntityHeading(cache.ped),
					}

					for k, v in pairs(Config.step.types[i].required) do
						if v.remove then
							lib.callback.await("wtr_vineyard:server:setupItems", false, "remove", v.itemName, (v.count * exports.wtr_vineyard:getAmountPreload("step")))
						end
					end

					local propsName = Utils.createProp(Config.step.types[i].propName, vec4(coords.x, coords.y, coords.z - 0.7, coords.w), false, true)
					while not DoesEntityExist(propsName) do Wait(10) end

					lib.requestNamedPtfxAsset("core")
					UseParticleFxAssetNextCall("core")
					local particles = StartParticleFxLoopedAtCoord(Config.step.types[i].particles, coords.x, coords.y, coords.z - 0.7, 0.0, 0.0, 0.0, 2.0, 0.01, false, false, false, false)

					SetEntityCoords(cache.ped, vec3(coords.x, coords.y, coords.z - 1.0))
					SetEntityHeading(cache.ped, coords.w - 90)

					local amountToCheck = Config.step.types[i].add.count
					for i = 1, (Config.step.duration * (Config.step.types[i].add.count * exports.wtr_vineyard:getAmountPreload("step"))) do
						local progress = math.floor((i * 100) / (Config.step.duration * (amountToCheck * exports.wtr_vineyard:getAmountPreload("step"))))
						
						lib.showTextUI(("**Vignoble**  \n*Pressage en cours:* **%s%%**"):format(tostring(progress)), {position = "left-center", icon = "fas fa-leaf", iconColor = "#FFFFFF"})
						FreezeEntityPosition(cache.ped, false)
						ClearPedTasks(cache.ped)

						FreezeEntityPosition(cache.ped, true)
						TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_JOG_STANDING', -1, true)
						Wait(1000)
					end

					lib.hideTextUI()
					FreezeEntityPosition(cache.ped, false)
					ClearPedTasksImmediately(cache.ped)
					DeleteEntity(propsName)
					StopParticleFxLooped(particles, 0)
					SetEntityCoords(cache.ped, entityData.coords.x, entityData.coords.y, entityData.coords.z - 1.0)
					SetEntityHeading(cache.ped, entityData.heading)

					lib.callback.await("wtr_vineyard:server:setupItems", false, "give", Config.step.types[i].add.itemName, (Config.step.types[i].add.count * exports.wtr_vineyard:getAmountPreload("step")))
					lib.callback.await("wtr_vineyard:server:setStepped", false, id, nil)
					exports.ox_target:disableTargeting(false)
				end
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:stepMenu",
		title = "Pressage de raisins",
		options = options
	})
	lib.showContext("wtr_vineyard:stepMenu")
end

function initStep()
	for i = 1, #Config.step.props.locations do
		local prop = Utils.createProp(Config.step.props.model, Config.step.props.locations[i], true)
		propsLoaded[#propsLoaded + 1] = prop

		exports.ox_target:addLocalEntity(prop, {
			{
				label = "Pressage de raisins",
				groups = Config.step.job.active and {[Config.step.job.name] = Config.step.job.grade} or nil,
				icon = "fas fa-leaf",
				onSelect = function()
					initStepMenu(Config.step.props.locations[i], i)
				end,
				distance = 2.0
			}
		})
	end
end
exports("InitStep", initStep)

function destroyStep()
	for k, v in pairs(propsLoaded) do
		if DoesEntityExist(v) then DeleteEntity(v) end
	end
end
exports("DestroyStep", destroyStep)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() == resource then
		for k, v in pairs(propsLoaded) do
			if DoesEntityExist(v) then DeleteEntity(v) end
		end
	end
end)