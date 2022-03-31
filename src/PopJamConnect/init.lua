local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")
local Chat = game:GetService("Chat")
local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

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
PopJamConnect.VERSION = "1.2.3"
PopJamConnect.RukkazAPI = RukkazAPI
PopJamConnect.Promise = Promise
PopJamConnect.DS_PREFIX = "PopJam"
PopJamConnect.DS_EVENT_ID = PopJamConnect.DS_PREFIX .. "EventId" -- "PopJamEventId"
PopJamConnect.DS_TELEPORT_DETAILS = PopJamConnect.DS_PREFIX .. "TeleportDetails" -- "PopJamTeleportDetails"
PopJamConnect.DS_SCOPE = nil

PopJamConnect.NO_EVENT = ""
PopJamConnect.EVENT_UNKNOWN = nil

PopJamConnect.config = script
PopJamConnect.ATTR_DEBUG_MODE = "DebugMode"
PopJamConnect.ATTR_PRIVATE_SERVER_ID_OVERRIDE = "PrivateServerIdOverride"

-- A special setup code which can be used to set up a mock PopJam event,
-- whose teleport details are NOT sent to PopJam for use in the portal.
PopJamConnect.MOCK_EVENT_SETUP_CODE = "000000"

-- The SuperAwesomeGaming group, who authors the PopJam Portal.
PopJamConnect.SA_GROUP_ID = 12478861

-- The minimum rank in the group identified by GROUP_ID which should be
-- considered an admin who can test event teleportaion using TEST_SETUP_CODE
PopJamConnect.SA_GROUP_MIN_RANK = 254

-- If this universe is owned by a group, this is the minimum rank required
-- in order to allow test event teleportation using TEST_SETUP_CODE
PopJamConnect.GROUP_MIN_RANK = 255

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
	return self.config:GetAttribute(self.ATTR_DEBUG_MODE) or RunService:IsStudio()
end

function PopJamConnect:setDebugMode(isDebugMode)
	assert(typeof(isDebugMode) == "boolean", "boolean expected")
	return self.config:SetAttribute(self.ATTR_DEBUG_MODE, isDebugMode)
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

function PopJamConnect:overridePrivateServerId(privateServerId)
	assert(typeof(privateServerId) == "string" or typeof(privateServerId) == "nil", "string or nil expected")
	self.config:SetAttribute(self.ATTR_PRIVATE_SERVER_ID_OVERRIDE, privateServerId)
	print("PrivateServerId override set to " .. (privateServerId or "nil"))
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
	local _
	_, self.dsEventId = pcall(DataStoreService.GetDataStore, DataStoreService, PopJamConnect.DS_EVENT_ID, PopJamConnect.DS_SCOPE)
	_, self.dsTeleportDetails = pcall(DataStoreService.GetDataStore, DataStoreService, PopJamConnect.DS_TELEPORT_DETAILS, PopJamConnect.DS_SCOPE)
	self:getHostedEventIdAsync():andThen(function (eventId)
		if eventId ~= PopJamConnect.NO_EVENT then
			print(("This server is hosting PopJam eventId: %s"):format(eventId))
		else
			print("This server is NOT hosting a PopJam event")
		end
	end)
	self._hostedEventId = PopJamConnect.EVENT_UNKNOWN
	self._teleportOptions = {}
	self._teleportOptionsPromises = {}
	return self
end

function PopJamConnect:main()
	self:replicateClientContent()
	self:injectChatModule()
	self:setupStarterPlayerScripts()
end

local reserveServerPromise = Promise.promisify(function (...)
	return TeleportService:ReserveServer(...)
end)

function PopJamConnect:getTeleportDetailsAsync()
	return self:getHostedEventIdAsync():andThen(function (eventId)
		if eventId == PopJamConnect.NO_EVENT then
			return Promise.reject()
		end
		local dataStore = self:getTeleportDetailsDataStore()
		local getAsyncPromise = Promise.promisify(dataStore.GetAsync)
		local key = tostring(eventId)
		return getAsyncPromise(dataStore, key):andThen(function (payload, _dataStoreKeyInfo)
			print(self.DS_TELEPORT_DETAILS, "GetAsync", key, payload)

			payload = payload or {}
			payload["placeIds"] = payload["placeIds"] or {}
			--payload["startPlaceId"]

			return Promise.resolve(eventId, payload)
		end)
	end)
end

function PopJamConnect:getTeleportDetailsForPlaceIdAsync(placeId)
	return self:getTeleportDetails():andThen(function (eventId, payload)
		-- Safely access payload["placeIds"][placeId]
		local placeIdTeleportDetails = payload["placeIds"][tostring(placeId)] or {}

		-- Promise that resolves with the privateServerAccessCode and privateServerId
		local promise
		if placeIdTeleportDetails["privateServerAccessCode"] and placeIdTeleportDetails["privateServerId"] then
			-- Already known, just resolve immediately
			promise = Promise.resolve(placeIdTeleportDetails["privateServerAccessCode"], placeIdTeleportDetails["privateServerId"])
		else
			-- Must be reserved, persisted, then resolved
			promise = reserveServerPromise(placeId):andThen(function (privateServerAccessCode, privateServerId)
				print("ReserveServer", privateServerAccessCode, privateServerId)
				return self:persistTeleportDetails(placeId, eventId, privateServerId, privateServerAccessCode, false):andThen(function ()
					return Promise.resolve(privateServerAccessCode, privateServerId)
				end)
			end)
		end

		return promise
	end)
