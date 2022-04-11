local NAMES_TOGGLE_PATTERN = "^/pj%s+names"

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
Players.LocalPlayer.Chatted:Connect(function (msg)
    if msg:lower():match(NAMES_TOGGLE_PATTERN) then
        local enable = not StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, enable)
        Players.LocalPlayer.NameDisplayDistance = enable and 100 or 0
    end
end)
