local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Chat = game:GetService("Chat")
local DataStoreService = game:GetService("DataStoreService")

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
PopJamConnect.DS_PREFIX = "PopJam"
PopJamConnect.DS_EVENT_ID = PopJamConnect.DS_PREFIX .. "EventId" -- "PopJamEventId"
PopJamConnect.DS_TELEPORT_DETAILS = PopJamConnect.DS_PREFIX .. "TeleportDetails" -- "PopJamTeleportDetails"
PopJamConnect.DS_SCOPE = nil

PopJamConnect.NO_EVENT = ""
PopJamConnect.EVENT_UNKNOWN = nil

PopJamConnect.config = script
PopJamConnect.ATTR_DEBUG_MODE = "DebugMode"
PopJamConnect.ATTR_PRIVATE_SERVER_ID_OVERRIDE = "PrivateServerIdOverride"

-- Print wrapper
local print_ = print
local function print(...)
	if PopJamConnect:isDebugMode() then
		print_("PopJamConnect", ...)
	end
end

-- Warn wrapper
local warn_ = warn
local function warn(...)
	warn_("PopJamConnect", ...)
end

function PopJamConnect:isDebugMode()
	return self.config:GetAttribute(self.ATTR_DEBUG_MODE)
end

function PopJamConnect:getCurrentPrivateServerId()
	local privateServerId = game.PrivateServerId
	if RunService:IsStudio() then
		local privateServerIdOverride = self.config:GetAttribute(self.ATTR_PRIVATE_SERVER_ID_OVERRIDE) or ""
		if privateServerIdOverride then
			warn("PrivateServerId override: " .. privateServerIdOverride)
		end
		privateServerId = privateServerIdOverride
	end
	return privateServerId
end

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
	self.dsEventId = DataStoreService:GetDataStore(PopJamConnect.DS_EVENT_ID, PopJamConnect.DS_SCOPE)
	self.dsTeleportDetails = DataStoreService:GetDataStore(PopJamConnect.DS_TELEPORT_DETAILS, PopJamConnect.DS_SCOPE)
	self:getHostedEventIdAsync():andThen(function (eventId)
		if eventId ~= PopJamConnect.NO_EVENT then
			print(("This server is hosting PopJam eventId: %s"):format(eventId))
		else
			print("This server is NOT hosting a PopJam event")
		end
	end)
	self._hostedEventId = PopJamConnect.EVENT_UNKNOWN
	return self
end

function PopJamConnect:main()
	self:replicateClientContent()
	self:injectChatModule()
	self:setupStarterPlayerScripts()
end

function PopJamConnect:getHostedEventIdAsync()
	if self._getHostedEventIdPromise then
		return self._getHostedEventIdPromise
	end
	if self._hostedEventId ~= PopJamConnect.EVENT_UNKNOWN then
		return Promise.resolve(self._hostedEventId)
	else
		self._getHostedEventIdPromise = Promise.resolve():andThen(function ()
			local dataStore = self:getEventIdDataStore()
			local getAsyncPromise = Promise.promisify(dataStore.GetAsync)
			local privateServerId = PopJamConnect:getCurrentPrivateServerId()
			if privateServerId == "" then
				return Promise.resolve(PopJamConnect.NO_EVENT)
			else
				print(("Looking up if PrivateServerId=%s is hosting a PopJam Event"):format(privateServerId))
				local key = tostring(privateServerId)
				return getAsyncPromise(dataStore, key):andThen(function (payload, dataStoreKeyInfo)
					if payload == nil then
						return Promise.resolve(PopJamConnect.NO_EVENT)
					end
					assert(typeof(payload) == "string", "string expected for event ID, got " .. typeof(payload))
					return Promise.resolve(payload)
				end)
			end
		end)
		-- Set self._hostedEventId appropriately after promise completes
		self._getHostedEventIdPromise:andThen(function (eventId)
			self._hostedEventId = eventId
		end):catch(function (err)
			warn("Failed to lookup current PopJam event id\n" .. tostring(err))
			self._hostedEventId = PopJamConnect.EVENT_UNKNOWN
		end)
	end
	return self._getHostedEventIdPromise
end

function PopJamConnect:getHostedEventId()
	return self:getHostedEventIdAsync():await()
end

function PopJamConnect:isHostingEventAsync()
	return self:getHostedEventIdAsync():andThen(function (eventId)
		return eventId ~= PopJamConnect.NO_EVENT and eventId ~= PopJamConnect.EVENT_UNKNOWN
	end)
end

function PopJamConnect:isHostingEvent()
	local eventId = self:getHostedEventId()
	return eventId ~= PopJamConnect.NO_EVENT and eventId ~= PopJamConnect.EVENT_UNKNOWN
end

function PopJamConnect:getEventIdDataStore()
	return self.dsEventId
end

function PopJamConnect:getTeleportDetailsDataStore()
	return self.dsTeleportDetails
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

function PopJamConnect:persistTeleportDetails(placeId, eventId, privateServerId, privateServerAccessCode, isStartPlace)
	-- First, save private server id => eventId
	-- Allows the private server to understand which event it is hosting
	return Promise.resolve():andThen(function ()
		local dsEventId = self:getEventIdDataStore()
		local updateAsyncPromise = Promise.promisify(dsEventId.UpdateAsync)
		local key = tostring(privateServerId)
		print("Saving privateServerId => eventId")
		return updateAsyncPromise(dsEventId, key, function (payload, dataStoreKeyInfo)
			-- Ensure an existing event ID is not being overwritten if it is different
			assert(payload == nil or payload == eventId, ("Unexpected event ID for privateServerId %s: %s"):format(privateServerId, tostring(payload)))
			payload = eventId

			-- Log for debugging
			print("UpdateAsync", self.DS_EVENT_ID, key, payload)

			return eventId, nil, nil
		end)
	end):andThen(function ()
		print("Saving eventId => teleportDetails")
		local dsTeleportDetails = self:getTeleportDetailsDataStore()
		local updateAsyncPromise = Promise.promisify(dsTeleportDetails.UpdateAsync)
		local key = tostring(eventId)
		return updateAsyncPromise(dsTeleportDetails, key, function (payload, dataStoreKeyInfo)
			payload = payload or {}
			if isStartPlace then
				payload["startPlaceId"] = placeId
			end
			-- Create mapping for place id => teleport details
			payload["placeIds"] = payload["placeIds"] or {}

			-- Create table to contain teleport details for this place id
			local placeIdTeleportDetails = payload["placeIds"][tostring(placeId)] or {}
			placeIdTeleportDetails["privateServerId"] = privateServerId
			placeIdTeleportDetails["privateServerAccessCode"] = privateServerAccessCode
			payload["placeIds"][tostring(placeId)] = placeIdTeleportDetails

			-- Log for debugging
			print("UpdateAsync", self.DS_TELEPORT_DETAILS, key, payload)

			return payload, nil, nil
		end)
	end)
end

function PopJamConnect:setupEvent(setupCode)
	return RukkazAPI:setupEvent(setupCode):andThen(function (placeId, eventId, privateServerId, privateServerAccessCode)
		return self:persistTeleportDetails(placeId, eventId, privateServerId, privateServerAccessCode, true)
	end)
end

function PopJamConnect:onSetupCodeSubmitted(_player, setupCode, ...)
	assert(typeof(setupCode) == "string" and setupCode:len() > 0 and setupCode:len() < 1024, "Setup code must be a nonempty string")
	assert(select("#", ...) == 0, "Too many arguments")
	return self:setupEvent(setupCode):catch(function (err)
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