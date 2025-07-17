local Event = Object:extend()

function Event:new(type, code, label, icon, target, targetAttribute, modifier, getRecapFn)
    self.type = type
    self.code = code
    self.label = label
    self.icon = icon
    self.target = target
    self.targetAttribute = targetAttribute
    self.modifier = modifier
    self.getRecapFn = getRecapFn
end

function Event:__tostring()
    local e = {
        type = self.type,
        code = self.code,
        label = self.label,
        modifier = self.modifier
    }
    return Json.encode(e)
end


return Event
