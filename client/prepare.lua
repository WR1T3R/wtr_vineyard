local Config = require("shared.shared")
local Utils = require("client.utils")

local pointsLoaded = {}

local function proceedPrepare(id, amountPreload, data)
	local prepare = Config.prepare.props.table.locations[id]
	local coords = prepare.player

	lib.print.info(data.propsTable)

	SetEntityCoords(cache.ped, coords)
	SetEntityHeading(cache.ped, coords.w)

	local newTable = {}
	for k, v in pairs(data.propsTable) do
		v.prop = joaat(v.prop)
		v.model = v.prop
		v.prop = nil
		newTable[k] = v
	end

	lib.print.info(newTable)
	local progress = Writer.SendProgress({
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
		anim = Config.prepare.animation,
		prop = newTable
	})

	return progress
end
lib.callback.register("wtr_vineyard:client:proceedPrepare", proceedPrepare)

local function initPrepareMenu(id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("prepare")

	options[#options + 1] = {
		title = ("Multiplicateur: **%d**"):format(amountPreload),
		icon = "fas fa-circle-info",
		description = "*Le multiplicateur permet de faire la préparation de plusieurs raisins à la fois au lieu de ré-ouvrir le menu pour recommencer l'action*",
		arrow = true,
		onSelect = function()
			local predefinedAmount, amount = exports.wtr_vineyard:predefinedAmount("prepare")
			if not predefinedAmount then
				initPrepareMenu(id)
				return
			end

			exports.wtr_vineyard:setAmountPreload(amount)
			Wait(10)
			Writer.Notify(("Multiplicateur ajusté à %d"):format(amount), "success")
			initPrepareMenu(id)
		end
	}

	for i = 1, #Config.prepare.types do
		local prepare = Config.prepare.types[i]
		local canProceed = Writer.CanCraft(prepare.required, amountPreload)
		local animDuration = (amountPreload * Config.prepare.duration)

		options[#options + 1] = {
			title = Writer.GetLabelDescription(prepare.add, amountPreload, ", ", true),
			description = ("%s%s"):format(Writer.GetLabelDescription(prepare.required, amountPreload, " \n", false), (" \n\n**Temps de préparation**: %d seconde%s"):format(animDuration, animDuration > 1 and "s" or "")),
			icon = #prepare.add > 1 and "fas fa-boxes" or Writer.GetImage(prepare.add[1].name),
			arrow = canProceed,
			disabled = not canProceed,
			onSelect = function()
				local pass = lib.callback.await("wtr_vineyard:server:proceedPrepare", false, id, amountPreload, prepare)
				if pass then
					Writer.Notify(("Vous avez préparé %d raisin%s avec succès"):format(amountPreload, amountPreload > 1 and "s" or ""))
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
	for k, v in pairs(Config.prepare.props.table.locations) do
		local point = lib.points.new({
			coords = v.spawn,
			heading = v.spawn.w,
			distance = 30,
			model = nil,
			box = nil
		})

		function point:onEnter()
			self.model = Utils.createProp(Config.prepare.props.table.model, vec4(self.coords.x, self.coords.y, self.coords.z, self.heading), true)

			local offset = GetOffsetFromEntityInWorldCoords(self.model, Config.prepare.props.box.offset)
			self.box = Utils.createProp(Config.prepare.props.box.model, vec4(offset.x, offset.y, offset.z, self.heading), true)
			exports.ox_target:addLocalEntity(self.model, {
				{
					label = "Préparation de raisins",
					groups = Config.prepare.job.active and {[Config.prepare.job.name] = Config.prepare.job.grade} or nil,
					icon = "fas fa-leaf",
					onSelect = function()
						initPrepareMenu(k)
					end,
					distance = 2.0,
				}
			})
		end

		function point:onExit()
			if self.model then
				if DoesEntityExist(self.model) then DeleteEntity(self.model) end
			end

			if self.box then
				if DoesEntityExist(self.box) then DeleteEntity(self.box) end
			end
		end

		pointsLoaded[#pointsLoaded + 1] = point
	end
end

CreateThread(function()
	while not Writer.IsLoaded do Wait(10) end

	initPrepare()
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