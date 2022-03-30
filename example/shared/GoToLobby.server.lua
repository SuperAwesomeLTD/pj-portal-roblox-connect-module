local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeleportHelpers = require(ServerScriptService:WaitForChild("TeleportHelpers"))
local PlaceIds = require(ReplicatedStorage:WaitForChild("PlaceIds"))

local debounce = {}
local function onTriggered(player)
	if debounce[player] then return end
	debounce[player] = true
	
	TeleportHelpers.teleportToPublicPlaceAsync(PlaceIds.LOBBY, {player}, {}):await()
	
	debounce[player] = false
end

local proximityPrompt = assert(workspace:FindFirstChild("GoToLobby", true), "Could not find GoToLobby ProximityPrompt")
proximityPrompt.Triggered:Connect(onTriggered)
proximityPrompt.Enabled = true
