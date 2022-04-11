local ReplicatedStorage = game:GetService("ReplicatedStorage")
local popJamConnect = ReplicatedStorage:WaitForChild("PopJamConnect")
local setupCodeRemotes = popJamConnect:WaitForChild("Remotes"):WaitForChild("SetupCode")
local eventIdRemotes = popJamConnect.Remotes:WaitForChild("EventId")

local lib = require(popJamConnect:WaitForChild("lib"))
local StateMachine = lib.StateMachine

local EventSetupWindow = {}
EventSetupWindow.__index = EventSetupWindow
EventSetupWindow.STATE_EVENT_ID = "StateEventId"
EventSetupWindow.STATE_SETUP_CODE = "StateSetupCode"
EventSetupWindow.STATE_MODAL = "StateModal"
EventSetupWindow.reSetupCodePrompt = setupCodeRemotes:WaitForChild("Prompt")
EventSetupWindow.rfSetupCodeSubmit = setupCodeRemotes:WaitForChild("Submit")
EventSetupWindow.reEventIdPrompt = eventIdRemotes:WaitForChild("Prompt")
EventSetupWindow.rfEventIdSubmit = eventIdRemotes:WaitForChild("Submit")

function EventSetupWindow.new(frame)
	local self = setmetatable({
		frame = frame;
	}, EventSetupWindow)
	
	self.tlTitleBar = self.frame:WaitForChild("TitleBar")
	self.bClose = self.tlTitleBar:WaitForChild("Close")
	
	self.stateMachine = StateMachine.new()
	
	-- Setup code
	self.frEnterCode = frame:WaitForChild("EnterSetupCode")
	self.frEnterCode.Visible = false
	self.setupCodeState = self.stateMachine:newState(EventSetupWindow.STATE_SETUP_CODE)
	self.setupCodeState.enter = function (...)
		return self:enterSetupCodeState(...)
	end
	self.setupCodeState.leave = function (...)
		return self:leaveSetupCodeState(...)
	end
	self.frEnterCode:WaitForChild("HBox")
	self.tbSetupCode = self.frEnterCode.HBox:WaitForChild("SetupCode")
	self.bSubmitSetupCode = self.frEnterCode.HBox:WaitForChild("Submit")
	self.bSubmitSetupCode.Activated:Connect(function ()
		self:submitSetupCode()
	end)
	self._submitSetupCodeCallback = function (_self, _tetxt)
		self.setupCodeState:transition()
	end
	self:setSetupCodeEnabled(true)
	
	-- Event id
	self.frEnterEventId = frame:WaitForChild("EnterEventId")
	self.frEnterEventId.Visible = false
	self.eventIdState = self.stateMachine:newState(EventSetupWindow.STATE_EVENT_ID)
	self.eventIdState.enter = function (...)
		return self:enterEventIdState(...)
	end
	self.eventIdState.leave = function (...)
		return self:leaveEventIdState(...)
	end
	self.frEnterEventId:WaitForChild("HBox")
	self.tbEventId = self.frEnterEventId.HBox:WaitForChild("EventId")
	self.bSubmitEventId = self.frEnterEventId.HBox:WaitForChild("Submit")
	self.bSubmitEventId.Activated:Connect(function ()
		self:submitEventId()
	end)
	self._submitEventIdCallback = function (_self, _tetxt)
		self.eventIdState:transition()
	end
	self:setEventIdEnabled(true)

	-- Modal
	self.frModal = self.frame:WaitForChild("Modal")
	self.frModal.Visible = false
	self.modalState = self.stateMachine:newState(EventSetupWindow.STATE_MODAL)
	self.modalState.enter = function (...)
		return self:enterModalState(...)
	end
	self.modalState.leave = function (...)
		return self:leaveModalState(...)
	end
	self.tlModalContent = self.frModal:WaitForChild("Content")
	self.modalButtonsContainer = self.frModal:WaitForChild("HBox")
	self.bModalButtonPrefab = self.modalButtonsContainer:WaitForChild("Button")
	self.bModalButtonPrefab.Parent = nil
	self._defaultModalCallback = function (_self, _text)
		warn("No modal callback defined")
		self:close()
	end

	self:close()
	self.bClose.Activated:Connect(function ()
		self:close()
	end)

	-- Start listening for prompts
	self._promptSetupCodeConn = EventSetupWindow.reSetupCodePrompt.OnClientEvent:Connect(function (...)
		return self:onSetupCodePrompted(...)
	end)
	self._promptEventIdConn = EventSetupWindow.reEventIdPrompt.OnClientEvent:Connect(function (...)
		return self:onEventIdPrompted(...)
	end)
	
	return self
end

function EventSetupWindow:open()
	self.frame.Visible = true
end

function EventSetupWindow:close()
	self.frame.Visible = false
end

function EventSetupWindow:setClosable(closable)
	self.bClose.Visible = closable
	self._closable = closable
end

