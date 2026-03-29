local Config = require("shared.shared")
local Utils = require("client.utils")

local pointsLoaded = {}

local function proceedStep(id, amountPreload, data)
	local step = Config.step.props.locations[id]
	local coords = step.spawn

	local lastData = {
		coords = GetEntityCoords(cache.ped),
		heading = GetEntityHeading(cache.ped),
	}

	local prop = Utils.createProp(data.propName, vec4(coords.x, coords.y, coords.z - 0.7, coords.w), false, true)
	while not DoesEntityExist(prop) do Wait(10) end

	lib.requestNamedPtfxAsset("core")
	UseParticleFxAssetNextCall("core")
	local particles = StartParticleFxLoopedAtCoord(data.particles, coords.x, coords.y, coords.z - 0.7, 0.0, 0.0, 0.0, 2.0, 0.01, false, false, false, false)

	SetEntityCoords(cache.ped, vec3(coords.x, coords.y, coords.z - 1.0))
	SetEntityHeading(cache.ped, coords.w - 90)

	local duration = (Config.step.duration * amountPreload)
	CreateThread(function()
		for i = 1, duration do		
			FreezeEntityPosition(cache.ped, false)
			ClearPedTasks(cache.ped)

			FreezeEntityPosition(cache.ped, true)
			TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_JOG_STANDING', -1, true)
			Wait(1000)
		end
	end)

	local progress = Writer.SendProgress({
		duration = duration * 1000,
		label = "Pressage en cours..",
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
			mouse = false,
			car = true
		},
	})

	FreezeEntityPosition(cache.ped, false)
	ClearPedTasksImmediately(cache.ped)
	DeleteEntity(prop)
	StopParticleFxLooped(particles, 0)
	SetEntityCoords(cache.ped, lastData.coords.x, lastData.coords.y, lastData.coords.z - 1.0)
	SetEntityHeading(cache.ped, lastData.heading)

	return progress
end
lib.callback.register("wtr_vineyard:client:proceedStep", proceedStep)

local function initStepMenu(id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("step")

	options[#options + 1] = {
		title = ("Multiplicateur: **%d**"):format(amountPreload),
		icon = "fas fa-circle-info",
		description = "*Le multiplicateur permet de faire la presse de plusieurs raisins à la fois au lieu de ré-ouvrir le menu pour recommencer l'action*",
		arrow = true,
		onSelect = function()
			local predefinedAmount, amount = exports.wtr_vineyard:predefinedAmount("step")
			if not predefinedAmount then
				initStepMenu(id)
				return
			end

			exports.wtr_vineyard:setAmountPreload(amount)
			Wait(10)
			Writer.Notify(("Multiplicateur ajusté à %d"):format(amount), "success")
			initStepMenu(id)
		end
	}

	for i = 1, #Config.step.types do
		local step = Config.step.types[i]
		local canProceed = Writer.CanCraft(step.required, amountPreload)
		local animDuration = (amountPreload * Config.step.duration)

		options[#options + 1] = {
			title = Writer.GetLabelDescription(step.add, amountPreload, ", ", true),
			description = ("%s%s"):format(Writer.GetLabelDescription(step.required, amountPreload, " \n", false), (" \n\n**Temps de remplissage**: %d seconde%s"):format(animDuration, animDuration > 1 and "s" or "")),
			icon = #step.add > 1 and "fas fa-boxes" or Writer.GetImage(step.add[1].name),
			arrow = canProceed,
			disabled = not canProceed,
			onSelect = function()
				local pass = lib.callback.await("wtr_vineyard:server:proceedStep", false, id, amountPreload, step)
				if pass then
					Writer.Notify(("Vous avez pressé %d raisin%s avec succès"):format(amountPreload, amountPreload > 1 and "s" or ""))
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

CreateThread(function()
	while not Writer.IsLoaded() do Wait(10) end

	for k, v in pairs(Config.step.props.locations) do
		local point = lib.points.new({
			coords = v.spawn,
			heading = v.spawn.w or 0.0,
			distance = 30,
			model = nil
		})

		function point:onEnter()
			if not self.model then
				self.model = Utils.createProp(Config.step.props.model, vec4(self.coords.x, self.coords.y, self.coords.z, self.heading), true)

				exports.ox_target:addLocalEntity(self.model, {
					{
						label = "Pressage de raisins",
						groups = Config.step.job.active and {[Config.step.job.name] = Config.step.job.grade} or nil,
						icon = "fas fa-leaf",
						onSelect = function()
							initStepMenu(k)
						end,
						distance = 2.0
					}
				})
			end
		end

		function point:onExit()
			if self.model then
				if DoesEntityExist(self.model) then DeleteEntity(self.model) end
				self.model = nil
			end
		end
	end

	pointsLoaded[#pointsLoaded + 1] = point
end)

AddEventHandler("onResourceStop", function(resource)
	if cache.resource == resource then
		for k, v in pairs(pointsLoaded) do
			if DoesEntityExist(v.model) then DeleteEntity(v.model) end
		end
	end
end)