local Config = require("shared.shared")
local Utils = require("client.utils")

local pointsLoaded = {}

local function proceedLabeling(id, amountPreload, data)
	local label = Config.labeling.props.table.locations[id]
	local coords = label.player

	SetEntityCoords(cache.ped, coords)
	SetEntityHeading(cache.ped, coords.w)

	local progress = Writer.SendProgress({
		label = "Étiquetage en cours..",
		duration = ((Config.labeling.duration * 1000) * amountPreload),
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			car = true,
			combat = true
		},
		anim = {
			dict = 'mp_arresting',
			clip = 'a_uncuff'
		},
		prop = {
			model = "prop_wine_bot_01",
			bone = 57005,
			pos = vec3(0.005, 0.024, -0.031),
			rot = vec3(-45.78, 22.05, -65.19),
		}
	}) 

	return progress
end
lib.callback.register("wtr_vineyard:client:proceedLabeling", proceedLabeling)

local function initLabelingMenu(id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("labeling")

	options[#options + 1] = {
		title = ("Multiplicateur: **%d**"):format(amountPreload),
		icon = "fas fa-circle-info",
		description = "*Le multiplicateur permet de faire l'étiquettage de plusieurs bouteilles à la fois au lieu de ré-ouvrir le menu pour recommencer l'action*",
		arrow = true,
		onSelect = function()
			local predefinedAmount, amount = exports.wtr_vineyard:predefinedAmount("labeling")
			if not predefinedAmount then
				initLabelingMenu(id)
				return
			end

			exports.wtr_vineyard:setAmountPreload(amount)
			Wait(10)
			Writer.Notify(("Multiplicateur ajusté à %d"):format(amount), "success")
			initLabelingMenu(id)
		end
	}
	for i = 1, #Config.labeling.types do
		local label = Config.labeling.types[i]
		local canProceed = Writer.CanCraft(label.required, amountPreload)
		local animDuration = (amountPreload * Config.labeling.duration)

		options[#options + 1] = {
			title = Writer.GetLabelDescription(label.add, amountPreload, ", ", true),
			description = ("%s%s"):format(Writer.GetLabelDescription(label.required, amountPreload, " \n", false), (" \n\n**Temps d'étiquettage**: %d seconde%s"):format(animDuration, animDuration > 1 and "s" or "")),
			icon = #label.add > 1 and "fas fa-boxes" or Writer.GetImage(label.add[1].name),
			arrow = canProceed,
			disabled = not canProceed,
			onSelect = function()
				local pass = lib.callback.await("wtr_vineyard:server:proceedLabeling", false, id, amountPreload, label)
				if pass then 
					Writer.Notify(("Vous avez étiquetté %d bouteille%s avec succès"):format(amountPreload, amountPreload > 1 and "s" or ""))
				end
			end
		}
	end

	lib.registerContext({
		id = "wtr_vineyard:labelingMenu",
		title = "Étiqueter",
		options = options
	})
	lib.showContext("wtr_vineyard:labelingMenu")
end

function initLabeling()
	for k, v in pairs(Config.labeling.props.table.locations) do
		local point = lib.points.new({
			coords = v.spawn,
			heading = v.spawn.w,
			distance = 30,
			model = nil,
			box = nil
		})

		function point:onEnter()
			if not self.model then
				self.model = Utils.createProp(Config.labeling.props.table.model, vec4(self.coords.x, self.coords.y, self.coords.z, self.heading), true)

				local offset = GetOffsetFromEntityInWorldCoords(self.model, Config.labeling.props.box.offset)
				self.box = Utils.createProp(Config.labeling.props.box.model, vec4(offset.x, offset.y, offset.z, self.heading), true)

				exports.ox_target:addLocalEntity(self.model, {
					{
						label = "Étiqueter",
						icon = "fas fa-leaf",
						groups = Config.labeling.job.active and {[Config.labeling.job.name] = Config.labeling.job.grade} or nil,
						onSelect = function()
							initLabelingMenu(k)
						end,
						distance = 2.0,
					}
				})
			end
		end

		function point:onExit()
			if self.model then
				if DoesEntityExist(self.model) then DeleteEntity(self.model) end
				self.model = nil
			end

			if self.box then
				if DoesEntityExist(self.box) then DeleteEntity(self.box) end
				self.box = nil
			end
		end

		pointsLoaded[#pointsLoaded + 1] = point
	end
end

CreateThread(function()
	while not Writer.IsLoaded() do Wait(10) end

	initLabeling()
end)

AddEventHandler("onResourceStop", function(resource)
	if cache.resource == resource then
		for k, v in pairs(pointsLoaded) do
			if v.model then
				if DoesEntityExist(v.model) then DeleteEntity(v.model) end
			end

			if v.box then
				if DoesEntityExist(v.box) then DeleteEntity(v.box) end
			end
		end
	end
end)