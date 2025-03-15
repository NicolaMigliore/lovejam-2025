local ECSWorld = require 'src.ECSWorld'
local GraphicsSystem = require 'src.systems.graphicsSystem'
local ActionSystem = require 'src.systems.actionSystem'
local PhysicsSystem = require 'src.systems.physicsSystem'
-- local UISystem = require 'src.systems.UISystem'
-- local ControlSystem = require 'src.systems.controlSystem'
-- local MapSystem = require 'src.systems.mapSystem'

local Actor = require 'src.entities.actor'
local actionComponents = require 'src.components.action'
local ActionController, Action = actionComponents[1], actionComponents[2]

local world = ECSWorld()

local Level1 = {
}

function Level1:enter()
    -- register systems
    self.graphicsSystem = GraphicsSystem(nil)
    -- self.graphicsSystem:setCameraScale()
    world:registerSystem(self.graphicsSystem)
    -- local mapSystem = MapSystem(self.map)
    -- world:registerSystem(mapSystem)
    -- world:registerSystem(ControlSystem)
    world:registerSystem(PhysicsSystem())
    world:registerSystem(ActionSystem())
    -- world:registerSystem(UISystem())

    -- self.graphicsSystem:setCameraTarget(self.player.id)

    -- basic ui
    self:configureUI()

    -- DEBUG
end

function Level1:update(dt)
    world:update(dt)
end

function Level1:draw()
    world:draw()
end

function Level1:keypressed(key, code, isRepeat)
    if key == 'escape' then
        love.event.quit(0)
    end

    world:keypressed(key, code, isRepeat)
end

function Level1:mousepressed(x, y, button, istouch, presses)
    -- local worldX, worldY = self.graphicsSystem.camera:toWorld(x, y)
    -- world:mousepressed(worldX, worldY, button, istouch, presses)
end

function Level1:resize(w, h)
    -- self.graphicsSystem:setCameraScale()
end

function Level1:configureUI_test()
    Luis.newLayer("main_menu")

    local centerX = Luis.baseWidth / 2
    local startY = 200
    local buttonWidth = 300
    local buttonHeight = 60
    local spacing = 20

    -- Luis.createElement("main_menu", "Label", centerX - 150, 100, "RETRO GAME", 300)
    -- Luis.createElement("main_menu", "Label", "RETRO GAME", centerX - 150, 100, 3, 10)
    Luis.createElement("main_menu", "Label", "RETRO GAME", 10, 3, 3, 10)

    -- Luis.createElement("main_menu", "Button", centerX - buttonWidth/2, startY, buttonWidth, buttonHeight, "Start Game", function() print("Start Game") end)
    Luis.enableLayer("main_menu")
    Luis.setCurrentLayer('main_menu')
end

function Level1:configureUI()
    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    local gridMaxCol, gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    local actionListContainer
    local actionList = {}


    -- Layer
    Luis.newLayer('main')
    Luis.setCurrentLayer('main')

    -- Commands
    local speed = 100
    local baseActions = {
        actMoveU = function(delay)
            return Action(
                function(dt, e)
                    e.body.acceleration = Vector(0, -1) * speed * dt
                    -- print('actMoveU', e.body.acceleration)
                    e.actionController.cooldown = false
                end
                , delay, 'Go Up')
        end,
        actMoveR = function(delay)
            return Action(
                function(dt, e)
                    e.body.acceleration = Vector(1, 0) * speed * dt
                    e.actionController.cooldown = false
                end, delay, 'Go Right')
        end,
        actMoveD = function(delay)
            return Action(
                function(dt, e)
                    e.body.acceleration = Vector(0, 1) * speed * dt
                    e.actionController.cooldown = false
                end, delay, 'Go Down')
        end,
        actMoveL = function(delay)
            return Action(
                function(dt, e)
                    e.body.acceleration = Vector(-1, 0) * speed * dt
                    e.actionController.cooldown = false
                end, delay, 'Go Left')
        end
    }
    local baseActionsList = {
        'actMoveU',
        'actMoveR',
        'actMoveD',
        'actMoveL',
    }

    -- Dropdown
    local ddW, ddH = 8, 2
    local offsetRow, offsetCol = 2, 2
    local selectedAction = baseActionsList[1]
    Luis.createElement(Luis.currentLayer, 'DropDown', baseActionsList, 1, ddW, ddH,
        function(val) selectedAction = val end, offsetRow, offsetCol, 4)
    offsetCol = offsetCol + ddW + 1

    -- Slider
    local selectedDelay = 1
    local sW, sH, lw = 12, 2, 3
    local l_delay = Luis.createElement(Luis.currentLayer, 'Label', '1', lw, sH, offsetRow, offsetCol + sW + 1)
    Luis.createElement(Luis.currentLayer, 'Slider', 0, 5, 1, sW, sH, function(val)
            print(val)
            val = Utils:round(val, 2)
            selectedDelay = val
            l_delay:setText(selectedDelay)
            print(selectedDelay)
        end,
        offsetRow, offsetCol)
    offsetCol = offsetCol + sW + lw + 2


    -- Button
    local bW, bH = 8, 2
    Luis.createElement("main", "Button", 'Add Action', bW, bH,
        function()
            local actionFabric = baseActions[selectedAction]
            local action = actionFabric(selectedDelay)
            table.insert(actionList, action)

            local text = action.label .. ' after ' .. action.delay .. 's'
            local l = Luis.newLabel(text, 10, 1, 1, 1)
            -- if self.player.actionController.actionIndex == index then
            --     l:setDecorator("GlowDecorator", { 1, 0.5, 0, 0.1 }, 3)
            -- end
            actionListContainer:addChild(l)
        end,
        function() print("Button 1 released!") end,
        offsetRow, offsetCol)
    offsetCol = offsetCol + bH + 1


    -- Container
    local contCol = 2
    local contRow = offsetRow + ddH + 1
    local cW, cH = 10, gridMaxRow - contRow -- Container width and height in number of grid cells
    local container = Luis.newFlexContainer(cW, cH, contRow, contCol)
    -- local container = Luis.newFlexContainer(cW, cH, 25, 10)
    local b_confirm = Luis.createElement("main", "Button", 'Confirm Actions', cW, 2,
        function() self:setupPlayer(actionList) end, nil, 1, 1)
    container:addChild(b_confirm)

    actionListContainer = Luis.createElement(Luis.currentLayer, 'FlexContainer', container)
    container:setDecorator("GlowDecorator", { 1, 0.5, 0, 0.1 }, 3)

    -- set window mode
    -- love.window.setMode(1280, 1024)
end

function Level1:setupPlayer(actions)
    -- register entities
    self.player = Actor(actions)
    world:registerEntity(self.player)
end

return Level1
