-- Shared module for PrivateServerId replication system
-- PrivateSeverIdReplicatoir moves this to ReplicatedStorage at runtime

local PrivateServerIdReplicatorModule = {}

-- The object on which to place attributes for replication
PrivateServerIdReplicatorModule.CONFIG = workspace

-- The private server ID to replicate 
PrivateServerIdReplicatorModule.ATTR_PRIVATE_SERVER_ID = "PrivateServerId"

-- How it should display in GUI
PrivateServerIdReplicatorModule.FORMAT = "game.PrivateServerId = %q"

return PrivateServerIdReplicatorModule
