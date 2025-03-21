local Plan = Object:extend()

local IconsImage = love.graphics.newImage('assets/icons.png')
IconsImage:setFilter('nearest', 'nearest')
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
        clickPotionsMinus = function() end,
        clickPotionsPlus = function() end,
        clickConfirm = function() end,
    }
    self.events = Lume.merge(self.events, events)
end

function Plan:createLayer()
    Luis.newLayer(self.layerName)

    local offsetRow, offsetCol = 2, 2
    local cW, cH = 11, 13
    local borderImage = love.graphics.newImage('assets/ui.png')
    local c_party = Luis.createElement(self.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'partyContainer')
    c_party:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)
    offsetCol = offsetCol


    local lW, lH = 7, 1
    local iS = 2
    -- Party Items
    for index = 1, self.maxPartySize, 1 do
        local member = self.party[index]

        offsetRow = (index * 3) - 1
        -- Name
        local text = '...'
        if member then
            text = member.race .. ' ' .. member.class
        end
        local l_name = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
        c_party:addChild(l_name, offsetRow, offsetCol)
        
        -- Avatar
        if member then
            local animation = member.animationController.animations.idle
            local ia_avatar = Luis.createElement(self.layerName, 'IconAnimated', member.animationController.image, animation, iS, offsetRow, offsetCol + lW, nil)
            c_party:addChild(ia_avatar, offsetRow, offsetCol + lW)
        end
        offsetRow = offsetRow + lH

        -- Stats
        text = 'HP: ' .. ' ' .. '   DMG: '
        if member then
            text = 'HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg
        end
        local l_stats = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
        c_party:addChild(l_stats, offsetRow, offsetCol)
        offsetRow = offsetRow + lH
        -- Equipment

        -- save item
        table.insert(self.partyItems, { l_name = l_name, l_stats = l_stats })
    end

    -- Inventory Items
    offsetRow = 2
    lW, lH = 4, 2

    cW, cH = 14, 13
    offsetCol = self.gridMaxCol -8 - lW - iS
    local c_inventory = Luis.createElement(self.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'inventoryContainer')
    c_inventory:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)

    -- Gold
    offsetCol = 5
    local gold_quad = love.graphics.newQuad(16, 0, 16, 16, IconsImage:getWidth(), IconsImage:getHeight())
    local i_gold = Luis.createElement(self.layerName, 'Icon', IconsImage, iS, offsetRow, offsetCol, nil, gold_quad)
    c_inventory:addChild(i_gold, offsetRow, offsetCol)

    offsetCol = offsetCol + iS + 1
    local text = 'gold: ' .. tostring(self.inventory.gold)
    local l_gold = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
    c_inventory:addChild(l_gold, offsetRow, offsetCol)
    offsetRow = offsetRow + 3

    -- Food
    local bW, bH = 2, 2
    offsetCol = 2
    local b_food_minus = Luis.createElement(self.layerName, 'Button', '-', bW, bH,
        function() self.events.clickFoodMinus() end,
        nil, offsetRow, offsetCol)
    c_inventory:addChild(b_food_minus, offsetRow, offsetCol)

    offsetCol = offsetCol + bW + 1
    local food_quad = love.graphics.newQuad(0, 0, 16, 16, IconsImage:getWidth(), IconsImage:getHeight())
    local i_food = Luis.createElement(self.layerName, 'Icon', IconsImage, iS, offsetRow, offsetCol, nil, food_quad)
    c_inventory:addChild(i_food, offsetRow, offsetCol)

    offsetCol = offsetCol + iS
    local text = 'food: ' .. tostring(self.inventory.food)
    local l_food = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'center')
    c_inventory:addChild(l_food, offsetRow, offsetCol)

    offsetCol = offsetCol + lW + 1
    local b_food_plus = Luis.createElement(self.layerName, 'Button', '+', bW, bH,
        function() self.events.clickFoodPlus() end, nil,
        offsetRow, offsetCol)
    c_inventory:addChild(b_food_plus, offsetRow, offsetCol)
    offsetRow = offsetRow + 3

    -- Potions
    local bW, bH = 2, 2
    offsetCol = 2
    local b_potions_minus = Luis.createElement(self.layerName, 'Button', '-', bW, bH,
        function() self.events.clickPotionsMinus() end,
        nil, offsetRow, offsetCol)
    c_inventory:addChild(b_potions_minus, offsetRow, offsetCol)

    offsetCol = offsetCol + bW + 1
    local potions_quad = love.graphics.newQuad(48, 0, 16, 16, IconsImage:getWidth(), IconsImage:getHeight())
    local i_potions = Luis.createElement(self.layerName, 'Icon', IconsImage, iS, offsetRow, offsetCol, nil, potions_quad)
    c_inventory:addChild(i_potions, offsetRow, offsetCol)

    offsetCol = offsetCol + iS
    local text = 'Potions: ' .. tostring(self.inventory.potions)
    local l_potions = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'center')
    c_inventory:addChild(l_potions, offsetRow, offsetCol)

    offsetCol = offsetCol + lW + 1
    local b_food_plus = Luis.createElement(self.layerName, 'Button', '+', bW, bH,
        function() self.events.clickPotionsPlus() end, nil,
        offsetRow, offsetCol)
    c_inventory:addChild(b_food_plus, offsetRow, offsetCol)
    offsetRow = offsetRow + 3

    -- Target Floor
    offsetCol = 2
    local b_targetFloor_minus = Luis.createElement(self.layerName, 'Button', '-', bW, bH,
        function() self.events.clickFloorMinus() end,
        nil, offsetRow, offsetCol)
    c_inventory:addChild(b_targetFloor_minus, offsetRow, offsetCol)

        offsetCol = offsetCol + bW + 1
    local floor_quad = love.graphics.newQuad(32, 0, 16, 16, IconsImage:getWidth(), IconsImage:getHeight())
    local i_floor = Luis.createElement(self.layerName, 'Icon', IconsImage, iS, offsetRow, offsetCol, nil, floor_quad)
    c_inventory:addChild(i_floor, offsetRow, offsetCol)

    offsetCol = offsetCol + iS
    local text = 'Target Flor: ' .. tostring(self.targetFloor)
    local l_targetFloor = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol)
    c_inventory:addChild(l_targetFloor, offsetRow, offsetCol)

    offsetCol = offsetCol + lW + 1
    local b_targetFloor_plus = Luis.createElement(self.layerName, 'Button', '+', bW, bH,
        function() self.events.clickFloorPlus() end, nil,
        offsetRow, offsetCol)
    c_inventory:addChild(b_targetFloor_plus, offsetRow, offsetCol)
    offsetRow = offsetRow + 2

    -- save
    self.inventoryItems.gold = { label = l_gold }
    self.inventoryItems.food = { b_minus = b_food_minus, label = l_food, b_plus = b_food_plus }
    self.inventoryItems.potions = { b_minus = b_food_minus, label = l_potions, b_plus = b_food_plus }
    self.inventoryItems.targetFloor = { b_minus = b_targetFloor_minus, label = l_targetFloor, b_plus = b_targetFloor_plus }

    -- Confirm
    bW, bH = 20, 3
    offsetRow = self.gridMaxRow - bH
    offsetCol = self.gridMaxCol / 2 - bW / 2
    Luis.createElement(self.layerName, 'Button', 'Confirm', bW, bH, function() self.events.clickConfirm() end, nil,
        offsetRow,
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
        if item then
            if member then
                item.l_name:setText(member.race .. ' ' .. member.class)
                item.l_stats:setText('HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg)
            else
                item.l_name:setText('...')
                item.l_stats:setText('HP: ' .. ' ' .. '   DMG: ' .. ' ')
            end
        end
    end

    -- update inventory labels
    self.inventoryItems.gold.label:setText('Gold: ' .. tostring(self.inventory.gold))
    self.inventoryItems.food.label:setText('Food: ' .. tostring(self.inventory.food))
    self.inventoryItems.potions.label:setText('Potions: ' .. tostring(self.inventory.potions))
    self.inventoryItems.targetFloor.label:setText('Floor: ' .. tostring(self.targetFloor))
end

function Plan:showLayer()
    Luis.enableLayer(self.layerName)
end

function Plan:hideLayer()
    Luis.disableLayer(self.layerName)
end

return Plan
