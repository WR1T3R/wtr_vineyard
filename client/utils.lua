local Config = require("shared.shared")
local Utils = {}

function Utils.getFormatTime(time)
	if (time > 60) and not (time > 3600) then
		local minutes, fraction = math.modf(time / 60)
		local seconds = time - (minutes * 60)
		local formatLast = (" %d %s%s"):format(seconds, "seconde", seconds > 1 and "s" or "")

		return ("%d %s%s%s"):format(minutes, "minute", minutes > 1 and "s" or "", fraction > 0.0 and formatLast or "")
	elseif time > 3600 then
		local hours, fraction = math.modf(time / 3600)
		local minutes = math.modf((time - (hours * 3600)) / 60)
		local formatLast = (" %d %s%s"):format(minutes, "minute", minutes > 1 and "s" or "")

		return ("%d %s%s%s"):format(hours, "heure", hours > 1 and "s" or "", fraction > 0.0 and formatLast or "")
	else
		return ("%d %s%s"):format(time, "seconde", time > 1 and "s" or "")
	end
end

function Utils.getInfoFromName(name)
	for i = 1, #Config.harvest do
		local harvest = Config.harvest[i]
		if harvest.areasType:lower() == name:lower() then
			return i
		end
	end

	return nil
end

function Utils.createProp(object, coords, placeonground, network)
	local model = joaat(object)
	lib.requestModel(model, 5000)

	local props = CreateObject(model, coords.x, coords.y, coords.z, network or false, false, false)

	while not DoesEntityExist(props) do Wait(10) end
	SetEntityHeading(props, coords.w)

	if placeonground then
		PlaceObjectOnGroundProperly(props)
	end
	FreezeEntityPosition(props, true)

	SetModelAsNoLongerNeeded(model)
	return props
end

function Utils.createEntity(model, coords)
	local model = joaat(model)

	lib.requestModel(model, 5000)

	local peds = CreatePed(0, model, coords.x, coords.y, coords.z - 1, coords.w, false, false, false)
	while not DoesEntityExist(peds) do Wait(2000) end

	FreezeEntityPosition(peds, true)
	SetEntityInvincible(peds, true)
	SetBlockingOfNonTemporaryEvents(peds, true)
	SetPedDefaultComponentVariation(peds)

	SetModelAsNoLongerNeeded(model)
	return peds
end

function Utils.getTotalAddItems(addTable, amountPreload)
	local totalAmount = 0
	for k, v in pairs(addTable) do
		totalAmount += v.count
	end

	return totalAmount * amountPreload
end

return Utils