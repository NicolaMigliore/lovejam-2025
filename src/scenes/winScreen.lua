
local WinScreen = {
    layers = {},
    sfx = {}
}

function WinScreen:enter(current, days)
    self.days = days

    self.layers.mainLayer = self:generateMainLayer()
    self.layers.mainLayer:showLayer()

    self.sfx.click = love.audio.newSource('assets/sounds/click.wav', 'static')
end

function WinScreen:update(dt)

end

function WinScreen:draw()
    Luis.draw()
end

function WinScreen:leave()
    Luis.removeLayer(self.layers.mainLayer.layerName)
end

function WinScreen:keypressed(key, code, isRepeat)
    if key == 'escape' then
        love.event.quit(0)
    end
end

function WinScreen:mousepressed(x, y, button, istouch, presses)
    -- local worldX, worldY = self.graphicsSystem.camera:toWorld(x, y)
    -- world:mousepressed(worldX, worldY, button, istouch, presses)
end

function WinScreen:resize(w, h)
    -- self.graphicsSystem:setCameraScale()
end

function WinScreen:generateMainLayer()
    local layerName = 'mainLayer'
    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    Luis.newLayer(layerName)

    local cW, cH = 18, 25
    local offsetRow, offsetCol = self.gridMaxRow / 2 - cH / 2, self.gridMaxCol / 2 - cW / 2
    local borderImage = love.graphics.newImage('assets/scroll.png')
    local mainLayer = Luis.createElement(layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'mainLayer')
    mainLayer:setDecorator("Slice9Decorator", borderImage, 48, 24, 28, 36)

    -- labels
    local lW, lH = 9, 2
    offsetRow = 3
    offsetCol = (cW / 2 - lW / 2) + 2
    local label1 = Luis.newLabel('Victory', lW, lH, offsetRow, offsetCol, 'center', GAME_SETTINGS.labelTheme)
    mainLayer:addChild(label1, offsetRow, offsetCol)

    offsetRow = offsetRow + lH + 1
    local label2 = Luis.newLabel('The party reached the top floor in '..self.days..' days!', lW, lH, offsetRow, offsetCol, 'center', GAME_SETTINGS.labelTheme)
    mainLayer:addChild(label2, offsetRow, offsetCol)


    -- buttons
    local bW, bH = 9, 2
    offsetRow, offsetCol = cH - 4, cW / 2 - bW / 2 + 2
    local b_add_member = Luis.newButton('Back to Title', bW, bH, function() GameState.switch(GAME_STATES.title) self.sfx.click:play() end,
    nil, offsetRow, offsetCol)
    mainLayer:addChild(b_add_member, offsetRow, offsetCol)


    local layerItem = {
        layerName = layerName,
        containers = {
            mainLayer = mainLayer
        },
        showLayer = function() Luis.enableLayer(layerName) end,
        hideLayer = function() Luis.disableLayer(layerName) end,
    }
    return layerItem
end

return WinScreen
