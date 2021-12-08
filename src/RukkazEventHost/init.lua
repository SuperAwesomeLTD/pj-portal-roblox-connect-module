local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Chat = game:GetService("Chat")

local RukkazAPI = require(ServerScriptService:WaitForChild("Rukkaz Roblox Web API SDK"):WaitForChild("RukkazAPI"):WaitForChild("Singleton"))

local RukkazEventHost = {}
RukkazEventHost.__index = RukkazEventHost

function RukkazEventHost.new()
	local self = setmetatable({
		chatModuleInjected = false;
		chatModulePrefab = script.RukkazEventHostChatModule;
		clientContent = script.Client;
		starterPlayerScripts = script.StarterPlayerScripts;
	}, RukkazEventHost)
	self.remotes = self.clientContent.Remotes
	self.remotes.SetupCode.Submit.OnServerInvoke = function (...)
		return self:onSetupCodeSubmitted(...)
	end
	return self
end

function RukkazEventHost:main()
	self:replicateClientContent()
	self:injectChatModule()
	self:setupStarterPlayerScripts()
end

function RukkazEventHost:setupStarterPlayerScripts()
	for _, child in pairs(self.starterPlayerScripts:GetChildren()) do
		child.Parent = StarterPlayerScripts
	end
end

function RukkazEventHost:replicateClientContent()
	self.clientContent.Name = "RukkazEventHost"
	self.clientContent.Parent = ReplicatedStorage
end

function RukkazEventHost:getChatModulesFolder()
	return Chat:WaitForChild("ChatModules")
end

function RukkazEventHost:injectChatModule()
	assert(not self.chatModuleInjected, "chat module already injected")
	local chatModulesFolder = self:getChatModulesFolder()
	local chatModule = self.chatModulePrefab:Clone()
	chatModule.Parent = chatModulesFolder
	self.chatModuleInjected = true
end

function RukkazEventHost:setupCodePrompt(player)
	self.remotes.SetupCode.Prompt:FireClient(player)
end

function RukkazEventHost:onSetupCodeSubmitted(_player, setupCode, ...)
	assert(typeof(setupCode) == "string" and setupCode:len() > 0 and setupCode:len() < 1024, "Setup code must be a nonempty string")
	assert(select("#", ...) == 0, "Too many arguments")
	return RukkazAPI:setupEvent(setupCode):await()
end

return RukkazEventHost.new()
