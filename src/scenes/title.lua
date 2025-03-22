local Plan = require 'src.layers.plan'
local Dungeon = require 'src.layers.dungeon'
local Recap = require 'src.layers.recap'
local Event = require 'src.event'
local PartyMember = require 'src.entities.partyMember'

local GraphicsSystem = require 'src.systems.graphicsSystem'

local world = ECSWorld()
local Title = {
    layers = {}
}

function Title:enter()
    self.layers.mainMenu = self:generateMainMenu()
    self.layers.mainMenu:showLayer()
end

function Title:update(dt)

end

function Title:draw()
    Luis.draw()
end

function Title:leave()
    Luis.removeLayer(self.layers.mainMenu.layerName)
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

    local cW, cH = 18, 25
    local offsetRow, offsetCol = self.gridMaxRow / 2 - cH / 2, self.gridMaxCol / 2 - cW / 2
    local borderImage = love.graphics.newImage('assets/ui.png')
    local c_mainMenu = Luis.createElement(layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'c_mainMenu')
    c_mainMenu:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)

    -- buttons
    local bW, bH = 9, 2
    offsetRow = offsetRow + 5
    offsetCol = (cW / 2 - bW / 2) + 1
    local b_add_member = Luis.newButton('New Game', bW, bH, function() GameState.switch(GAME_STATES.dungeonPlanner) end,
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
