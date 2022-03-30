local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Shared code
local PrivateServerIdReplication = require(script:WaitForChild("PrivateServerIdReplication"))

local PrivateServerIdReplicatorLocal = {}
PrivateServerIdReplicatorLocal.screenGui = script:WaitForChild("PrivateServerIdGui")
PrivateServerIdReplicatorLocal.screenGui.Enabled = false
PrivateServerIdReplicatorLocal.textBox = PrivateServerIdReplicatorLocal.screenGui:WaitForChild("PrivateServerId")
PrivateServerIdReplicatorLocal.textBox.Visible = false

function PrivateServerIdReplicatorLocal.update()
	PrivateServerIdReplicatorLocal.textBox.Text = PrivateServerIdReplication.FORMAT:format(
		PrivateServerIdReplication.CONFIG:GetAttribute(
			PrivateServerIdReplication.ATTR_PRIVATE_SERVER_ID
		) or "<nil>"
	)
	PrivateServerIdReplicatorLocal.textBox.Visible = true
end

function PrivateServerIdReplicatorLocal.main()
	-- Move to PlayerGui
	PrivateServerIdReplicatorLocal.screenGui.Parent = player:WaitForChild("PlayerGui")
	
	-- Listen for updates
	PrivateServerIdReplicatorLocal.update()
	PrivateServerIdReplication.CONFIG:GetAttributeChangedSignal(
		PrivateServerIdReplication.ATTR_PRIVATE_SERVER_ID
	):Connect(PrivateServerIdReplicatorLocal.update)
	
	-- Show it!
	PrivateServerIdReplicatorLocal.screenGui.Enabled = true
end

return PrivateServerIdReplicatorLocal
