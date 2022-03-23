local PopJamConnect = require(script.Parent:WaitForChild("PopJamConnect"))

-- During the event setup process, RukkazAPI calls this with the event ID
-- that is currently being set up. The function should return the place ID
-- to which event guests must be teleported. The place ID is then passed to
-- TeleportService:ReserveServer
local function getHostPlaceIdCallback(_eventId)
	return game.PlaceId
end
PopJamConnect.RukkazAPI:setEventHostPlaceIdCallback(getHostPlaceIdCallback)

PopJamConnect:main()
