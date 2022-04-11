local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local FUNCTION_ID = "popJamConnect"
local EVENT_SETUP_MESSAGE_PATTERN = "^/pj%s+setup"
local EVENT_JOIN_MESSAGE_PATTERN = "^/pj%s+join"
local KICK_MESSAGE_PATTERN = "^/pj%s+kick%s+(.+)"
local KICK_WITH_REASON_MESSAGE_PATTERN = "^/pj%s+kick%s+(.+),%s+(.+)"

local PopJamConnect = require(
	ServerScriptService
	:WaitForChild("PopJam Portal Roblox Connect Module")
	:WaitForChild("PopJamConnect")
)

-- TODO: Add flood checker

local function findPlayer(s)
	local i = tonumber(s)
	for _, player in pairs(Players:GetPlayers()) do
		if s:lower() == player.Name:lower() or i == player.UserId then
			return player
		end
	end
	return nil
end

local function playerStr(player)
	return ("%s (%d, @%s)"):format(player.DisplayName, player.UserId, player.Name)
end

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
			if PopJamConnect:isHostingEvent() or RunService:IsStudio() then
				local hasPrivileges = PopJamConnect:isGameOwnerOrPopJamAdminAsync(player) or RunService:IsStudio()
				if hasPrivileges then
					-- /pj kick [username]
					local nameToKick, reason = message:match(KICK_WITH_REASON_MESSAGE_PATTERN)
					if not nameToKick then
						nameToKick = message:match(KICK_MESSAGE_PATTERN)
					end
					if nameToKick then
						local playerToKick = findPlayer(nameToKick)
						if playerToKick then
							print(("PopJamConnect: Kicked %s"):format(playerStr(playerToKick)))
							playerToKick:Kick(reason or "")
						else
							print(("PopJamConnect: Could not find player: %q"):format(nameToKick))
						end
						return true
					end
				end
			end
		end

		return false
	end)
end
