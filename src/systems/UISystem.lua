local UI = Object:extend()

function UI:new()
    self.entities = {}

    self.buttons = {
        { text = 'move up',    onClick = nil, position = Vector(500, 20) },
        { text = 'move right', onClick = nil, position = Vector(500, 50) },
        { text = 'move down',  onClick = nil, position = Vector(500, 80) },
        { text = 'move left',  onClick = nil, position = Vector(500, 110) },
        { text = 'Run',        onClick = nil, position = Vector(500, 140) },
    }


end

--- Reset systems entity reference
--- @param entities table<Entity> list of all entities to query
function UI:queryEntities(entities)
    -- self.entities = {}

    -- for _, e in ipairs(entities) do
    --     if e.body then
    --         self.entities[e.id] = e
    --     end
    -- end
end

function UI:update(dt)

end

function UI:draw()
    for index, b in ipairs(self.buttons) do
        love.graphics.setColor(.6, .6, .6)
        love.graphics.rectangle('fill', b.position.x - 5, b.position.y - 3, 100, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(b.text, b.position.x, b.position.y)
    end
end

return UI
