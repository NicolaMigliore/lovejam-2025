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
            if action.delay then
                -- Timer.after(action.delay, function() print('action called') end)
                local function test()
                    action.fn(dt, e)
                end
                Timer.after(action.delay, test)
                e.actionController.cooldown = true
            end
            e.actionController.actionIndex = e.actionController.actionIndex + 1
        end
    end
end

return Action