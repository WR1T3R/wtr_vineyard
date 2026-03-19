local Config = require("shared.shared")
local Utils = require("client.utils")

local amountPreLoad = 1

local dataAmount = {
	["fill"] = 20,
	["step"] = 20,
	["prepare"] = 60,
	["labelling"] = 60,
}
exports("setAmountPreload", function(amount)
	amountPreLoad = amount
end)

exports("getAmountPreload", function(_type)
	return amountPreLoad >= dataAmount[_type] and dataAmount[_type] or amountPreLoad
end)

---@param items table table which contains all items needed
local function canCraft(items)
	local itemsIn = 0

	for i = 1, #items do
		local count = exports.ox_inventory:GetItemCount(items[i].itemName)

		if count >= items[i].count then itemsIn += 1 end
	end

	return #items == itemsIn
end

local function getRequiredLabel(items)
	a = 0
	label = ""

	for _, v in pairs(items) do
		label = string.format("%s%sx %s", label, v.count, exports.ox_inventory:Items(v.itemName).label)
		if a ~= #items - 1 then label = ("%s\n"):format(label) end
		a += 1
	end

	return label
end

CreateThread(function()
	while not LocalPlayer.state.isLoggedIn do Wait(5000) end

	for k, v in pairs(Config.vineZone) do
		local poly = lib.zones.poly({
			points = v.points,
			thickness = v.thickness,
			debug = Config.debug,
			onEnter = function()
				exports.wtr_vineyard:InitFill()
				exports.wtr_vineyard:InitPrepare()
				exports.wtr_vineyard:InitLabeling()
				exports.wtr_vineyard:InitShop()
				exports.wtr_vineyard:InitStep()
			end,
			onExit = function()
				exports.wtr_vineyard:DestroyFill()
				exports.wtr_vineyard:DestroyPrepare()
				exports.wtr_vineyard:DestroyLabeling()
				exports.wtr_vineyard:DestroyShop()
				exports.wtr_vineyard:DestroyStep()
			end
		})
	end

	for k, v in pairs(Config.stashes) do
		exports.ox_target:addBoxZone({
			coords = v.zone.coords,
			size = v.zone.size,
			rotation = v.zone.rotation,
			debug = Config.debug,
			options = {
				{
					label = v.label,
					icon = "fas fa-box",
					groups = v.job.active and {[v.job.name] = v.job.grade} or nil,
					onSelect = function()
						local stash = lib.callback.await("wtr_vineyard:server:registerStash", false, ("wtr_vineyard:stash:%s"):format(v.id), v.label, v.slots, v.weight, v.owner)
						exports.ox_inventory:openInventory("stash", ("wtr_vineyard:stash:%s"):format(v.id))
					end,
					distance = 2.0
				}
			}
		})
	end

	for k, v in pairs(Config.blips) do
		local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
        SetBlipSprite(blip, v.sprite)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, v.scale)
        SetBlipColour(blip, v.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(v.label)
        EndTextCommandSetBlipName(blip)
	end
end)

lib.hideContext()
function preparePour(data)
	local options = {
		{
			title = "Boire la bouteille",
			icon = "fas fa-bottle-water",
			arrow = true,
			onSelect = function()
				if lib.progressCircle({
					label = "Boire..",
					duration = data.duration * 1000,
					position = 'bottom',
					useWhileDead = false,
					canCancel = false,
					disable = {
						move = false,
						combat = true,
						car = true,
					},
					anim = {
						dict = data.animation.dict,
						clip = data.animation.clip
					},
					prop = {
						{
							model = data.animation.propName,
							bone = 57005,
							pos = vec3(0.08, -0.22, -0.11),
							rot = vec3(-70.0, 50.0, 0.0)
						},
					},
				}) 
				then 
					lib.callback.await("wtr_vineyard:server:drink", false, data)
				end
			end
		},
		{
			title = "Verser",
			icon = "fas fa-wine-glass",
			arrow = canCraft(data.pour.required),
			disabled = not canCraft(data.pour.required),
			description = "Requis: "..getRequiredLabel(data.pour.required),
			onSelect = function()
				if lib.progressCircle({
					label = "Versage..",
					duration = data.pour.duration * 1000,
					position = 'bottom',
					useWhileDead = false,
					canCancel = false,
					disable = {
						move = false,
						combat = true,
						car = true,
					},
					anim = {
						dict = 'mp_arresting',
						clip = 'a_uncuff'
					},
					prop = {
						{
							model = data.animation.propName,
							bone = 57005,
							pos = vec3(0.005, 0.024, -0.031),
							rot = vec3(-45.78, 22.05, -65.19),
						},
					},
				}) 
				then 
					for k,v in pairs(data.pour.required) do
						if v.remove then
							lib.callback.await("wtr_vineyard:server:setupItems", false, "remove", v.itemName, v.count)
						end
					end
					lib.callback.await("wtr_vineyard:server:setupItems", false, "remove", data.itemName, 1)
					lib.callback.await("wtr_vineyard:server:setupItems", false, "give", data.pour.add.itemName, data.pour.add.count)
				end
			end
		}
	}

	lib.registerContext({
		id = "wtr_vineyard:preparePour",
		title = exports.ox_inventory:Items(data.itemName).label,
		options = options
	})
	lib.showContext("wtr_vineyard:preparePour")
end

lib.callback.register("wtr_vineyard:client:preparePour", function(data)
	preparePour(data)
end)

---@param data table contains all progressbars data
---@return boolean
lib.callback.register("wtr_vineyard:client:drinkGlass", function(data)
	if lib.progressCircle({
		label = "Boire..",
		duration = data.duration * 1000,
		position = 'bottom',
		useWhileDead = false,
		canCancel = false,
		disable = {
			move = false,
			combat = true,
			car = true,
		},
		anim = {
			dict = data.animation.dict,
			clip = data.animation.clip
		},
		prop = {
			{
				model = data.animation.propName,
				bone = 57005,
				pos = vec3(0.14, -0.07, -0.01),
				rot = vec3(-80.0, 100.0, 0.0)
			},
		},
	}) 
	then 
		return true
	end
end)
