local Action = Object:extend()

function Action:new(fn, delay, label)
    self.fn = fn
    self.delay = delay
    -- self.duration = duration
    self.label = label
end

function Action:setDelay(newDelay)
    self.delay = newDelay
end

local ActionController = Object:extend()

function ActionController:new(list)
    self.actionIndex = 1
    self.actions = list
    self.cooldown = nil
end

return { ActionController, Action }
