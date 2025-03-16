local Action = Object:extend()

function Action:new()
    self.entities = {}
end

--- Reset systems entity reference
--- @param entities table<Entity> list of all entities to query
function Action:queryEntities(entities)
    self.entities = {}

    for _, e in ipairs(entities) do
        if e.actionController then
            self.entities[e.id] = e
        end
    end
end

function Action:update(dt)
    for id, e in pairs(self.entities) do
        local noCooldown = not e.actionController.cooldown --e.actionController.cooldown == nil or e.actionController.cooldown == 0
        local hasNextAction = e.actionController.actionIndex <= #e.actionController.actions
        if noCooldown and hasNextAction then
            local action = e.actionController.actions[e.actionController.actionIndex]
            if action.delay and not action.executed then
                local function test()
                    action.fn(dt, e)
                    action.executed = true
                end
                Timer.during(action.delay, test, function() e.actionController.actionIndex = e.actionController.actionIndex + 1 end)
                e.actionController.cooldown = true
            end
        end
    end
end

return Action