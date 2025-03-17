local Plan = Object:extend()

function Plan:new(party, inventory, targetFloor, events)
    self.layerName = 'plan'

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- props
    self.party = party
    self.inventory = inventory
    self.targetFloor = targetFloor

    self.maxPartySize = 4
    self.partyItems = {}
    self.inventoryItems = {}
    self:createLayer()

    self.events = {
        clickFoodMinus = function() end,
        clickFoodPlus = function() end,
        clickFloorMinus = function() end,
        clickFloorPlus = function() end,
        clickConfirm = function() end,
    }
    self.events = Lume.merge(self.events, events)
end

function Plan:createLayer()
    Luis.newLayer(self.layerName)

    local offsetRow, offsetCol = 0, 2
    local lW, lH = 10, 1
    -- Party Items
    -- for index, member in ipairs(self.party) do
    for index = 1, self.maxPartySize, 1 do
        local member = self.party[index]
        
        offsetRow = index * 3
        -- Name
        local text = '...'
        if member then
            text = member.race .. ' ' .. member.class
        end
        local l_name = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
        offsetRow = offsetRow + lH

        -- Stats
        text = 'HP: ' .. ' ' .. '   DMG: '
        if member then
            text = 'HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg
        end
        local l_stats = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
        offsetRow = offsetRow + lH
        -- Equipment

        -- save item
        table.insert(self.partyItems, { l_name = l_name, l_stats = l_stats })
    end

    -- Inventory Items
    offsetRow = 3
    lW = 4

    -- Gold
    offsetCol = self.gridMaxCol - 2 - lW
    local text = 'gold: ' .. tostring(self.inventory.gold)
    local l_gold = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
    offsetRow = offsetRow + 2

    -- Food
    local bW, bH = 1, 1
    offsetCol = self.gridMaxCol - 3 - lW - bW
    local b_food_minus = Luis.createElement(self.layerName, 'Button', '-', bW, bH, function() self.events.clickFoodMinus() end,
        nil, offsetRow, offsetCol)

    offsetCol = self.gridMaxCol - 2 - lW
    local text = 'food: ' .. tostring(self.inventory.food)
    local l_food = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)

    offsetCol = self.gridMaxCol - bW
    local b_food_plus = Luis.createElement(self.layerName, 'Button', '+', bW, bH, function() self.events.clickFoodPlus() end, nil,
        offsetRow, offsetCol)
    offsetRow = offsetRow + 2

    -- Target Floor
    offsetCol = self.gridMaxCol - 3 - lW - bW
    local b_targetFloor_minus = Luis.createElement(self.layerName, 'Button', '-', bW, bH, function() self.events.clickFloorMinus() end,
        nil, offsetRow, offsetCol)

    offsetCol = self.gridMaxCol - 2 - lW
    local text = 'Target Flor: ' .. tostring(self.targetFloor)
    local l_targetFloor = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)

    offsetCol = self.gridMaxCol - bW
    local b_targetFloor_plus = Luis.createElement(self.layerName, 'Button', '+', bW, bH, function() self.events.clickFloorPlus() end, nil,
        offsetRow, offsetCol)
    offsetRow = offsetRow + 2

    -- save
    self.inventoryItems.gold = { label = l_gold }
    self.inventoryItems.food = { b_minus = b_food_minus, label = l_food, b_plus = b_food_plus }
    self.inventoryItems.targetFloor = { b_minus = b_targetFloor_minus, label = l_targetFloor, b_plus = b_targetFloor_plus }

    -- Confirm
    bW, bH = 20, 3
    offsetRow = self.gridMaxRow - bH
    offsetCol = self.gridMaxCol / 2 - bW / 2
    Luis.createElement(self.layerName, 'Button', 'Confirm', bW, bH, function() self.events.clickConfirm() end, nil, offsetRow,
    offsetCol)
end

function Plan:update(dt, party, inventory, targetFloor)
    -- update props
    self.party = party
    self.inventory = inventory
    self.targetFloor = targetFloor

    -- update computed labels
    -- for index, member in ipairs(self.party) do
    --     local item = self.partyItems[index]
    --     item.l_name:setText(member.race .. ' ' .. member.class)
    --     item.l_stats:setText('HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg)
    -- end
    for index = 1, self.maxPartySize, 1 do
        local member = self.party[index]
        local item = self.partyItems[index]
        if member then
            item.l_name:setText(member.race .. ' ' .. member.class)
            item.l_stats:setText('HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg)
        else
            item.l_name:setText('...')
            item.l_stats:setText('HP: ' .. ' ' .. '   DMG: ' .. ' ')
        end
    end

    -- update inventory labels
    self.inventoryItems.gold.label:setText('gold: ' .. tostring(self.inventory.gold))
    self.inventoryItems.food.label:setText('food: ' .. tostring(self.inventory.food))
    self.inventoryItems.targetFloor.label:setText('floor: ' .. tostring(self.targetFloor))
end

function Plan:showLayer()
    Luis.enableLayer(self.layerName)
end
function Plan:hideLayer()
    Luis.disableLayer(self.layerName)
end

return Plan
