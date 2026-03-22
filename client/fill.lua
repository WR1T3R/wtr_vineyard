local Config = require("shared.shared")
local Utils = require("client.utils")

local propsLoaded = {}

local function proceedAnimation(id, amountPreload, data, tapCoords)
	if not id then return false end
	if not amountPreload then return false end
	if not data then return false end
	if not tapCoords then return false end

	local newProgress = nil
	local inProgress = true
	local coords = Config.fill.props.barrel.locations[id].player

	SetEntityCoords(cache.ped, coords)
	SetEntityHeading(cache.ped, coords.w)

	lib.requestAnimDict('pickup_object')
	TaskPlayAnim(cache.ped, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
	local prop = Utils.createProp("prop_wine_bot_01", vec3(tapCoords.x + 0.02, tapCoords.y - 0.232, coords.z -10), false, true)

	FreezeEntityPosition(prop, false)
	AttachEntityToEntity(prop, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.087, -0.121, -0.102, -73.06, 0.84, -10.62, true, true, false, false, 0, true)
	Wait(980)
	DeleteEntity(prop)

	local animDuration = (amountPreload * Config.fill.duration) * 1000
	local prop = Utils.createProp("prop_wine_bot_01", vec3(tapCoords.x + 0.02, tapCoords.y - 0.232, coords.z), false, true)

	SetTimeout(animDuration, function()
		DeleteEntity(prop)
	end)
	
	if Writer.SendProgress({
		duration = animDuration,
		label = "Remplissage en cours..",
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
			mouse = false,
			car = true
		},
		anim = Config.fill.animation
	}) 
	then
		lib.hideTextUI() 
		return true
	else 
		lib.hideTextUI()
		return false 
	end
end
lib.callback.register("wtr_vineyard:client:proceedFilling", proceedAnimation)

local function initFillMenu(id, tapCoords)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("fill")

	options[#options + 1] = {
		title = ("Multiplicateur: **%d**"):format(amountPreload),
		icon = "fas fa-circle-info",
		description = ("*Le multiplicateur permet de faire le remplissage de plusieurs bouteilles à la fois au lieu de ré-ouvrir le menu pour recommencer l'action*"):format(Config.maxPredefinedAmount["fill"] or 1),
		arrow = true,
		onSelect = function()
			local predefinedAmount, amount = exports.wtr_vineyard:predefinedAmount("fill")
			if not predefinedAmount then
				initFillMenu(id, tapCoords)
				return
			end

			exports.wtr_vineyard:setAmountPreload(amount)
			Wait(10)
			Writer.Notify(("Multiplicateur ajusté à %d"):format(amount), "success")
			initFillMenu(id, tapCoords)
		end
	}
	for i = 1, #Config.fill.types do
		local fill = Config.fill.types[i]
		local canProceed = Writer.CanCraft(fill.required, amountPreload)
		local animDuration = (amountPreload * Config.fill.duration)

		options[#options + 1] = {
			title = Writer.GetLabelDescription(fill.add, amountPreload, ", ", true),
			description = Writer.GetLabelDescription(fill.required, amountPreload, " \n", false).. (" \n\n**Temps de remplissage**: %d seconde%s"):format(animDuration, animDuration > 1 and "s" or ""),
			icon = #fill.add > 1 and "fas fa-boxes" or Writer.GetImage(fill.add[1].name),
			arrow = canProceed,
			disabled = not canProceed,
			onSelect = function()
				local pass = lib.callback.await("wtr_vineyard:server:proceedFilling", false, id, amountPreload, fill, tapCoords)
				if pass then
					Writer.Notify(("Vous avez rempli %d bouteille%s avec succès"):format(amountPreload, amountPreload > 1 and "s" or ""))
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
	for k, v in pairs(Config.fill.props.barrel.locations) do
		local prop = Utils.createProp(Config.fill.props.barrel.model, v.spawn, true)
		propsLoaded[#propsLoaded + 1] = prop

		local offset = GetOffsetFromEntityInWorldCoords(prop, Config.fill.props.tap.offset)
		local tapProp = Utils.createProp(Config.fill.props.tap.model, vec4(offset.x, offset.y, offset.z, GetEntityHeading(prop)), false)

		propsLoaded[#propsLoaded + 1] = tapProp
		exports.ox_target:addLocalEntity(prop, {
			{
				label = "Remplissage",
				groups = Config.fill.job.active and {[Config.fill.job.name] = Config.fill.job.grade} or nil,
				icon = "fas fa-wine-glass",
				onSelect = function()
					local tapCoords = GetEntityCoords(tapProp)
					local tapHeading = GetEntityHeading(tapProp)

					initFillMenu(k, vec4(tapCoords.x, tapCoords.y, tapCoords.z, tapHeading))
				end,
				distance = 2.0,
			}
		})
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