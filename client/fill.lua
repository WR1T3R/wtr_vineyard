local Config = require("shared.shared")
local Utils = require("client.utils")

local pointsLoaded = {}

local boxLoaded = {}
local function formatFillBottles(id, amountPreload)
	local barrel = pointsLoaded[id].model
	local heading = pointsLoaded[id].heading - 90.0

	local barrelOffset = GetOffsetFromEntityInWorldCoords(barrel, vec3(0.0, 0.8, 0.0))
	local box = Utils.createProp("ng_proc_crate_03a", vec4(barrelOffset.x, barrelOffset.y, barrelOffset.z, heading), true, true)
	boxLoaded[#boxLoaded + 1] = box

	local tableOffset = {
		[1] = vec3(0.27, -0.18, 0.0),
		[2] = vec3(0.16, -0.18, 0.0),
		[3] = vec3(0.06, -0.18, 0.0),
		[4] = vec3(-0.06, -0.18, 0.0),
		[5] = vec3(-0.16, -0.18, 0.0),
		[6] = vec3(-0.27, -0.18, 0.0),

		[7] = vec3(0.27, -0.06, 0.0),
		[8] = vec3(0.16, -0.06, 0.0),
		[9] = vec3(0.06, -0.06, 0.0),
		[10] = vec3(-0.06, -0.06, 0.0),
		[11] = vec3(-0.16, -0.06, 0.0),
		[12] = vec3(-0.27, -0.06, 0.0),

		[13] = vec3(0.27, 0.06, 0.0),
		[14] = vec3(0.16, 0.06, 0.0),
		[15] = vec3(0.06, 0.06, 0.0),
		[16] = vec3(-0.06, 0.06, 0.0),
		[17] = vec3(-0.16, 0.06, 0.0),
		[18] = vec3(-0.27, 0.06, 0.0),

		[19] = vec3(0.27, 0.18, 0.0),
		[20] = vec3(0.16, 0.18, 0.0),
		[21] = vec3(0.06, 0.18, 0.0),
		[22] = vec3(-0.06, 0.18, 0.0),
		[23] = vec3(-0.16, 0.18, 0.0),
		[24] = vec3(-0.27, 0.18, 0.0)
	}

	local duration = (Config.fill.duration * amountPreload) * 1000

	SetTimeout(duration + 100, function()
		for k, v in pairs(boxLoaded) do
			DeleteEntity(v)
		end
		boxLoaded = {}
	end)

	for i = 1, amountPreload do
		Wait(Config.fill.duration * 1000)
		if tableOffset[i] then
			local boxOffset = GetOffsetFromEntityInWorldCoords(box, tableOffset[i])
			local bottle = Utils.createProp("prop_wine_bot_01", vec4(boxOffset.x, boxOffset.y, boxOffset.z, heading), true, true)

			boxLoaded[#boxLoaded + 1] = bottle
		end
	end
end

local function proceedAnimation(id, amountPreload, data)
	if not id then return false end
	if not amountPreload then return false end
	if not data then return false end

	local coords = Config.fill.props.barrel.locations[id].player

	SetEntityCoords(cache.ped, coords)
	SetEntityHeading(cache.ped, coords.w)

	local tap = pointsLoaded[id].tap
	local tapCoords = GetEntityCoords(tap)

	lib.requestAnimDict('pickup_object')
	TaskPlayAnim(cache.ped, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
	local prop = Utils.createProp("prop_wine_bot_01", vec3(tapCoords.x + 0.02, tapCoords.y - 0.232, coords.z -10), false, true)

	FreezeEntityPosition(prop, false)
	AttachEntityToEntity(prop, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.087, -0.121, -0.102, -73.06, 0.84, -10.62, true, true, false, false, 0, true)
	Wait(980)
	DeleteEntity(prop)

	CreateThread(function()
		formatFillBottles(id, amountPreload)
	end)

	local animDuration = (amountPreload * Config.fill.duration) * 1000
	local prop = Utils.createProp("prop_wine_bot_01", vec3(tapCoords.x + 0.02, tapCoords.y - 0.232, coords.z), false, true)

	SetTimeout(animDuration, function()
		DeleteEntity(prop)
	end)

	local progress = Writer.SendProgress({
		duration = animDuration,
		label = "Remplissage en cours..",
		position = 'bottom',
		useWhileDead = false,
		canCancel = false,
		disable = {
			move = true,
			combat = true,
			mouse = false,
			car = true
		},
		anim = Config.fill.animation
	})

	return progress
end
lib.callback.register("wtr_vineyard:client:proceedFilling", proceedAnimation)

local function initFillMenu(id)
	local options = {}
	local amountPreload = exports.wtr_vineyard:getAmountPreload("fill")

	options[#options + 1] = {
		title = ("Multiplicateur: **%d**"):format(amountPreload),
		icon = "fas fa-circle-info",
		description = "*Le multiplicateur permet de faire le remplissage de plusieurs bouteilles à la fois au lieu de ré-ouvrir le menu pour recommencer l'action*",
		arrow = true,
		onSelect = function()
			local predefinedAmount, amount = exports.wtr_vineyard:predefinedAmount("fill")
			if not predefinedAmount then
				initFillMenu(id)
				return
			end

			exports.wtr_vineyard:setAmountPreload(amount)
			Wait(10)
			Writer.Notify(("Multiplicateur ajusté à %d"):format(amount), "success")
			initFillMenu(id)
		end
	}
	for i = 1, #Config.fill.types do
		local fill = Config.fill.types[i]
		local canProceed = Writer.CanCraft(fill.required, amountPreload)
		local animDuration = (amountPreload * Config.fill.duration)

		options[#options + 1] = {
			title = Writer.GetLabelDescription(fill.add, amountPreload, ", ", true),
			description = ("%s%s"):format(Writer.GetLabelDescription(fill.required, amountPreload, " \n", false), (" \n\n**Temps de remplissage**: %d seconde%s"):format(animDuration, animDuration > 1 and "s" or "")),
			icon = #fill.add > 1 and "fas fa-boxes" or Writer.GetImage(fill.add[1].name),
			arrow = canProceed,
			disabled = not canProceed,
			onSelect = function()
				local pass = lib.callback.await("wtr_vineyard:server:proceedFilling", false, id, amountPreload, fill)
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
		local point = lib.points.new({
			coords = v.spawn,
			heading = v.spawn.w or 0.0,
			distance = 30,
			model = nil,
			tap = nil
		})
		function point:onEnter()
			if not self.model then
				self.model = Utils.createProp(Config.fill.props.barrel.model, vec4(self.coords.x, self.coords.y, self.coords.z, self.heading), true)

				local offset = GetOffsetFromEntityInWorldCoords(self.model, Config.fill.props.tap.offset)
				self.tap = Utils.createProp(Config.fill.props.tap.model, vec4(offset.x, offset.y, offset.z, self.heading), false)

				exports.ox_target:addLocalEntity(self.model, {
					{
						label = "Remplissage",
						groups = Config.fill.job.active and {[Config.fill.job.name] = Config.fill.job.grade} or nil,
						icon = "fas fa-wine-glass",
						onSelect = function()
							local tapCoords = GetEntityCoords(self.tap)
							local tapHeading = GetEntityHeading(self.tap)

							initFillMenu(k)
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

			if self.tap then
				if DoesEntityExist(self.tap) then DeleteEntity(self.tap) end
				self.tap = nil
			end
		end

		pointsLoaded[k] = point
	end
end

CreateThread(function()
	while not Writer.IsLoaded() do Wait(10) end

	initFill()
end)

AddEventHandler("onResourceStop", function(resource)
	if cache.resource == resource then
		for k, v in pairs(pointsLoaded) do
			if v.model then
				if DoesEntityExist(v.model) then DeleteEntity(v.model) end
				v.model = nil
			end

			if v.tap then
				if DoesEntityExist(v.tap) then DeleteEntity(v.tap) end
				v.tap = nil
			end
		end
	end
end)