do -- Enter code state
	function EventSetupWindow:onSetupCodePrompted()
		self:open()
		self.setupCodeState:transition()
	end

	function EventSetupWindow:enterSetupCodeState()
		StateMachine.State.enter(self.setupCodeState) -- call super
		self.frEnterCode.Visible = true
		self:setClosable(true)
		self.tbSetupCode:CaptureFocus()
	end
	
	function EventSetupWindow:leaveSetupCodeState()
		StateMachine.State.leave(self.setupCodeState) -- call super
		self.frEnterCode.Visible = false
		self:setClosable(false)
	end
	
	function EventSetupWindow:submitSetupCode()
		if self._submitDebounce then return end
		local setupCode = self.tbSetupCode.Text
		if self:isSetupCodeValid(setupCode) then
			self._submitDebounce = true
			self:setSetupCodeEnabled(false)
			
			self:showModal("Submitting setup code...", function () end, {}, false)
			local results = {pcall(self.rfSetupCodeSubmit.InvokeServer, self.rfSetupCodeSubmit, setupCode)}
			print("Response:", unpack(results))
			if results[1] then
				if results[2] then
					local _placeId, popJamEventId, _privateServerId, _privateServerAccessCode = results[3], results[4], results[5], results[6]
					if popJamEventId:sub(1, 5) == "mock-" then
						self:showModal(
							"Success! Mock event is set up. Mock event ID:\n" .. tostring(popJamEventId),
							function (_self, text)
								if text == "Join" then
									self.eventIdState:transition()
									self.tbEventId.Text = popJamEventId
								end
							end,
							{"Join", "Close"}, true
						)
					else
						self:showModal("Success! Your event is all set up now.", self._submitSetupCodeCallback, {"Close"}, true)
					end
				else
					self:showModal(
						typeof(results[3]) == "string" and results[3] or "Something went wrong while setting up your event.",
						self._submitSetupCodeCallback, {"Try again", "Close"}, true
					)
				end
			else
				self:showModal("An error occured while submitting the setup code.", self._submitSetupCodeCallback, {"Try again", "Close"}, true)
			end

			self:setSetupCodeEnabled(true)
			self._submitDebounce = nil
		else
			self.tbSetupCode:CaptureFocus()
		end
	end
	
	function EventSetupWindow:setSetupCodeEnabled(enabled)
		self.tbSetupCode.TextEditable = enabled
		self.bSubmitSetupCode.AutoButtonColor = enabled
	end
	
	function EventSetupWindow:isSetupCodeValid(setupCode)
		return setupCode:len() > 0
	end
end

do -- Enter event id 
	function EventSetupWindow:onEventIdPrompted()
		self:open()
		self.eventIdState:transition()
	end

	function EventSetupWindow:enterEventIdState()
		StateMachine.State.enter(self.setupCodeState) -- call super
		self.frEnterEventId.Visible = true
		self:setClosable(true)
		self.tbEventId:CaptureFocus()
	end
	
	function EventSetupWindow:leaveEventIdState()
		StateMachine.State.leave(self.setupCodeState) -- call super
		self.frEnterEventId.Visible = false
		self:setClosable(false)
	end
	
	function EventSetupWindow:submitEventId()
		if self._submitDebounce then return end
		local eventId = self.tbEventId.Text
		if self:isEventIdValid(eventId) then
			self._submitDebounce = true
			self:setEventIdEnabled(false)
			
			self:showModal("Submitting event id...", function () end, {}, false)
			local results = {pcall(self.rfEventIdSubmit.InvokeServer, self.rfEventIdSubmit, eventId)}
			print("Response:", unpack(results))
			if results[1] then
				if results[2] then
					self:showModal("Teleporting!", self._submitEventIdCallback, {"Close"}, true)
				else
					if results[3] == "ErrMustUsePortal" then
						self:showModal(
							"You must use the PopJam Portal to do that.",
							self._submitEventIdCallback, {"Try again", "Close"}, true
						)
					else
						self:showModal(
							typeof(results[3]) == "string" and results[3] or "Something went wrong.",
							self._submitEventIdCallback, {"Try again", "Close"}, true
						)
					end
				end
			else
				self:showModal("An error occured while submitting the event id.", self._submitEventIdCallback, {"Try again", "Close"}, true)
			end

			self:setEventIdEnabled(true)
			self._submitDebounce = nil
		else
			self.tbSetupCode:CaptureFocus()
		end
	end
	
	function EventSetupWindow:setEventIdEnabled(enabled)
		self.tbEventId.TextEditable = enabled
		self.bSubmitEventId.AutoButtonColor = enabled
	end
	
	function EventSetupWindow:isEventIdValid(eventId)
		return eventId:len() > 0
	end
end

do -- Modal state
	function EventSetupWindow:enterModalState()
		StateMachine.State.enter(self.modalState) -- call super
		self.frModal.Visible = true
		self._modalButtons = {}
	end

	function EventSetupWindow:leaveModalState()
		StateMachine.State.leave(self.modalState) -- call super
		self.frModal.Visible = false
		self.tlModalContent.Text = ""
		if self._modalButtons then
			self:destroyModalButtons()
		end
	end
	
	function EventSetupWindow:destroyModalButtons()
		for button, conn in pairs(self._modalButtons) do
			conn:Disconnect()
			self._modalButtons[button] = nil
			button:Destroy()
		end
	end
	
	function EventSetupWindow:showModal(content, callback, buttons, closable)
		callback = callback or self._defaultModalCallback
		buttons = buttons or {"OK"}
		
		assert(typeof(content) == "string", "text should be a string")
		assert(typeof(callback) == "function", "callback should be a function")
		assert(typeof(buttons) == "table", "buttons should be a table")
		
		self.modalState:transition()
		self:setClosable(closable)
		self.tlModalContent.Text = content
		
		-- Modal buttons
		self:destroyModalButtons()
		self.modalButtonsContainer.Visible = #buttons > 0
		for _i, text in pairs(buttons) do
			assert(typeof(text) == "string", "value should be a string")
			local button = self.bModalButtonPrefab:Clone()
			button.Text = text:upper()
			button.Size = UDim2.new(
				1 / #buttons, -10,
				self.bModalButtonPrefab.Size.Y.Scale, self.bModalButtonPrefab.Size.Y.Offset
			)
			button.Parent = self.modalButtonsContainer
			self._modalButtons[button] = button.Activated:Connect(function ()
				if text == "Close" then
					self:close()
				else
					callback(self, text)
				end
			end)
		end
	end
end

return EventSetupWindow
