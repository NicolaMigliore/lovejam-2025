local Recap = Object:extend()

local pW, pH = 20, 2
local lW, lH = 15, 2

function Recap:new(eventRecap, events)
    self.layerName = 'recap'
    self.containers = {}

    
    local gridCellSize = Luis.getGridSize()
    self.containerCustomTheme = {
        backgroundColor = function() return 1, 1, 1, 1 end,
        borderColor = function() return 1, 1, 1, 1 end,
        borderWidth = 2,
        padding = gridCellSize * 2,
        handleSize = 20,
        handleColor = function() return 1, 1, .4, 1 end,
        cornerRadius = 3,
    }

    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- props
    self.eventRecap = eventRecap

    self.eventRecapItems = {}
    self:createLayer()

    self.events = {
        clickContinue = function() end,
    }
    self.events = Lume.merge(self.events, events)
end

function Recap:createLayer()
    Luis.newLayer(self.layerName)

    local cW, cH = 40, 25
    local offsetRow, offsetCol = (self.gridMaxRow / 2 - cH/2), (self.gridMaxCol / 2 - cW/2)
    local borderImage = love.graphics.newImage('assets/ui.png')
    -- local c_recap = Luis.createElement(self.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'recapContainer')
    local c_recap = Luis.createElement(self.layerName, 'FlexContainer', cW, cH, offsetRow, offsetCol, nil, 'recapContainer')
    c_recap:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)
    self.containers.c_recap = c_recap

    -- Recap Events
    lW = cW
    offsetRow, offsetCol = self.gridMaxRow / 2 - pH - 2, self.gridMaxCol / 2 - lW / 2
    for index, evtRecapMsg in ipairs(self.eventRecap) do
        -- local l_floor = Luis.createElement(self.layerName, 'Label', evtRecapMsg, lW, lH, offsetRow + index * 2, offsetCol,
        --     'center')
        local l_recap = Luis.newLabel(evtRecapMsg, lW, lH, offsetRow + index * 2, offsetCol,'center')
        c_recap:addChild(l_recap)

        -- save item
        table.insert(self.eventRecapItems, { label = l_recap, row = offsetRow + index * 2, col = offsetCol })
    end

    -- Continue
    local bW, bH = 20, 3
    offsetRow = self.gridMaxRow - bH
    offsetCol = self.gridMaxCol / 2 - bW / 2
    Luis.createElement(self.layerName, 'Button', 'Continue', bW, bH, function() self.events.clickContinue() end, nil,
        offsetRow,
        offsetCol)
end

function Recap:update(dt, eventRecap)
    -- update props
    self.eventRecap = eventRecap


    -- update computed labels
    self:setRecapLabels()
    for index, evtRecapMsg in ipairs(self.eventRecap) do
        local item = self.eventRecapItems[index]

        -- if item then
            item.label:setText(evtRecapMsg)
        -- end
    end
end

function Recap:setRecapLabels()

    -- clear exceeding eventRecapItems
    if #self.eventRecapItems > #self.eventRecap then
        -- for index = #self.eventRecap + 1, #self.eventRecapItems do
        for index, recapItem in ipairs(self.eventRecapItems) do
            -- local recapItem = self.eventRecapItems[index]
            if index > #self.eventRecap then
                local label = recapItem.label
                Luis.removeElement(self.layerName, label)
                table.remove(self.eventRecapItems, index)
            end
        end
    end

    local offsetRow, offsetCol = self.gridMaxRow / 2 - pH - 2, self.gridMaxCol / 2 - lW / 2
    for index = 1, #self.eventRecap, 1 do
        local item = self.eventRecapItems[index]
        local evt = self.eventRecap[index]
        local text = 'Floor ' .. index
        if evt then
            text = evt
        end

        -- create or update label
        if not item then
            local l_recap = Luis.newLabel(evtRecapMsg, lW, lH, offsetRow + index * 2, offsetCol,'center')
            self.containers.c_recap:addChild(l_recap)
            -- save item
            table.insert(self.eventRecapItems, { label = l_recap, row = offsetRow + index * 2, col = offsetCol })
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
