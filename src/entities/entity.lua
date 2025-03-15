local Entity = Object:extend()

function Entity:new()
    self.id = Lume.uuid()
end

function Entity:__tostring()
    local e = {
        id = self.id,
        components = {}
    }
    for key, value in pairs(self) do
        table.insert(e.components, key)
    end
    return Json.encode(e)
end

return Entity