end

function PopJamConnect:getTeleportOptionsForPlaceIdAsync(placeId)
	-- Cache
	if self._teleportOptions[placeId] then
		return Promise.resolve(self._teleportOptions[placeId])
	end
	-- Return any in-progress promise
	if self._teleportOptionsPromises[placeId] then
		return self._teleportOptionsPromises[placeId]
	end
	local promise = self:getHostedEventIdAsync():andThen(function (eventId)
		local teleportOptions = Instance.new("TeleportOptions")

		if eventId == PopJamConnect.NO_EVENT then
			print("This server is not hosting a PopJam event; returning plain TeleportOptions")
			return Promise.resolve(teleportOptions)
		end

		return self:getTeleportDetailsForPlaceIdAsync(placeId):andThen(function (privateServerAccessCode, privateServerId)
			print("getTeleportOptionsForPlaceIdAsync", placeId, privateServerId, privateServerAccessCode)
			teleportOptions.ReservedServerAccessCode = privateServerAccessCode
			return Promise.resolve(teleportOptions)
		end)
	end):tap(function (teleportOptions)
		-- Cache result
		self._teleportOptions[placeId] = teleportOptions
	end)
	-- Cache promise, forget once resolved
	self._teleportOptionsPromises[placeId] = promise
	promise:finally(function ()
		self._teleportOptionsPromises[placeId] = nil
	end)
	return promise
end

