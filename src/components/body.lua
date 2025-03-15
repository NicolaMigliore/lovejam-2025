local Body = Object:extend()

function Body:new(position, velocity, maxSpeed)
    self.position = position
    self.direction = Vector(0, 1)
    self.velocity = velocity or Vector(0, 0)
    self.acceleration = Vector(0, 0)
    self.maxSpeed = maxSpeed or 10
end

return Body
