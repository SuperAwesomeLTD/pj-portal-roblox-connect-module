local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Chat = game:GetService("Chat")

local Promise = require(
	script
	:WaitForChild("Client")
	:WaitForChild("lib")
	:WaitForChild("Promise")
)

local RukkazAPI = require(
	script
	:WaitForChild("lib")
	:WaitForChild("Rukkaz Roblox Web API SDK")
	:WaitForChild("RukkazAPI")
	:WaitForChild("Singleton")
)

local PopJamConnect = {}
PopJamConnect.__index = PopJamConnect
PopJamConnect.VERSION = "1.2.0"
PopJamConnect.RukkazAPI = RukkazAPI

function PopJamConnect.new()
	local self = setmetatable({
		chatModuleInjected = false;
		chatModulePrefab = script.PopJamConnectChatModule;
		clientContent = script.Client;
		starterPlayerScripts = script.StarterPlayerScripts;
	}, PopJamConnect)
	self.remotes = self.clientContent.Remotes
	self.remotes.SetupCode.Submit.OnServerInvoke = function (...)
		return self:onSetupCodeSubmitted(...)
	end
	return self
end

function PopJamConnect:main()
	self:replicateClientContent()
	self:injectChatModule()
	self:setupStarterPlayerScripts()
end

function PopJamConnect:setupStarterPlayerScripts()
	for _, child in pairs(self.starterPlayerScripts:GetChildren()) do
		child.Parent = StarterPlayerScripts
	end
end

function PopJamConnect:replicateClientContent()
	self.clientContent.Name = "RukkazEventHost"
	self.clientContent.Parent = ReplicatedStorage
end

function PopJamConnect:getChatModulesFolder()
	return Chat:WaitForChild("ChatModules")
end

function PopJamConnect:injectChatModule()
	assert(not self.chatModuleInjected, "chat module already injected")
	local chatModulesFolder = self:getChatModulesFolder()
	if not chatModulesFolder:FindFirstChild(self.chatModulePrefab.Name) then
		local chatModule = self.chatModulePrefab:Clone()
		chatModule.Parent = chatModulesFolder
	end
	self.chatModuleInjected = true
end

function PopJamConnect:setupCodePrompt(player)
	self.remotes.SetupCode.Prompt:FireClient(player)
end

function PopJamConnect:onSetupCodeSubmitted(_player, setupCode, ...)
	assert(typeof(setupCode) == "string" and setupCode:len() > 0 and setupCode:len() < 1024, "Setup code must be a nonempty string")
	assert(select("#", ...) == 0, "Too many arguments")
	return RukkazAPI:setupEvent(setupCode):catch(function (err)
		warn(tostring(err))
		if tostring(err):lower():match("http requests are not enabled") then
			warn("Did you forget to enable HttpService.HttpEnabled?")
			return Promise.reject("HttpService.HttpEnabled is false")
		elseif err == "ErrNoMatchingEvent" then
			return Promise.reject("The setup code you provided doesn't match any event.")
		else
			return Promise.reject("Unspecified error")
		end
	end):await()
end

return PopJamConnect.new()