function PopJamConnect:getTeleportOptionsForPlaceId(...)
	return self:getTeleportOptionsForPlaceIdAsync(...):expect()
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
				return getAsyncPromise(dataStore, key):andThen(function (payload, _dataStoreKeyInfo)
					print(self.DS_EVENT_ID, "GetAsync", key)

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
	return self:getHostedEventIdAsync():expect()
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
	return assert(self.dsEventId, "DataStores are not enabled")
end

function PopJamConnect:getTeleportDetailsDataStore()
	return assert(self.dsTeleportDetails, "DataStores are not enabled")
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

function PopJamConnect:persistEventId(privateServerId, eventId)
	local dsEventId = self:getEventIdDataStore()
	local updateAsyncPromise = Promise.promisify(dsEventId.UpdateAsync)
	local key = tostring(privateServerId)
	print("Saving privateServerId => eventId")

	return updateAsyncPromise(dsEventId, key, function (payload, _dataStoreKeyInfo)
		-- Ensure an existing event ID is not being overwritten if it is different
		assert(payload == nil or payload == eventId, ("Unexpected event ID for privateServerId %s: %s"):format(privateServerId, tostring(payload)))
		payload = eventId

		-- Log for debugging
		print(self.DS_EVENT_ID, "UpdateAsync", key, payload)

		return eventId, nil, nil
	end)
end

function PopJamConnect:persistTeleportDetails(placeId, eventId, privateServerId, privateServerAccessCode, isStartPlace)
	-- First, save private server id => eventId
	-- Allows the private server to understand which event it is hosting
	return self:persistEventId(privateServerId, eventId):andThen(function ()
		print("Saving eventId => teleportDetails")
		local dsTeleportDetails = self:getTeleportDetailsDataStore()
		local updateAsyncPromise = Promise.promisify(dsTeleportDetails.UpdateAsync)
		local key = tostring(eventId)
		return updateAsyncPromise(dsTeleportDetails, key, function (payload, _dataStoreKeyInfo)
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
			print(self.DS_TELEPORT_DETAILS, "UpdateAsync", key, payload)

			return payload, nil, nil
		end)
	end)
end

function PopJamConnect:setStartPlaceIdCallback(callback)
	assert(typeof(callback) == "function", "callback should be a function")
	self._placeIdCallback = callback
end

PopJamConnect.ERR_PLACE_ID_INVALID = "ErrPlaceIdInvalid"
function PopJamConnect:isValidPlaceId(placeId)
	return typeof(placeId) == "number" and placeId > 0 and math.floor(placeId) == placeId
end

function PopJamConnect:isMockEventSetupCode(setupCode)
	return self.MOCK_EVENT_SETUP_CODE == setupCode
end

function PopJamConnect:generateMockPopJamEventId(player)
	return 'mock-' .. player.UserId .. "-" .. math.random(1000,9999) .. "-" .. math.random(1000,9999)
end

PopJamConnect.ERR_CANNOT_CREATE_MOCK_EVENT = "ErrCannotCreateMockEvent"
function PopJamConnect:validateSetupCode(setupCode, player)
	if self:isMockEventSetupCode(setupCode) then
		return self:hasMockEventPermissionsAsync(player):andThen(function (hasMockEventPermissions)
			if hasMockEventPermissions then
				return Promise.resolve(self:generateMockPopJamEventId(player), true)
			else
				return Promise.reject(PopJamConnect.ERR_CANNOT_CREATE_MOCK_EVENT)
			end
		end)
	else
		return RukkazAPI:getEventIdBySetupCode(setupCode):andThen(function (popJamEventId)
			return Promise.resolve(popJamEventId, false)
		end)
	end
end

function PopJamConnect:setupEvent(setupCode, player)
	-- Step 1: Validate the event setup code
	return self:validateSetupCode(setupCode, player):andThen(function (popJamEventId, isMockEvent)
		-- Step 2a: Get the start place ID (from callback, if set)
		local placeIdPromise = self._placeIdCallback and Promise.promisify(self._placeIdCallback)(popJamEventId) or Promise.resolve(game.PlaceId)
		return placeIdPromise:andThen(function (placeId)
			assert(PopJamConnect:isValidPlaceId(placeId), PopJamConnect.ERR_PLACE_ID_INVALID)
			-- Step 2b: Reserve a server for the target place ID
			return reserveServerPromise(placeId):andThen(function (privateServerAccessCode, privateServerId)
				-- Step 3: Persist the teleport details in data store
				return self:persistTeleportDetails(placeId, popJamEventId, privateServerId, privateServerAccessCode, true):andThen(function ()
					if isMockEvent then
						-- Mock events stop here - don't actually submit teleport details as the setup code is not good.
						return Promise.resolve(placeId, popJamEventId, privateServerId, privateServerAccessCode)
					else
						-- Step 4: Send teleport details to PopJam for use in the PopJam Portal
						return RukkazAPI:setTeleportDetailsForEvent(popJamEventId, setupCode, placeId, privateServerId, privateServerAccessCode):andThen(function ()
							return Promise.resolve(placeId, popJamEventId, privateServerId, privateServerAccessCode)
						end)
					end
				end)
			end)
		end)
	end)
end

function PopJamConnect:onSetupCodeSubmitted(player, setupCode, ...)
	assert(typeof(setupCode) == "string" and setupCode:len() > 0 and setupCode:len() < 1024, "Setup code must be a nonempty string")
	assert(select("#", ...) == 0, "Too many arguments")
	return self:setupEvent(setupCode, player):catch(function (err)
		warn(tostring(err))
		if tostring(err):lower():match("http requests are not enabled") then
			warn("Did you forget to enable HttpService.HttpEnabled?")
			return Promise.reject("HttpService.HttpEnabled is false")
		elseif err == RukkazAPI.ERR_NO_MATCHING_EVENT then
			return Promise.reject("The setup code you provided doesn't match any event.")
		elseif err == PopJamConnect.ERR_CANNOT_CREATE_MOCK_EVENT then
			return Promise.reject("You are not allowed to create mock events.")
		else
			return Promise.reject("Error - check developer console.")
		end
	end):await()
end

function PopJamConnect:hasMockEventPermissionsAsync(player)
	return self:isGameOwnerOrPopJamAdminAsync(player)
end

function PopJamConnect:isGameOwnerOrPopJamAdminAsync(player)
	return Promise.any{
		-- Do they own the game?
		self:isGameOwnerAsync(player):andThen(function (isOwner)
			if isOwner then
				return Promise.resolve()
			else
				return Promise.reject()
			end
		end);
		-- Are they a PopJam admin?
		self:isPopJamAdminAsync(player):andThen(function (isPopJamAdmin)
			if isPopJamAdmin then
				return Promise.resolve()
			else
				return Promise.reject()
			end
		end);
	}:andThen(function ()
		return Promise.resolve(true)
	end, function ()
		return Promise.resolve(false)
	end)
end

function PopJamConnect:isGameOwnerAsync(player)
	if game.CreatorType == Enum.CreatorType.User then
		return Promise.resolve(game.CreatorId == player.UserId)
	elseif game.CreatorType == Enum.CreatorType.Group then
		return Promise.promisify(player.GetRankInGroup)(player, game.CreatorId):andThen(function (rank)
			return Promise.resolve(rank >= self.GROUP_MIN_RANK)
		end)
	else
		return Promise.reject()
	end
end

function PopJamConnect:hasMockEventPermissions(...)
	return self:hasMockEventPermissionsAsync(...):expect()
end

function PopJamConnect:isPopJamAdminAsync(player)
	return Promise.promisify(player.GetRankInGroup)(player, self.SA_GROUP_ID):andThen(function (rankInSAGroup)
		return Promise.resolve(rankInSAGroup > self.SA_GROUP_MIN_RANK)
	end)
end

function PopJamConnect:isPopJamAdmin(...)
	return self:isPopJamAdminAsync(...):expect()
end

return PopJamConnect.new()
