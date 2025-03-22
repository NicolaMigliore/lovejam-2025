local Dungeon = Object:extend()

local pW, pH = 20, 2
local lW, lH = 15, 1

function Dungeon:new(dungeonEvents, questPercentage, targetFloor, currentFloor, events)
    self.layerName = 'dungeon'

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- props
    self.dungeonEvents = dungeonEvents
    self.questPercentage = questPercentage
    self.targetFloor = targetFloor
    self.currentFloor = currentFloor

    self.floorItems = {}
    self.questPercentageItem = nil
    self:createLayer()

end

function Dungeon:createLayer()
    Luis.newLayer(self.layerName)


    -- ProgressBar
    local offsetRow, offsetCol = self.gridMaxRow / 2, self.gridMaxCol / 2 - pW / 2
    local p_quest = Luis.createElement(self.layerName, 'ProgressBar', self.questPercentage, pW, pH, offsetRow, offsetCol)
    self.questPercentageItem = p_quest

    -- Dungeon Events
    offsetRow, offsetCol = self.gridMaxRow / 2 - pH - 2, self.gridMaxCol / 2 - lW / 2
    for index = 1, self.targetFloor, 1 do
        -- floor
        local text = 'Floor ' .. index
        local evt = self.dungeonEvents[index]
        if evt then
            text = text .. ' - ' .. evt.label .. ' ' .. evt.modifier
        end
        local l_floor = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow + index * 2, offsetCol, 'center')

        -- save item
        table.insert(self.floorItems, { label = l_floor, row = offsetRow + index * 2, col = offsetCol })
    end
end

function Dungeon:update(dt, dungeonEvents, questPercentage, targetFloor, currentFloor)
    -- update props
    self.dungeonEvents = dungeonEvents
    self.questPercentage = questPercentage
    self.targetFloor = targetFloor
    self.currentFloor = currentFloor

    -- update progress bar
    self.questPercentageItem:setValue(self.questPercentage)

    -- update computed labels
    self:setFloorLabels()
    for index = 1, self.targetFloor do
        local item = self.floorItems[index]

        local currentIndex = self.currentFloor

        -- set visibility
        local show = index <= currentIndex
        item.label:setShow(show)

        -- set decorator
        item.label:setDecorator(nil)
        if currentIndex == index then
            item.label:setDecorator("GlowDecorator", { 1, 0.5, 0, 0.1 }, 3)
        end
        -- set position
        local yDelta = self.targetFloor * 2
        local row, col = item.row, item.col
        row = row - self.questPercentage * yDelta
        item.label:setPosition(row, col)
    end
end

function Dungeon:setFloorLabels()

    -- clear exceeding floorItems
    if #self.floorItems > self.targetFloor then
        for index, floorItem in ipairs(self.floorItems) do
            if index > self.targetFloor then
                local label = floorItem.label
                Luis.removeElement(self.layerName, label)
                table.remove(self.floorItems, index)
            end
        end
    end
    
    local offsetRow, offsetCol = self.gridMaxRow / 2 - pH - 2, self.gridMaxCol / 2 - lW / 2
    for index = 1, self.targetFloor, 1 do
        local item = self.floorItems[index]
        local evt = self.dungeonEvents[index]
        local row = offsetRow + index * 2
        local text = 'Floor ' .. index
        if evt then
            text = text .. ' - ' .. evt.label .. ' ' .. evt.modifier
        end

        -- create or update label
        if not item then
            item = Luis.createElement(self.layerName, 'Label', text, lW, lH, row, offsetCol, 'center')
            -- save item
            table.insert(self.floorItems, { label = item, row = row, col = offsetCol })
        else
            item.label:setText(text)
        end
    end
end

function Dungeon:showLayer()
    Luis.enableLayer(self.layerName)
end

function Dungeon:hideLayer()
    Luis.disableLayer(self.layerName)
end

return Dungeon
