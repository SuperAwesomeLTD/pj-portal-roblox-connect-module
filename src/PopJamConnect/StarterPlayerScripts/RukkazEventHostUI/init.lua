local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local popJamConnect = ReplicatedStorage:WaitForChild("PopJamConnect")

local EventHostUI = require(popJamConnect:WaitForChild("UI"):WaitForChild("EventHostUI"))

local eventHostUI = EventHostUI.new(EventHostUI.prefab:Clone())
eventHostUI.screenGui.Parent = player:WaitForChild("PlayerGui")
return eventHostUI
