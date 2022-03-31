local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeleportHelpers = require(ServerScriptService:WaitForChild("TeleportHelpers"))
local PlaceIds = require(ReplicatedStorage:WaitForChild("PlaceIds"))

local debounce = {}
local function onTriggered(player)
	if debounce[player] then return end
	debounce[player] = true
	
	TeleportHelpers.teleportToPublicPlaceAsync(PlaceIds.ALTERNATE, {player}, {}):await()
	
	debounce[player] = false
end

local proximityPrompt = assert(workspace:FindFirstChild("GoToAlt", true), "Could not find GoToAlt ProximityPrompt")
proximityPrompt.Triggered:Connect(onTriggered)
proximityPrompt.Enabled = true
