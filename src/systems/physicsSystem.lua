local Physics = Object:extend()

function Physics:new(bfWorld)
    self.bfWorld = bfWorld
    self.entities = {}

    self.ground = BF.Collider.new(self.bfWorld, "Polygon", {0, 550, 650, 550 , 650, 650, 0, 650})
    self.ground:setType("static")
end

--- Reset systems entity reference
--- @param entities table<Entity> list of all entities to query
function Physics:queryEntities(entities)
    self.entities = {}

    for _, e in ipairs(entities) do
        if e.body then
            self.entities[e.id] = e
        end
    end
end

function Physics:update(dt)
    for id, e in pairs(self.entities) do
        -- e.body.velocity = e.body.velocity + e.body.acceleration -- add acceleration
        -- local mass = .5
        -- local friction = e.body.velocity:normalized() * -1 * mass
        -- e.body.velocity = e.body.velocity + friction -- sub friction
        -- -- Avoid drift
        -- if math.abs(e.body.velocity:len()) <= 1 then
        --     e.body.velocity = Vector(0, 0)
        -- end

        -- -- Set direction
        -- if math.abs(e.body.velocity:len()) > 0 then
        --     if math.abs(e.body.velocity.x) > math.abs(e.body.velocity.y) then
        --         e.body.direction = Vector(e.body.velocity.x, 0):normalized()
        --     else
        --         e.body.direction = Vector(0, e.body.velocity.y):normalized()
        --     end
        -- end

        -- e.body.velocity = e.body.velocity:trimmed(e.body.maxSpeed)
        -- e.body.position = e.body.position + e.body.velocity
        
        if e.collider then
            local x, y = e.collider:getPosition()
            e.body.position = Vector(x, y)
        end
    end
end

return Physics