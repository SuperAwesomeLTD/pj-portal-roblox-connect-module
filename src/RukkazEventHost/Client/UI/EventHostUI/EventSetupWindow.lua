local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rukkazEventHost = ReplicatedStorage:WaitForChild("RukkazEventHost")
local setupCodeRemotes = rukkazEventHost:WaitForChild("Remotes"):WaitForChild("SetupCode")

local lib = require(rukkazEventHost:WaitForChild("lib"))
local StateMachine = lib.StateMachine

local EventSetupWindow = {}
EventSetupWindow.__index = EventSetupWindow
EventSetupWindow.STATE_SETUP_CODE = "StateSetupCode"
EventSetupWindow.STATE_MODAL = "StateModal"
EventSetupWindow.reSetupCodePrompt = setupCodeRemotes:WaitForChild("Prompt")
EventSetupWindow.rfSetupCodeSubmit = setupCodeRemotes:WaitForChild("Submit")

function EventSetupWindow.new(frame)
	local self = setmetatable({
		frame = frame;
	}, EventSetupWindow)
	
	self.tlTitleBar = self.frame:WaitForChild("TitleBar")
	self.bClose = self.tlTitleBar:WaitForChild("Close")
	
	self.stateMachine = StateMachine.new()
	
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
	self.bSubmit = self.frEnterCode.HBox:WaitForChild("Submit")
	self.bSubmit.Activated:Connect(function ()
		self:submitSetupCode()
	end)

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
		self.setupCodeState:transition()
	end

	self:close()
	self.bClose.Activated:Connect(function ()
		self:close()
	end)

	self._promptedConn = EventSetupWindow.reSetupCodePrompt.OnClientEvent:Connect(function (...)
		return self:onSetupCodePrompted(...)
	end)
	self:setSetupCodeEnabled(true)
	
	return self
end

function EventSetupWindow:onSetupCodePrompted()
	self:open()
end

function EventSetupWindow:open()
	self.frame.Visible = true
	self.setupCodeState:transition()
end

function EventSetupWindow:close()
	self.frame.Visible = false
end

function EventSetupWindow:setClosable(closable)
	self.bClose.Visible = closable
	self._closable = closable
end

do -- Enter code state
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
					self:showModal("Success! Your event is all set up now.", nil, {"Close"}, true)
				else
					self:showModal("Something went wrong while setting up your event.", nil, {"Try again", "Close"}, true)
				end
			else
				self:showModal("An error occured while submitting the setup code.", nil, {"Try again", "Close"}, true)
			end

			self:setSetupCodeEnabled(true)
			self._submitDebounce = nil
		else
			self.tbSetupCode:CaptureFocus()
		end
	end
	
	function EventSetupWindow:setSetupCodeEnabled(enabled)
		self.tbSetupCode.TextEditable = enabled
		self.bSubmit.AutoButtonColor = enabled
	end
	
	function EventSetupWindow:isSetupCodeValid(setupCode)
		return setupCode:len() > 0
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
			button.Text = text
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
