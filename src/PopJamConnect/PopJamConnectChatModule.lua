local ServerScriptService = game:GetService("ServerScriptService")

local FUNCTION_ID = "popJamConnect"
local EVENT_SETUP_MESSAGE_PATTERN = "^/pj%s+setup"
local EVENT_JOIN_MESSAGE_PATTERN = "^/pj%s+join"

local PopJamConnect = require(
	ServerScriptService
	:WaitForChild("PopJam Portal Roblox Connect Module")
	:WaitForChild("PopJamConnect")
)

-- TODO: Add flood checker

return function (ChatService)
	ChatService:RegisterProcessCommandsFunction(FUNCTION_ID, function (speakerName, message, _channelName)
		local speaker = ChatService:GetSpeaker(speakerName)
		local player = speaker and speaker:GetPlayer()
		if player then
			if message:match(EVENT_SETUP_MESSAGE_PATTERN) then
				PopJamConnect:setupCodePrompt(player)
				return true
			end
			if message:match(EVENT_JOIN_MESSAGE_PATTERN) then
				PopJamConnect:eventIdPrompt(player)
				return true
			end
		end

		return false
	end)
end
