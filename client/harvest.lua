local Config = require("shared.shared")
local Utils = require("client.utils")
local areas = require("shared.areas")
local insideArea = false
local canHarvest = false
local pointsLoaded = {}
local particlesLoaded = {}

local QBCore = exports["qb-core"]:GetCoreObject()
local playerJob = {}

local harvestData = {
	id = nil,
	name = nil,
	harvestId = nil,
	coords = nil
}

local keybind = lib.addKeybind({
    name = 'respects',
    description = 'Récolter des raisins',
    defaultKey = 'E',
    onPressed = function(self)
		if insideArea and canHarvest then
			local isHarvested, data = lib.callback.await("wtr_vineyard:server:isHarvested", false, harvestData.name, harvestData.id, harvestData.harvestId)

			if not isHarvested then
				local zoneInfo = Utils.getInfoFromName(harvestData.name)

				if Config.harvest[zoneInfo].job.active then
					if playerJob.name == Config.harvest[zoneInfo].job.name and playerJob.grade.level >= Config.harvest[zoneInfo].job.grade then
					else
						if playerJob.name == Config.harvest[zoneInfo].job.name and playerJob.grade.level < Config.harvest[zoneInfo].job.grade then
							lib.notify({description = "Vous n'avez pas le grade requis pour récolter des raisins", type = "error"})
							return
						else
							lib.notify({description = "Vous n'avez pas l'emploi requis pour récolter des raisins", type = "error"})
							return
						end
					end
				end

				self:disable(true)
				lib.callback.await("wtr_vineyard:server:setHarvested", false, harvestData.name, harvestData.id, harvestData.harvestId, Config.harvest[zoneInfo].cooldown)
				TaskTurnPedToFaceCoord(cache.ped, harvestData.coords, 1000)

				if lib.progressCircle({
					duration = (Config.harvest[zoneInfo].harvestTime * 1000),
					label = "Récolte en cours..",
					position = 'bottom',
					useWhileDead = false,
					canCancel = false,
					disable = {
						move = true,
						car = true,
						combat = true,
					},
					anim = {
						dict = 'amb@prop_human_movie_bulb@idle_a',
						clip = 'idle_b'
					},
				})
				then
					self:disable(false)
					lib.notify({description = "Vigne récoltée avec succès", type = "success"})

					for k,v in pairs(Config.harvest[zoneInfo].items) do
						lib.callback.await("wtr_vineyard:server:setupItems", false, "give", v.name, math.random(v.count.min, v.count.max))
					end
				end
			else
				lib.notify({description = ("Cette vigne est déjà récoltée (Revenez dans %s)"):format(Utils.getFormatTime(data.cooldown)), type = "error"})
			end
		end
    end,
})

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
	playerJob = job
end)

CreateThread(function()
	while not LocalPlayer.state.isLoggedIn do Wait(30) end

	playerJob = QBCore.Functions.GetPlayerData().job

	for name, locations in pairs(areas) do
		local zoneInfo = Utils.getInfoFromName(name)

		for id, zones in ipairs(locations) do
			if zones.points then
				lib.zones.poly({
					points = zones.points,
					thickness = zones.thickness,
					debug = Config.debugPoly,
					onEnter = function()
						if zones.harvestLocations and #zones.harvestLocations > 0 then
							for i = 1, #zones.harvestLocations do
								local coords = zones.harvestLocations[i]

								lib.requestNamedPtfxAsset("core")
								UseParticleFxAssetNextCall("core")
								local particles = StartParticleFxLoopedAtCoord("fire_wrecked_plane_cockpit", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.01, false, false, false, false)

								local point = lib.points.new({
									coords = coords,
									distance = 1.7,
								})

								function point:onEnter()
									canHarvest = true
									harvestData = {
										id = id,
										name = name,
										harvestId = i,
										coords = coords
									}
									lib.showTextUI(("**Vignoble**  \n*[%s] - Récolter*"):format(keybind.currentKey), {icon = "fas fa-leaf", iconColor = Config.harvest[zoneInfo].color, position = "left-center"})
								end

								function point:onExit()
									canHarvest = false
									harvestData = {
										id = nil,
										name = nil,
										harvestId = nil,
										coords = nil
									}
									lib.hideTextUI()
								end

								pointsLoaded[#pointsLoaded + 1] = point
								particlesLoaded[#particlesLoaded + 1] = particles
							end
						end
						lib.showTextUI(("**Vignoble**  \n*Type de champ: %s*"):format(Config.harvest[zoneInfo].label:lower()), {icon = "fas fa-leaf", iconColor = Config.harvest[zoneInfo].color, position = "left-center"})
						insideArea = true
						Wait(5000)

						local isOpen, text = lib.isTextUIOpen()
						if isOpen then
							if text == ("**Vignoble**  \n*Type de champ: %s*"):format(Config.harvest[zoneInfo].label:lower()) then
								lib.hideTextUI()
							end
						end
					end,
					onExit = function()
						if #particlesLoaded > 0 then
							for k, v in pairs(particlesLoaded) do
								StopParticleFxLooped(v, 0)
							end
						end

						if #pointsLoaded > 0 then
							for k,v in pairs(pointsLoaded) do
								v:remove()
							end
						end

						lib.hideTextUI()
						insideArea = false
					end
				})
			end
		end
	end
end)