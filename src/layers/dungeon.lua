local Dungeon = Object:extend()

local pW, pH = 40, 2
local lW, lH = 15, 1
local borderImage = love.graphics.newImage('assets/ui.png')

function Dungeon:new(dungeonEvents, questPercentage, targetFloor, currentFloor, party, events)
    self.layerName = 'dungeon'

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- props
    self.dungeonEvents = dungeonEvents
    self.questPercentage = questPercentage
    self.targetFloor = targetFloor
    self.currentFloor = currentFloor
    self.party = party

    self.floorItems = {}
    self.partyItems = {}
    self.questPercentageItem = nil
    self:createLayer()

end

function Dungeon:createLayer()
    Luis.newLayer(self.layerName)


    -- ProgressBar
    local offsetRow, offsetCol = self.gridMaxRow / 2 + pH + 2, self.gridMaxCol / 2 - pW / 2
    local p_quest = Luis.createElement(self.layerName, 'ProgressBar', self.questPercentage, pW, pH, offsetRow, offsetCol)
    self.questPercentageItem = p_quest

    -- Party icons
    local maxPartySize = 4
    for index = 1, maxPartySize, 1 do
        local offsetCol = index - 2
        table.insert(self.partyItems, { ia_avatar = nil, offsetCol = offsetCol})
    end

    -- Dungeon Events
    offsetRow, offsetCol = self.gridMaxRow / 2 - pH - 2, self.gridMaxCol / 2 - lW / 2
    for index = 1, self.targetFloor, 1 do
        -- floor
        local text = 'Floor ' .. index
        local evt = self.dungeonEvents[index]
        if evt then
            text = text .. ' - ' .. evt.label .. ' ' .. evt.modifier
        end
        local l_floor = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow + index * 2, offsetCol, 'center', GAME_SETTINGS.labelTheme)
        l_floor:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)

        -- save item
        table.insert(self.floorItems, { label = l_floor, row = offsetRow + index * 2, col = offsetCol })
    end
end

function Dungeon:update(dt, dungeonEvents, questPercentage, targetFloor, currentFloor, party)
    -- update props
    self.dungeonEvents = dungeonEvents
    self.questPercentage = questPercentage
    self.targetFloor = targetFloor
    self.currentFloor = currentFloor
    self.party = party

    -- update progress bar
    self.questPercentageItem:setValue(self.questPercentage)

    -- update Party icons
    local maxPartySize = 4
    local row, col = self.gridMaxRow / 2 + pH , self.gridMaxCol / 2 - pW / 2
    for index = 1, maxPartySize, 1 do
        local member = self.party[index]
        local item = self.partyItems[index]
        local baseCol = self.gridMaxCol / 2 - pW / 2
        col = baseCol + item.offsetCol + (pW-1) * self.questPercentage

        if item then
            if member then
                    local animation = member.animationController.animations.idle
                if item.ia_avatar then
                    item.ia_avatar:setAnimation(animation)
                    item.ia_avatar:setPosition(row, col)
                else
                    -- create missing icon
                    local ia_avatar = Luis.createElement(self.layerName, 'IconAnimated', member.animationController.image, animation, 2, row, col, nil)
                    item.ia_avatar = ia_avatar
                end
            else
                if item.ia_avatar then
                    Luis.removeElement(self.layerName, item.ia_avatar)
                    item.ia_avatar = nil
                end
            end
        end
    end

    -- update computed labels
    self:setFloorLabels()
    for index = 1, self.targetFloor do
        local item = self.floorItems[index]

        local currentIndex = self.currentFloor

        -- set visibility
        local show = index <= currentIndex
        item.label:setShow(show)

        -- set decorator
        -- item.label:setDecorator(nil)
        -- if currentIndex == index then
        --     item.label:setDecorator("GlowDecorator", { 1, 0.5, 0, 0.1 }, 3)
        -- end
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
            item = Luis.createElement(self.layerName, 'Label', text, lW, lH, row, offsetCol, 'center', GAME_SETTINGS.labelTheme)
            item:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)
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
