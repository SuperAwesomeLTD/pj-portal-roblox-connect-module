--- A state of a @{StateMachine}.
-- You probably want to use @{StateMachine:newState} to create one.
-- @classmod StateMachine.State

local Event = require(script.Parent.Parent:WaitForChild("Event"))

local State = {}
State.__index = State

--- Fires when a @{StateMachine} @{StateMachine:transition|transitions} into this state.
-- @event onEnter

--- Fires when a @{StateMachine} @{StateMachine:transition|transitions} out of this state.
-- @event onLeave

--- Construct a new state.
-- @tparam StateMachine machine The `StateMachine` to which the new state should belong.
-- @tparam string id An identifier for the new state, must be unique within the owning `StateMachine`.
-- @tparam[opt] function onEnterFunction A `function` to connect to the onEnter event upon creation.
-- @constructor State.new
-- @see StateMachine:newState
-- @usage local state = State.new(machine, id, onEnterFunction)
-- @usage local state = machine:newState(id, onEnterFunction)
function State.new(machine, id, onEnterFunction)
	if type(id) ~= "string" then
		error("State.new expects string id", 3)
	end
	local self = setmetatable({
		machine = machine;
		id = id;
		onEnter = Event.new();
		onLeave = Event.new();
	}, State)
	
	if type(onEnterFunction) == "function" then
		self.onEnter:connect(onEnterFunction)
	elseif type(onEnterFunction) ~= "nil" then
		error("State.new() was given non-function onEnterFunction (" .. type(onEnterFunction) .. ", " .. tostring(onEnterFunction) .. ")")
	end	
	
	return self
end

function State:cleanup()
	self.machine = nil
	self.onEnter:cleanup()
	self.onEnter = nil
	self.onLeave:cleanup()
	self.onLeave = nil
end

--- Fires the {@StateMachine.State.onEnter|onEnter} event.
-- Passes all arguments to `Event:fire`.
function State:enter(...)
	self.onEnter:fire(...)
end

--- Fires the {@StateMachine.State.onEnter|onEnter} event.
-- Passes all arguments to `Event:fire`.
function State:leave(...)
	self.onLeave:fire(...)
end

--- Orders the owning @{StateMachine} to @{StateMachine:transition|transition} to this state.
-- @return The result of the @{StateMachine:transition|transition}.
function State:transition()
	return self.machine:transition(self)
end

return State
