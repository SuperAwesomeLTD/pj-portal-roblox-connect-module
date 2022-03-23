local EventSetupWindow = require(script:WaitForChild("EventSetupWindow"))

local EventHostUI = {}
EventHostUI.__index = EventHostUI
EventHostUI.TOPBAR_SIZE = 36
EventHostUI.prefab = script:WaitForChild("PopJamEventHostGui")

function EventHostUI.new(screenGui)
	local self = setmetatable({
		screenGui = screenGui;
		container = screenGui:WaitForChild("Container");
	}, EventHostUI)
	self.eventSetupWindow = EventSetupWindow.new(self.container:WaitForChild("EventSetupWindow"))
	self.container.Size = UDim2.new(1, 0, 1, EventHostUI.TOPBAR_SIZE)
	self.screenGui.Enabled = true
	return self
end

return EventHostUI
