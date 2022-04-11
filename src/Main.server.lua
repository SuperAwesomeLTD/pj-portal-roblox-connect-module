local PopJamConnect = require(script.Parent:WaitForChild("PopJamConnect"))

-- During the event setup process, the PopJamConnect module invokes this
-- with the event ID that is currently being set up. The function should
-- return the place ID to which event guests must be teleported.
-- The place ID is passed to TeleportService:ReserveServer
local function getStartPlaceIdCallback(_eventId)
	return game.PlaceId
end
PopJamConnect:setStartPlaceIdCallback(getStartPlaceIdCallback)
PopJamConnect:main()
