local Graphics = Object:extend()

function Graphics:new(map)
    self.entities = {}

    -- get map bounds
    -- local terrainLayer = map:getLayer('terrain')
    -- local boundL, boundT, boundR, boundB = terrainLayer:getPixelBounds()

    -- local cameraBoundW, cameraBoundH = 800, 600
    local cameraBoundW, cameraBoundH = GAME_SETTINGS.baseWidth, GAME_SETTINGS.baseHeight
    -- cameraBoundW, cameraBoundH = boundR, boundB

    self.camera = Gamera.new(0, 0, cameraBoundW, cameraBoundH)
    self.baseScale = 2.66

    -- TODO: Map System should also draw within the camera... Consider merging the two systems
    self.cameraTargetId = nil

    self.map = map
end

--- Reset systems entity reference
--- @param entities table<Entity> list of all entities to query
function Graphics:queryEntities(entities)
    self.entities = {}

    for _, e in ipairs(entities) do
        if e.body then
            self.entities[e.id] = e
        end
    end
end

function Graphics:update(dt)
    if self.cameraTargetId then
        local pos = self.entities[self.cameraTargetId].body.position
        self.camera:setPosition(pos.x, pos.y)
    end

    for id, e in pairs(self.entities) do
        if e.animationController then
            e.animationController.activeAnimation:update(dt)
        end
    end
end

function Graphics:draw()
    local function drawInCamera(l, t, w, h)
        if self.bfWorld then
            self.bfWorld:draw()
        end

        -- draw map
        if self.map then
            self.map:draw()
        end

        for id, e in pairs(self.entities) do
            local scaleX, scaleY = 1, 1
            local drawX, drawY = e.body.position.x, e.body.position.y

            if e.animationController then
                local anim = e.animationController.activeAnimation
                if e.size then
                    local frameW, frameH = anim:getDimensions()
                    scaleX = e.size.w / frameW
                    scaleY = e.size.h / frameH
                    drawX = e.body.position.x - e.size.w / 2
                    drawY = e.body.position.y - e.size.h / 2
                end
                anim:draw(e.animationController.image, drawX, drawY, 0, scaleX, scaleY)
            elseif e.texture then
                if e.size then
                    scaleX = e.size.w / e.texture.image:getWidth()
                    scaleY = e.size.h / e.texture.image:getHeight()
                    drawX = e.body.position.x - e.size.w / 2
                    drawY = e.body.position.y - e.size.h / 2
                end
                love.graphics.draw(e.texture.image, drawX, drawY, 0, scaleX, scaleY)
            else
                if e.size then
                    scaleX = e.size.w
                end
                love.graphics.circle('fill', drawX, drawY, scaleX)
            end

            -- love.graphics.circle('line', e.body.position.x, e.body.position.y, 4)
        end
    end

    self.camera:draw(drawInCamera)
end

function Graphics:setCameraTarget(targetId)
    self.cameraTargetId = targetId
end

function Graphics:setCameraScale()
    self.baseScale = 4
    local baseResX, baseResY = 1280, 720
    local windowW, windowH = love.window.getMode()
    local windowScaleX, windowScaleY = windowW / baseResX, windowH / baseResY
    local windowScale = math.min(windowScaleX, windowScaleY)
    local newCameraScale = math.floor(self.baseScale * windowScale)

    self.camera:setScale(newCameraScale)
    self.camera:setWindow(0, 0, windowW, windowH)
end

function Graphics:setPhysicsWorld(bfWorld)
    self.bfWorld = bfWorld
end

return Graphics
