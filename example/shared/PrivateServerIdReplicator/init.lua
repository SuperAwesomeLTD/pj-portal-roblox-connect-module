-- This system creates an uneditable TextBox at the top of your screen which reflects
-- the current PrivateServerId. It is useful when debugging place-to-place teleportation
-- in private servers.

local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local Client = script:WaitForChild("Client")

-- Shared module
local PrivateServerIdReplication = require(Client:WaitForChild("PrivateServerIdReplication"))

local PrivateServerIdReplicator = {}
PrivateServerIdReplicator.Shared = PrivateServerIdReplication
PrivateServerIdReplicator.Client = Client

function PrivateServerIdReplicator.replicate()
	print("PrivateServerId:", game.PrivateServerId)
	PrivateServerIdReplication.CONFIG:SetAttribute(
		PrivateServerIdReplication.ATTR_PRIVATE_SERVER_ID,
		game.PrivateServerId
	)
end

function PrivateServerIdReplicator.main()
	-- Move client code into StarterPlayerScripts
	Client.Name = "PrivateServerIdReplicator (Client)"
	Client.Parent = StarterPlayerScripts

	PrivateServerIdReplicator.replicate()
	-- Note: PSID never changes, but just in case it does... couldn't hurt
	game:GetPropertyChangedSignal("PrivateServerId"):Connect(PrivateServerIdReplicator.replicate)
end

return PrivateServerIdReplicator
