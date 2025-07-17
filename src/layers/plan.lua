local Plan = Object:extend()

local IconsImage = love.graphics.newImage('assets/icons.png')
IconsImage:setFilter('nearest', 'nearest')
local partyClasses = { 'rogue', 'archer', 'mage', 'warrior' }
local partyClassLabels = { 'rogue (F:1, C:4)', 'archer (F:3, C:6)', 'mage (F:4, C:8)', 'warrior (F:5, C:10)'}

function Plan:new(party, inventory, targetFloor, days, events)
    self.layerName = 'plan'
    self.containers = {}

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    self.gridMaxCol, self.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- props
    self.party = party
    self.inventory = inventory
    self.targetFloor = targetFloor
    self.days = days

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
        nextPartyMemberChange = function(newClass) end,
        clickAddPartyMember = function() end,
        clickRemovePartyMember = function() end,
    }
    self.events = Lume.merge(self.events, events)

end

function Plan:createLayer()
    Luis.newLayer(self.layerName)

    local offsetRow, offsetCol = 2, 2
    local cW, cH = 13, 19
    local borderImage = love.graphics.newImage('assets/ui.png')
    local c_party = Luis.createElement(self.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'partyContainer')
    c_party:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)
    self.containers.c_party = c_party
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
            -- text = member.race .. ' ' .. member.class
            text = member.class .. ' ' .. member.name
        end
        local l_name = Luis.newLabel(text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
        c_party:addChild(l_name, offsetRow, offsetCol)

        -- Remove button
        local b_remove = Luis.newButton('-', 2, 2, function() self.events.clickRemovePartyMember(index) end, nil, offsetRow, 11)
        c_party:addChild(b_remove, offsetRow, 11)
        offsetRow = offsetRow + lH

        -- Stats
        text = 'HP: ' .. ' ' .. '   DMG: '
        if member then
            text = 'HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg
        end
        local l_stats = Luis.newLabel(text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
        c_party:addChild(l_stats, offsetRow, offsetCol)
        offsetRow = offsetRow + lH
        -- Equipment

        -- save item
        table.insert(self.partyItems, { l_name = l_name, l_stats = l_stats, ia_avatar = nil, b_remove = b_remove })
    end

    -- Add party member
    offsetCol = 2
    offsetRow = offsetRow + 1
    local ddW, ddH = 11, 2
    local dd_nextClass = Luis.createElement(self.layerName, 'DropDown', partyClassLabels, nil, ddW, ddH, function(val)
        local index = Lume.find(partyClassLabels, val)
        local newClass = partyClasses[index]
        self.events.nextPartyMemberChange(newClass) end
    , offsetRow, offsetCol, 4)
    -- local dd_nextClass = Luis.newDropDown(partyClasses, nil, ddW, ddH,function(val) self.events.nextPartyMemberChange(val) end, offsetRow, offsetCol, 2)
    c_party:addChild(dd_nextClass, offsetRow, offsetCol)

    offsetRow = offsetRow + ddH + 1
    local b_add_member = Luis.createElement(self.layerName, 'Button', 'Add Member', 11, 2, function() self.events.clickAddPartyMember() end, nil, offsetRow, offsetCol)
    c_party:addChild(b_add_member, offsetRow, offsetCol)


    -- Inventory Items
    offsetRow = 2
    lW, lH = 4, 2

    cW, cH = 14, 16
    offsetCol = self.gridMaxCol -8 - lW - iS
    local c_inventory = Luis.createElement(self.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'inventoryContainer')
    c_inventory:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)
    self.containers.c_inventory = c_inventory

    -- Days
    offsetCol = 5
    local days_quad = love.graphics.newQuad(64, 0, 16, 16, IconsImage:getWidth(), IconsImage:getHeight())
    local i_days = Luis.createElement(self.layerName, 'Icon', IconsImage, iS, offsetRow, offsetCol, nil, days_quad)
    c_inventory:addChild(i_days, offsetRow, offsetCol)
    offsetCol = offsetCol + iS
    local text = 'days: ' .. tostring(self.days)
    local l_days = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
    c_inventory:addChild(l_days, offsetRow, offsetCol)
    offsetRow = offsetRow + 3

    -- Gold
    offsetCol = 5
    local gold_quad = love.graphics.newQuad(16, 0, 16, 16, IconsImage:getWidth(), IconsImage:getHeight())
    local i_gold = Luis.createElement(self.layerName, 'Icon', IconsImage, iS, offsetRow, offsetCol, nil, gold_quad)
    c_inventory:addChild(i_gold, offsetRow, offsetCol)

    offsetCol = offsetCol + iS
    local text = 'gold: ' .. tostring(self.inventory.gold)
    local l_gold = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
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
    local l_food = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
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
    local l_potions = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
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
    local l_targetFloor = Luis.createElement(self.layerName, 'Label', text, lW, lH, offsetRow, offsetCol, 'left', GAME_SETTINGS.labelTheme)
    c_inventory:addChild(l_targetFloor, offsetRow, offsetCol)

    offsetCol = offsetCol + lW + 1
    local b_targetFloor_plus = Luis.createElement(self.layerName, 'Button', '+', bW, bH,
        function() self.events.clickFloorPlus() end, nil,
        offsetRow, offsetCol)
    c_inventory:addChild(b_targetFloor_plus, offsetRow, offsetCol)
    offsetRow = offsetRow + 2

    -- save
    self.inventoryItems.days = { label = l_days}
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

function Plan:update(dt, party, inventory, targetFloor, days)
    local oldPartySize = #self.party
    -- update props
    -- self.party = party
    self.inventory = inventory
    self.targetFloor = targetFloor
    self.days = days
    
    -- update computed labels
    for index = 1, self.maxPartySize, 1 do
        local member = self.party[index]
        local item = self.partyItems[index]
        if item then
            if member then
                item.l_name:setText(member.class .. ' ' .. member.name)
                item.l_stats:setText('HP: ' .. Utils:round(member.hp, 2) .. '   DMG: ' .. member.dmg)

                -- create missing icon
                local animation = member:makeAnimation('idle')
                if item.ia_avatar then
                    -- check if party size has changed
                    -- if oldPartySize ~= #self.party then
                        item.ia_avatar:setAnimation(animation)
                    -- end
                else
                    local ia_avatar = Luis.newIconAnimated(member.animationController.image, animation, 2, (index * 3) - 1, 10, nil)
                    self.containers.c_party:addChild(ia_avatar, (index * 3) - 1, 9)
                    item.ia_avatar = ia_avatar
                end
            else
                item.l_name:setText('...')
                item.l_stats:setText('HP: ' .. ' ' .. '   DMG: ' .. ' ')
                if item.ia_avatar then
                    self.containers.c_party:removeChild(item.ia_avatar)
                    item.ia_avatar = nil
                end
            end
        end
    end

    -- update inventory labels
    self.inventoryItems.days.label:setText('Days: ' .. tostring(self.days))
    self.inventoryItems.gold.label:setText('Gold: ' .. tostring(self.inventory.gold))
    self.inventoryItems.food.label:setText('Food: ' .. tostring(self.inventory.food))
    self.inventoryItems.potions.label:setText('Potions: ' .. tostring(self.inventory.potions))
    self.inventoryItems.targetFloor.label:setText('Floor: ' .. tostring(self.targetFloor))
end

function Plan:refreshIcons()
    for index = 1, self.maxPartySize, 1 do
        local member = self.party[index]
        local item = self.partyItems[index]
        if item then
            if member then
                -- create missing icon
                local animation = member:makeAnimation('idle')
                if item.ia_avatar then
                    item.ia_avatar:setAnimation(animation)
                else
                    local ia_avatar = Luis.newIconAnimated(member.animationController.image, animation, 2, (index * 3) - 1, 10, nil)
                    self.containers.c_party:addChild(ia_avatar, (index * 3) - 1, 9)
                    item.ia_avatar = ia_avatar
                end
            else
                if item.ia_avatar then
                    self.containers.c_party:removeChild(item.ia_avatar)
                    item.ia_avatar = nil
                end
            end
        end
    end
end

function Plan:showLayer()
    Luis.enableLayer(self.layerName)
end

function Plan:hideLayer()
    Luis.disableLayer(self.layerName)
end

return Plan
