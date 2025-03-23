local Recap = Object:extend()

local cW, cH = 40, 25
local pW, pH = 20, 2
local lW, lH = 15, 2

function Recap:new(eventRecap, isGameOver, events)
    self.layerName = 'recap'
    self.containers = {}


    local gridCellSize = Luis.getGridSize()
    self.containerCustomTheme = {
        backgroundColor = function() return 1, 1, 1, 1 end,
        borderColor = function() return 1, 1, 1, 1 end,
        borderWidth = 2,
        padding = gridCellSize * .005,
        handleSize = 20,
        handleColor = function() return 1, 1, .4, 1 end,
        cornerRadius = 3,
    }

    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- props
    self.eventRecap = eventRecap
    self.isGameOver = isGameOver

    self.eventRecapItems = {}
    self.buttonItems = {}
    self:createLayer()

    self.events = {
        clickContinue = function() end,
        clickExit = function() end,
    }
    self.events = Lume.merge(self.events, events)
end

function Recap:createLayer()
    Luis.newLayer(self.layerName)

    local offsetRow, offsetCol = (self.gridMaxRow / 2 - cH / 2), (self.gridMaxCol / 2 - cW / 2)
    local borderImage = love.graphics.newImage('assets/scroll.png')
    local c_recap = Luis.createElement(self.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil,
        'recapContainer')
    c_recap:setDecorator("Slice9Decorator", borderImage, 48, 24, 28, 36)
    self.containers.c_recap = c_recap

    -- Recap Events
    lW = cW
    offsetRow, offsetCol = self.gridMaxRow / 2 - pH - 2, self.gridMaxCol / 2 - lW / 2
    for index, evtRecapMsg in ipairs(self.eventRecap) do
        -- local l_floor = Luis.createElement(self.layerName, 'Label', evtRecapMsg, lW, lH, offsetRow + index * 2, offsetCol,
        --     'center')
        local l_recap = Luis.newLabel(evtRecapMsg, lW, lH, offsetRow + index, offsetCol, 'center',
            GAME_SETTINGS.labelTheme)
        c_recap:addChild(l_recap, offsetRow + index, offsetCol)

        -- save item
        table.insert(self.eventRecapItems, { label = l_recap, row = offsetRow + index, col = offsetCol })
    end

    -- Continue
    local bW, bH = 20, 3
    offsetRow = self.gridMaxRow - bH
    offsetCol = self.gridMaxCol / 2 - bW / 2
    local b_continue = Luis.createElement(self.layerName, 'Button', 'Continue', bW, bH,
        function() self.events.clickContinue() end, nil,
        offsetRow,
        offsetCol)
    self.buttonItems.b_continue = b_continue
end

function Recap:update(dt, eventRecap, isGameOver)
    -- update props
    self.eventRecap = eventRecap
    self.isGameOver = isGameOver


    -- update computed labels
    self:setRecapLabels()
    for index, evtRecapMsg in ipairs(self.eventRecap) do
        local item = self.eventRecapItems[index]
        item.label:setText(evtRecapMsg)
    end

    -- Show game over message
    if self.isGameOver then
        -- remove continue button
        if self.buttonItems.b_continue then
            Luis.removeElement(self.layerName, self.buttonItems.b_continue)
            self.buttonItems.b_continue = nil
        end
        -- add exit button
        if not self.buttonItems.b_exit then
            local bW, bH = 20, 3
            local offsetRow = self.gridMaxRow - bH
            local offsetCol = self.gridMaxCol / 2 - bW / 2
            local b_exit = Luis.createElement(self.layerName, 'Button', 'Back to Title', bW, bH,
                function() self.events.clickExit() end, nil, offsetRow, offsetCol)
            self.buttonItems.b_exit = b_exit
        end
    end
end

function Recap:setRecapLabels()
    -- clear exceeding eventRecapItems
    if #self.eventRecapItems > #self.eventRecap then
        for index, recapItem in ipairs(self.eventRecapItems) do
            if index > #self.eventRecap then
                local label = recapItem.label
                self.containers.c_recap:removeChild(label)
                table.remove(self.eventRecapItems, index)
            end
        end
    end

    local offsetRow, offsetCol = .5, cW / 2 - lW / 2
    for index = 1, #self.eventRecap, 1 do
        local item = self.eventRecapItems[index]
        local evt = self.eventRecap[index]
        local text = 'Floor ' .. index
        if evt then
            text = evt
        end

        -- create or update label
        if not item then
            local row = offsetRow + index * lH
            local l_recap = Luis.newLabel(evtRecapMsg, lW, lH, row, offsetCol, 'center', GAME_SETTINGS.labelTheme)
            self.containers.c_recap:addChild(l_recap, offsetRow + index, offsetCol)
            -- save item
            table.insert(self.eventRecapItems, { label = l_recap, row = row, col = offsetCol })
        else
            item.label:setText(text)
        end
    end
end

function Recap:showLayer()
    Luis.enableLayer(self.layerName)
end

function Recap:hideLayer()
    Luis.disableLayer(self.layerName)
end

return Recap
