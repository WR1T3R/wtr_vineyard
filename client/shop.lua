local Config = require("shared.shared")
local Utils = require("client.utils")

local entitiesLoaded = {}
local propsLoaded = {}

local pointsLoaded = {}

local function initShop()
	for k, v in pairs(Config.shop) do
		local point = lib.points.new({
			coords = v.peds.coords,
			heading = v.peds.coords.w or 0.0,
			distance = 5,
			model = nil
		})

		function point:onEnter()
			if not self.model then
				self.model = Utils.createEntity(v.peds.model, v.peds.coords, true)

				if v.peds.scenario then
					TaskStartScenarioInPlace(self.model, v.peds.scenario, -1, true)
				end
			end

			exports.ox_target:addLocalEntity(self.model, {
				{
					label = v.target.label or "Magasin",
					icon = v.target.icon or "fas fa-cash-register",
					groups = v.job.active and {[v.job.name] = v.job.grade} or nil,
					onSelect = function()
						exports.ox_inventory:openInventory("shop", {type = ('wtr_vineyard:shop:%s'):format(k), id = 1})
					end,
					distance = v.target.distance or 2.0,
				}
			})
		end

		function point:onExit()
			if self.model then
				if DoesEntityExist(self.model) then
					DeleteEntity(self.model)
					exports.ox_target:removeLocalEntity(self.model)
				end

				self.model = nil
			end
		end

		pointsLoaded[#pointsLoaded + 1] = point
	end
end

local function initStandaloneShop()
	for k, v in pairs(Config.standaloneStore) do
		local point = lib.points.new({
			coords = v.peds.coords,
			heading = v.peds.coords.w or 0.0,
			distance = 30,
			model = nil
		})

		function point:onEnter()
			if not self.model then
				self.model = Utils.createEntity(v.peds.model, v.peds.coords, true)

				if v.peds.scenario then
					TaskStartScenarioInPlace(self.model, v.peds.scenario, -1, true)
				end
			end

			exports.ox_target:addLocalEntity(self.model, {
				{
					label = v.target.standalone.label or "Magasin autonome",
					icon = v.target.standalone.icon or "fas fa-cash-register",
					onSelect = function()
						exports.ox_inventory:openInventory("shop", {type = ('wtr_vineyard:standaloneStore:%s'):format(k), id = 1})
					end,
					distance = v.target.standalone.distance or 2.0
				},
				{
					label = v.target.refill.label or "Ravitailler",
					icon = v.target.refill.icon or "fas fa-boxes",
					groups = v.job.active and {[v.job.name] = v.job.grade} or nil,
					onSelect = function()
						exports.ox_inventory:openInventory("stash", ("wtr_vineyard:standaloneShop:%s"):format(k))
					end,
					distance = v.target.refill.distance or 2.0
				}
			})
		end

		function point:onExit()
			if self.model then
				if DoesEntityExist(self.model) then
					DeleteEntity(self.model)
					exports.ox_target:removeLocalEntity(self.model)
				end

				self.model = nil
			end
		end

		pointsLoaded[#pointsLoaded + 1] = point
	end
end

AddEventHandler("onResourceStop", function(resource)
	if cache.resource == resource then
		for k, v in pairs(pointsLoaded) do
			if v.model and DoesEntityExist(v.model) then DeleteEntity(v.model) end
		end
	end
end)

CreateThread(function()
	while not Writer.IsLoaded do Wait(10) end

	initShop()
	initStandaloneShop()
end)