

local GraphicsSystem = require 'src.systems.graphicsSystem'

local world = ECSWorld()
local Title = {
    layers = {},
    images = {},
    music = {},
    sfx = {},
}

function Title:enter()
    self.layers.mainMenu = self:generateMainMenu()
    self.layers.mainMenu:showLayer()

    -- load image
    self.images.background = love.graphics.newImage('assets/title.png')

    -- load sounds
    self.music.title = love.audio.newSource('assets/music/649132__sonically_sound__medievalfantasy-rpg-loop-mix-at-32-secs-to-extendrepeat.flac', 'stream')
    self.music.title:play()
    self.sfx.click = love.audio.newSource('assets/sounds/click.wav', 'static')
end

function Title:update(dt)

end

function Title:draw()
    local imgW, imgH = self.images.background:getWidth(), self.images.background:getHeight()
    local scaleX, scaleY = GAME_SETTINGS.baseWidth / imgW, GAME_SETTINGS.baseHeight / imgH
    love.graphics.draw(self.images.background, 0, 0, 0, scaleX, scaleY)
    Luis.draw()
end

function Title:leave()
    Luis.removeLayer(self.layers.mainMenu.layerName)
    love.audio.stop(self.music.title)
end

function Title:keypressed(key, code, isRepeat)
    if key == 'escape' then
        love.event.quit(0)
    end
end

function Title:mousepressed(x, y, button, istouch, presses)
    -- local worldX, worldY = self.graphicsSystem.camera:toWorld(x, y)
    -- world:mousepressed(worldX, worldY, button, istouch, presses)
end

function Title:resize(w, h)
    -- self.graphicsSystem:setCameraScale()
end

function Title:generateMainMenu()
    local layerName = 'mainMenu'
    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    Luis.newLayer(layerName)

    local cW, cH = 18, 15
    local offsetRow, offsetCol = self.gridMaxRow / 2 - cH / 2, self.gridMaxCol / 2 - cW / 2
    offsetRow = 15
    offsetCol = offsetCol +1
    local borderImage = love.graphics.newImage('assets/scroll.png')
    local c_mainMenu = Luis.createElement(layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'c_mainMenu')
    c_mainMenu:setDecorator("Slice9Decorator", borderImage, 48, 24, 28, 36)

    -- buttons
    local bW, bH = 9, 2
    offsetRow = cH / 2 - bH / 2
    offsetCol = (cW / 2 - bW / 2) + 1.5
    local b_add_member = Luis.newButton('New Game', bW, bH, function() GameState.switch(GAME_STATES.dungeonPlanner) self.sfx.click:play() end,
    nil, offsetRow, offsetCol)
    c_mainMenu:addChild(b_add_member, offsetRow, offsetCol)


    local layerItem = {
        layerName = layerName,
        containers = {
            c_mainMenu = c_mainMenu
        },
        showLayer = function() Luis.enableLayer(layerName) end,
        hideLayer = function() Luis.disableLayer(layerName) end,
    }
    return layerItem
end

return Title
