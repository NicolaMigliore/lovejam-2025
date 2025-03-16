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
    actionList = {},
    layers = {}
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

    if Luis.isLayerEnabled('debug') then
        self:updateDebugLayer()
    end
    if Luis.isLayerEnabled('listActions') then
        self:updateListActionsLayer()
    end
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


function Level1:configureUI()
    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    local gridMaxCol, gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    local actionListContainer

    -- Define Layers
    self:createDebugLayer(gridMaxRow, gridMaxCol)
    self:createDefineActionsLayer(gridMaxRow)
    self:createListActionsLayer(gridMaxRow)

    Luis.enableLayer('debug')
    Luis.enableLayer('defineActions')
    Luis.disableLayer('listActions')


    -- set window mode
    -- love.window.setMode(1280, 1024)
end

function Level1:createDebugLayer(gridMaxRow, gridMaxCol)
    Luis.newLayer('debug')
    self.layers.debug = {}

    local offsetRow = 10
    local lW, lH = 10, 2

    -- player label
    local text = 'player: nil'
    if self.player then
        text = 'player: '..self.player.id
    end
    local playerLabel = Luis.createElement('debug', 'Label', text, lW, lH, offsetRow, gridMaxCol - lW - 1)
    self.layers.debug.playerLabel = playerLabel
    offsetRow = offsetRow + 2

    text = 'no. actions: 0'
    if self.player and self.player.actionController then
        text = 'no. actions: '..#self.player.actionController.actions
    end
    local actionsLabel = Luis.createElement('debug', 'Label', text, lW, lH, offsetRow, gridMaxCol - lW - 1)
    self.layers.debug.actionsLabel = actionsLabel
    offsetRow = offsetRow + 2

    text = 'action index: 0'
    if self.player and self.player.actionController then
        text = 'action index: '..self.player.actionController.actionIndex
    end
    local actionIndexLabel = Luis.createElement('debug', 'Label', text, lW, lH, offsetRow, gridMaxCol - lW - 1)
    self.layers.debug.actionIndexLabel = actionIndexLabel
    offsetRow = offsetRow + 2

    for _, action in ipairs(self.actionList) do
        local actionIndexLabel = Luis.createElement('debug', 'Label', 'action_'.._..' executed: '..tostring(action.executed), text, lW, lH, offsetRow + _*2, gridMaxCol - lW - 1)
        self.layers.debug['action_'.._] = actionIndexLabel
    end
end

function Level1:updateDebugLayer()
    local text = 'player: nil'
    if self.player then
        text = 'player:'..self.player.id
    end
    self.layers.debug.playerLabel:setText(text)

    text = 'no. actions: 0'
    if self.player and self.player.actionController then
        text = 'no. actions: '..#self.player.actionController.actions
    end
    self.layers.debug.actionsLabel:setText(text)
    
    text = 'action index: 0'
    if self.player and self.player.actionController then
        text = 'action index: '..self.player.actionController.actionIndex
    end
    self.layers.debug.actionIndexLabel:setText(text)

    for _, action in ipairs(self.actionList) do
        text = 'action_'.._..' executed: '..tostring(action.executed)
        local l = self.layers.debug['action_'.._]
        if l then  
            l:setText(text)
        else
            local actionIndexLabel = Luis.createElement('debug', 'Label', text, 10, 2, 16 + _*2, 29)
            self.layers.debug['action_'.._] = actionIndexLabel
        end
    end
end

function Level1:createDefineActionsLayer(gridMaxRow)
    -- Layer
    Luis.newLayer('defineActions')

    -- Commands
    local speed = 100
    local baseActions = {
        actMoveU = function(delay)
            return Action(
                function(dt, e)
                    e.body.acceleration = Vector(0, -1) * speed * dt
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
    Luis.createElement('defineActions', 'DropDown', baseActionsList, 1, ddW, ddH,
        function(val) selectedAction = val end, offsetRow, offsetCol, 4)
    offsetCol = offsetCol + ddW + 1

    -- Slider
    local selectedDelay = 1
    local sW, sH, lw = 12, 2, 3
    local l_delay = Luis.createElement('defineActions', 'Label', '1', lw, sH, offsetRow, offsetCol + sW + 1)
    Luis.createElement('defineActions', 'Slider', 0, 5, 1, sW, sH, function(val)
            val = Utils:round(val, 2)
            selectedDelay = val
            l_delay:setText(selectedDelay)
            print(selectedDelay)
        end,
        offsetRow, offsetCol)
    offsetCol = offsetCol + sW + lw + 2


    -- Button
    local bW, bH = 8, 2
    Luis.createElement("defineActions", "Button", 'Add Action', bW, bH,
        function()
            local actionFabric = baseActions[selectedAction]
            local action = actionFabric(selectedDelay)
            table.insert(self.actionList, action)

            local text = action.label .. ' after ' .. action.delay .. 's'
            local l = Luis.newLabel(text, 10, 1, 1, 1)
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
    local b_confirm = Luis.createElement("defineActions", "Button", 'Confirm Actions', cW, 2,
        function()
            self:setupPlayer(self.actionList)
            self:createListActionsLayer(gridMaxRow)
            self:ShowListActions()
        end, nil, 1, 1)
    container:addChild(b_confirm)

    actionListContainer = Luis.createElement('defineActions', 'FlexContainer', container)
    container:setDecorator("GlowDecorator", { 1, 0.5, 0, 0.1 }, 3)
end

function Level1:createListActionsLayer(gridMaxRow)
    print('test', gridMaxRow)
    -- Layer
    Luis.removeLayer('listActions')
    Luis.newLayer('listActions')

    self.layers.listActions = {}

    local labels = {}

    local offsetRow = 1
    -- Action list
    for index, action in ipairs(self.actionList) do
        local text = action.label .. ' after ' .. action.delay .. 's'
        local l = Luis.createElement('listActions', 'Label', text, 10, 1, offsetRow + index, 1)
        table.insert(self.layers.listActions, l)
    end
    -- Reset Button
    Luis.createElement('listActions', 'Button', 'Reset Level', 8, 2, function() self:resetLevel() end, nil, gridMaxRow - 3, 2 )
end

function Level1:updateListActionsLayer()
    for index, action in ipairs(self.actionList) do
        if self.player.actionController.actionIndex == index then
            self.layers.listActions[index]:setDecorator("GlowDecorator", { 1, 0.5, 0, 0.1 }, 3)
        else
            self.layers.listActions[index]:setDecorator(nil)
        end
    end
end

function Level1:resetLevel()
    -- reset action list
    for _, action in ipairs(self.actionList) do
        action.executed = false
    end
    
    -- reset player
    world:unregisterEntity(self.player.id)
    self.player = nil
    print('reset player')
    
    -- self:setupPlayer(self.actionList)

    -- reset other entities

    -- toggle layout
    self:ShowCreateActions()
end

function Level1:setupPlayer(actions)
    if not self.player then
        -- register entities
        self.player = Actor(actions)
        world:registerEntity(self.player)
    end
end

function Level1:ShowCreateActions()
    Luis.enableLayer('defineActions')
    Luis.disableLayer('listActions')
end

function Level1:ShowListActions()
    Luis.disableLayer('defineActions')
    Luis.enableLayer('listActions')
end


return Level1
