local Config = require("shared.shared")
local Utils = require("client.utils")
local areas = require("shared.areas")

local insideArea = false
local pointsLoaded = {}
local plyState = LocalPlayer.state

local inCooldown = false

local keybind = lib.addKeybind({
    name = 'respects',
    description = 'Récolter des raisins',
    defaultKey = 'E',
})
keybind:disable(true)

local function proceedHarvest(spotCoords, harvestData)
	TaskTurnPedToFaceCoord(cache.ped, spotCoords, 10)

	local progress = Writer.SendProgress({
		duration = (harvestData.harvestTime * 1000),
		label = harvestData.progressBar.label or "Récolte en cours",
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			car = true,
			combat = true,
		},
		anim = harvestData.progressBar.anim,
		prop = harvestData.progressBar.prop
	})

	return progress
end
lib.callback.register("wtr_vineyard:client:proceedHarvest", proceedHarvest)

CreateThread(function()
	while not LocalPlayer.state.isLoggedIn do Wait(30) end

	plyState:set("vineyard:collecting", false, true)

	for name, locations in pairs(areas) do
		local zoneInfo = Utils.getInfoFromName(name)

		for id, zones in ipairs(locations) do
			if zones.points then
				lib.zones.poly({
					points = zones.points,
					thickness = zones.thickness,
					debug = Config.debugPoly,
					onEnter = function()
						local playerJob = Writer.GetJob()

						if (Writer.GetTableSize(zones.harvestLocations or {}) > 0) then
							for spotId, spotCoords in pairs(zones.harvestLocations) do
								local coords = spotCoords

								local point = lib.points.new({
									coords = coords,
									distance = 10.0,
								})

								local r, g, b = lib.math.hextorgb(Config.harvest[zoneInfo].color)
								local marker = lib.marker.new({
									type = 2,
									width = 0.5,
									height = 0.5,
									rotation = vec3(180.0, 0.0, 0.0),
									bobUpAndDown = true,
									faceCamera = true,
									coords = vec3(coords.x, coords.y, coords.z + 1.0),
									color = {r = r, g = g, b = b, a = 0.8},
								})

								function point:nearby()
									local canPass = false

									if Config.harvest[zoneInfo].job.active then
										if playerJob.name == Config.harvest[zoneInfo].job.name and playerJob.grade >= Config.harvest[zoneInfo].job.grade then
											canPass = true
										else
											canPass = false
										end
									else
										canPass = true
									end

									if canPass then
										if self.currentDistance < 3.2 then
											if self.currentDistance <= 3.0 then
												marker:draw()
											end

										
											if self.currentDistance <= 1.7 then
												if not plyState["vineyard:collecting"] then
													keybind:disable(false)
													keybind.onPressed = function(keybindData)
														if not inCooldown then
															if insideArea and not plyState["vineyard:collecting"] then

																inCooldown = true
																SetTimeout(1500, function()
																	inCooldown = false
																end)

																TriggerServerEvent("wtr_vineyard:server:proceedHarvest", Config.harvest[zoneInfo], spotId, spotCoords, name)
															else
																inCooldown = true
																SetTimeout(1500, function()
																	inCooldown = false
																end)
															end
														else
															Writer.Notify("Ça ne sert à rien de spam", "error")
														end
													end

													lib.showTextUI(("**Vignoble**  \n*[%s] - Récolter*"):format(keybind.currentKey), {icon = "fas fa-leaf", iconColor = Config.harvest[zoneInfo].color, position = "left-center"})
												end
											elseif self.currentDistance > 2.0 then
												keybind:disable(false)
												keybind.onPressed = function(keybindData) end
												lib.hideTextUI()
											end
										end
									end
								end

								pointsLoaded[#pointsLoaded + 1] = point
							end
						end

						lib.showTextUI(("**Vignoble**  \n*Type de champ: %s*"):format(Writer.FirstToUpper(Config.harvest[zoneInfo].label:lower())), {icon = "fas fa-leaf", iconColor = Config.harvest[zoneInfo].color, position = "left-center"})
						insideArea = true

						SetTimeout(5000, function()
							local isOpen, text = lib.isTextUIOpen()
							if isOpen then
								if text == ("**Vignoble**  \n*Type de champ: %s*"):format(Writer.FirstToUpper(Config.harvest[zoneInfo].label:lower())) then
									lib.hideTextUI()
								end
							end
						end)

					end,
					onExit = function()
						if #pointsLoaded > 0 then
							for k,v in pairs(pointsLoaded) do
								v:remove()
							end
						end

						insideArea = false
					end
				})
			end
		end
	end
end)