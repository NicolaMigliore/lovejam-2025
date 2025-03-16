local ECSWorld = Object:extend()

function ECSWorld:new()
    self.entities = {}
    self.systems = {}
end

function ECSWorld:registerSystem(system)
    table.insert(self.systems, system)
end

function ECSWorld:registerEntity(entity)
    table.insert(self.entities, entity)

    -- refresh system queries
    for _, system in ipairs(self.systems) do
        system:queryEntities(self.entities)
    end
end

function ECSWorld:unregisterEntity(entityId)
    local e, index = Lume.match(self.entities, function(x) return x.id == entityId end)

    table.remove(self.entities, index)

    -- refresh system queries
    for _, system in ipairs(self.systems) do
        system:queryEntities(self.entities)
    end
end

function ECSWorld:update(dt)
    for _, system in ipairs(self.systems) do
        if system.update then
            system:update(dt)
        end
    end
end

function ECSWorld:draw()
    for _, system in ipairs(self.systems) do
        if system.draw then
            system:draw()
        end
    end
end

function ECSWorld:keypressed(key, code, isRepeat)
    for _, system in ipairs(self.systems) do
        if system.keypressed then
            system:keypressed(key, code, isRepeat)
        end
    end
end

function ECSWorld:mousepressed(x, y, button, istouch, presses)
    for _, system in ipairs(self.systems) do
        if system.mousepressed then
            system:mousepressed(x, y, button, istouch, presses)
        end
    end
end

return ECSWorld