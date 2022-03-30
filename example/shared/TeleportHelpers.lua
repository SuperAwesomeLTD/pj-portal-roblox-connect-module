local TeleportService = game:GetService("TeleportService")

local PopJamConnect = require(
	game:GetService("ServerScriptService")
	:WaitForChild("PopJam Portal Roblox Connect Module")
	:WaitForChild("PopJamConnect")
)

local TeleportHelpers = {}

-- Promise.promisify(func)
-- Wraps a function that yields into one that returns a Promise.
-- Any errors that occur while executing the function will be turned into rejections.
-- https://eryn.io/roblox-lua-promise/api/Promise/#promisify
TeleportHelpers.reserveSeverAsync = PopJamConnect.Promise.promisify(function (...)
	return TeleportService:ReserveServer(...)
end)

function TeleportHelpers.teleportToPublicPlaceAsync(placeId, players, teleportData)
	PopJamConnect:getTeleportOptionsForPlaceIdAsync(placeId):andThen(function (teleportOptions)
		-- getTeleportOptionsForPlaceIdAsync resolves with a cached TeleportOptions.
		-- In PopJam event servers, it will be already set up with ReserveServerAccessCode.
		-- In non-PopJam event servers, it'll be blank (but still cached).
		-- To use SetTeleportData, clone it first so you don't edit the cached one.
		local myTeleportOptions = teleportOptions:Clone()
		myTeleportOptions:SetTeleportData(teleportData)
		TeleportService:TeleportAsync(placeId, players, myTeleportOptions)
	end)
end

function TeleportHelpers.teleportToPublicPlace(...)
	return TeleportHelpers.teleportToPublicPlaceAsync(...):expect()
end

function TeleportHelpers.teleportToMinigameAsync(placeId, players, teleportData)
	return TeleportHelpers.reserveSeverAsync(placeId):andThen(function (psac, psid)
		return PopJamConnect:getHostedEventIdAsync():andThen(function (popJamEventId)
			if popJamEventId ~= PopJamConnect.NO_EVENT then
				-- Persist the private server ID => PopJam event ID association
				-- Remember, if this fails - don't teleport! That's why we use :andThen() after this.
				return PopJamConnect:persistEventId(psid, popJamEventId)
			else
				-- No additional Nothing extra to do - continue on to the next :andThen().
				return PopJamConnect.Promise.resolve()
			end
		end):andThen(function ()
			local teleportOptions = Instance.new("TeleportOptions")
			teleportOptions.ReservedServerAccessCode = psac
			teleportOptions:SetTeleportData(teleportData or {})
			TeleportService:TeleportAsync(placeId, players, teleportOptions)
		end)
	end)
end

function TeleportHelpers.teleportToMinigame(...)
	return TeleportHelpers.teleportToMinigameAsync(...):expect()
end

return TeleportHelpers
