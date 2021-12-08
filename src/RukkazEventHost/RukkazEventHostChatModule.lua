local ServerScriptService = game:GetService("ServerScriptService")

local FUNCTION_ID = "rukkazSetupEvent"
local MESSAGE_WITH_SETUP_CODE_PATTERN = "^/rukkaz%s+setup%s+(.+)"
local MESSAGE_PATTERN = "^/rukkaz%s+setup"

local RukkazAPI = require(ServerScriptService:WaitForChild("Rukkaz Roblox Web API SDK"):WaitForChild("RukkazAPI"):WaitForChild("Singleton"))

local RukkazEventHost = require(ServerScriptService:WaitForChild("Rukkaz Roblox Event Host Module"):WaitForChild("RukkazEventHost"))

-- TODO: Add flood checker

return function (ChatService)
	ChatService:RegisterProcessCommandsFunction(FUNCTION_ID, function (speakerName, message, _channelName)
		local setupCode = message:match(MESSAGE_WITH_SETUP_CODE_PATTERN)
		if setupCode then
			RukkazAPI:setupEvent(setupCode)
			return true
		end
		if message:match(MESSAGE_PATTERN) then
			local speaker = ChatService:GetSpeaker(speakerName)
			local player = speaker and speaker:GetPlayer()
			if player then
				RukkazEventHost:setupCodePrompt(player)
			else
				warn(("RukkazEventHostChatModule: Could not find player for speaker %s"):format(speakerName))
			end
			return true
		end
		return false
	end)
end
