local ServerScriptService = game:GetService("ServerScriptService")

local FUNCTION_ID = "popjamSetupEvent"
local MESSAGE_WITH_SETUP_CODE_PATTERN = "^/pj%s+setup%s+(.+)"
local MESSAGE_PATTERN = "^/pj%s+setup"

local RukkazEventHost = require(
	ServerScriptService
	:WaitForChild("PopJam Portal Roblox Connect Module")
	:WaitForChild("RukkazEventHost")
)

local RukkazEventHost = require(ServerScriptService:WaitForChild("PopJam Portal Roblox Connect Module"):WaitForChild("RukkazEventHost"))

-- TODO: Add flood checker

return function (ChatService)
	ChatService:RegisterProcessCommandsFunction(FUNCTION_ID, function (speakerName, message, _channelName)
		local setupCode = message:match(MESSAGE_WITH_SETUP_CODE_PATTERN)
		if setupCode then
			RukkazEventHost.RukkazAPI:setupEvent(setupCode)
			return true
		end
		if message:match(MESSAGE_PATTERN) then
			local speaker = ChatService:GetSpeaker(speakerName)
			local player = speaker and speaker:GetPlayer()
			if player then
				RukkazEventHost:setupCodePrompt(player)
			else
				warn(("PopJamEventHostChatModule: Could not find player for speaker %s"):format(speakerName))
			end
			return true
		end
		return false
	end)
end
