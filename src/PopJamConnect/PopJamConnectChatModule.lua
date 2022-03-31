local ServerScriptService = game:GetService("ServerScriptService")

local FUNCTION_ID = "popjamSetupEvent"
local MESSAGE_PATTERN = "^/pj%s+setup"

local PopJamConnect = require(
	ServerScriptService
	:WaitForChild("PopJam Portal Roblox Connect Module")
	:WaitForChild("PopJamConnect")
)

-- TODO: Add flood checker

return function (ChatService)
	ChatService:RegisterProcessCommandsFunction(FUNCTION_ID, function (speakerName, message, _channelName)
		if message:match(MESSAGE_PATTERN) then
			local speaker = ChatService:GetSpeaker(speakerName)
			local player = speaker and speaker:GetPlayer()
			if player then
				PopJamConnect:setupCodePrompt(player)
			else
				warn(("PopJamConnectChatModule: Could not find player for speaker %s"):format(speakerName))
			end
			return true
		end
		return false
	end)
end
