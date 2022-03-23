local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local rukkazEventHost = ReplicatedStorage:WaitForChild("RukkazEventHost")

local EventHostUI = require(rukkazEventHost:WaitForChild("UI"):WaitForChild("EventHostUI"))

local eventHostUI = EventHostUI.new(EventHostUI.prefab:Clone())
eventHostUI.screenGui.Parent = player:WaitForChild("PlayerGui")
return eventHostUI
