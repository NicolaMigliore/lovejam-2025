local Event = require 'src.event'

local maxFloor = 10

-- UI constants
local gridMaxCol, gridMaxRow
local pW, pH = 40, 2
local lW, lH = 15, 1

local Dungeon = {
    assets = { images = {}, music = {}, sfx = {} },
    ui = {},
    events = {},
    questPercentage = 0,
    currentFloor = 0,
    targetFloor = 1,
    party = {},
    recap = {},
}

-- Mark: Enter
function Dungeon:enter(previousState, inventory, targetFloor, party)
    -- reset state
    self.inventory = inventory
    self.events = {}
    self.questPercentage = 0
    self.currentFloor = 0
    self.targetFloor = targetFloor
    self.party = party
    self.recap = {}

    -- generate events
    self:generateEvents()

    -- load assets
    self.assets.images.dungeon = love.graphics.newImage('assets/dungeon.png')
    self.assets.images.borderImage = love.graphics.newImage('assets/ui.png')
    self.assets.music.dungeon = love.audio.newSource('assets/music/Lost.mp3', 'stream')
    self.assets.music.drip = love.audio.newSource('assets/sounds/water-drop-night-horror-effects-304065.mp3', 'static')
    self.assets.sfx.death = love.audio.newSource('assets/sounds/34. Effort Grunt (Male).wav', 'static')

    -- play music
    if GAME_SETTINGS.playMusic then
        self.assets.music.dungeon:play()
        self.assets.music.drip:play()
    end

    self:createUI()

    -- start quest progression
    Flux.to(self, 5, { questPercentage = 1 }):delay(.5)
end

-- Mark: Update
function Dungeon:update(dt)
    -- transition to recap
    if self.questPercentage == 1 then
        return GameState.switch(GAME_STATES.recap, self.inventory, self.targetFloor, self.party, self.recap, self.assets.music)
    end

    -- update ui
    self:updateUI(dt)

    -- play music
    if GAME_SETTINGS.playMusic and not self.assets.music.dungeon:isPlaying() then
        self.assets.music.dungeon:play()
    end

    -- run floor
    local currentIndex = math.floor(self.targetFloor * self.questPercentage) + 1
    local canRunNextFloor = currentIndex > self.currentFloor and currentIndex <= self.targetFloor and #self.party > 0
    if canRunNextFloor then
        self:runNextFloor(currentIndex)
        -- consume food
        self:consumeFood(currentIndex)
        -- consume potions
        self:consumePotion(currentIndex)

        self.currentFloor = currentIndex
    end
end

-- Mark: Draw
function Dungeon:draw()
    love.graphics.setColor(1, 1, 1, 1)

    -- draw environment
    local img = self.assets.images.dungeon
    local imgW, imgH = img:getWidth(), img:getHeight()
    local scaleX, scaleY = GAME_SETTINGS.baseWidth / imgW, GAME_SETTINGS.baseHeight / imgH
    love.graphics.draw(img, 0, 0, 0, scaleX, scaleY)

    -- draw ui
    Luis.draw()
end

-- Mark: Leave
function Dungeon:leave()
    Luis.removeLayer('dungeon')

    -- self.assets.music.dungeon:stop()
    -- self.assets.music.drip:stop()
end

function Dungeon:keypressed(key, code, isRepeat)
    if key == 'escape' then
        love.event.quit(0)
    end
end

-- Mark:CreateUI
function Dungeon:createUI()
    local layerName = 'dungeon'
    Luis.newLayer(layerName)
    self.ui[layerName] = {}

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    gridMaxCol, gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- ProgressBar
    local offsetRow, offsetCol = gridMaxRow / 2 + pH + 2, gridMaxCol / 2 - pW / 2
    local p_quest = Luis.createElement(layerName, 'ProgressBar', self.questPercentage, pW, pH, offsetRow, offsetCol)
    self.ui[layerName].questPercentageItem = p_quest

    -- Party icons
    self.ui[layerName].partyItems = {}
    local maxPartySize = 4
    for index = 1, maxPartySize, 1 do
        local offsetCol = index - 2
        table.insert(self.ui[layerName].partyItems, { ia_avatar = nil, offsetCol = offsetCol })
    end

    -- Dungeon Events
    self.ui[layerName].floorItems = {}
    local lW, lH = 15, 1

    offsetRow, offsetCol = gridMaxRow / 2 + pH - 4, gridMaxCol / 2 - lW / 2
    for index = 1, self.targetFloor, 1 do
        -- floor
        local text = 'Floor ' .. index
        local evt = self.events[index]
        if evt then
            text = text .. ' - ' .. evt.label .. ' ' .. evt.modifier
        end
        local l_floor = Luis.createElement(layerName, 'Label', text, lW, lH, offsetRow + index * 2, offsetCol, 'center',
            GAME_SETTINGS.labelTheme)
        -- local l_floor = Luis.newLabel(text, lW, lH, offsetRow + index * 2, offsetCol, 'center', GAME_SETTINGS.labelTheme)
        l_floor:setDecorator("Slice9Decorator", self.assets.images.borderImage, 6, 6, 6, 6)

        -- save item
        table.insert(self.ui[layerName].floorItems, { label = l_floor, row = offsetRow + index * 2, col = offsetCol })
    end

    Luis.enableLayer(layerName)
end

-- Mark: UpdateUI
function Dungeon:updateUI(dt)
    -- update progress bar
    self.ui.dungeon.questPercentageItem:setValue(self.questPercentage)

    -- update Party icons
    local maxPartySize = 4
    local row, col = gridMaxRow / 2 + pH, gridMaxCol / 2 - pW / 2
    for index = 1, maxPartySize, 1 do
        local member = self.party[index]
        local item = self.ui.dungeon.partyItems[index]
        local baseCol = gridMaxCol / 2 - pW / 2
        col = baseCol + item.offsetCol + (pW - 1) * self.questPercentage

        if item then
            if member then
                print('member', member.class)
                local animation = member.animationController.animations.idle
                if item.ia_avatar then
                    item.ia_avatar:setAnimation(animation)
                    item.ia_avatar:setPosition(row, col)
                else
                    -- create missing icon
                    local ia_avatar = Luis.createElement('dungeon', 'IconAnimated', member.animationController.image,
                        animation, 2, row, col, nil)
                    item.ia_avatar = ia_avatar
                end
            else
                if item.ia_avatar then
                    Luis.removeElement('dungeon', item.ia_avatar)
                    item.ia_avatar = nil
                end
            end
        end
    end

    -- update computed labels
    self:setFloorLabels()
    for index = 1, self.targetFloor do
        local item = self.ui.dungeon.floorItems[index]
        local currentIndex = self.currentFloor

        -- set visibility
        local show = index <= currentIndex
        item.label:setShow(show)

        -- set position
        local yDelta = self.targetFloor * 2
        local row, col = item.row, item.col
        row = row - self.questPercentage * yDelta
        item.label:setPosition(row, col)
    end
end

function Dungeon:setFloorLabels()
    -- clear exceeding floorItems
    if #self.ui.dungeon.floorItems > self.targetFloor then
        for index, floorItem in ipairs(self.floorItems) do
            if index > self.targetFloor then
                local label = floorItem.label
                Luis.removeElement('dungeon', label)
                table.remove(self.ui.dungeon, index)
            end
        end
    end

    local offsetRow, offsetCol = gridMaxRow / 2 - pH - 2, gridMaxCol / 2 - lW / 2
    for index = 1, self.targetFloor, 1 do
        local item = self.ui.dungeon.floorItems[index]
        local evt = self.events[index]
        local row = offsetRow + index * 2
        local text = 'Floor ' .. index
        if evt then
            text = text .. ' - ' .. evt.label .. ' ' .. evt.modifier
        end

        -- create or update label
        if not item then
            item = Luis.createElement('dungeon', 'Label', text, lW, lH, row, offsetCol, 'center',
                GAME_SETTINGS.labelTheme)
            item:setDecorator("Slice9Decorator", self.assets.images.borderImage, 6, 6, 6, 6)
            -- save item
            table.insert(self.ui.dungeon.floorItems, { label = item, row = row, col = offsetCol })
        else
            item.label:setText(text)
        end
    end
end

-- Mark: Generate events
function Dungeon:generateEvents()
    self.events = {}
    local eventTypes = { 'inventory_loose', 'inventory_gain', 'trap_single', 'trap_all' }
    local inventoryChangeRecap = function(e, floorIndex, partyTarget)
        local evtRecapMsg = 'Floor ' .. floorIndex .. ': ' .. e.label
        if e.modifier > 0 then
            evtRecapMsg = evtRecapMsg .. ' +' .. e.modifier
        else
            evtRecapMsg = evtRecapMsg .. ' ' .. e.modifier
        end
        return evtRecapMsg
    end

    local floorEventWeights = {
        inventory_loose = function(x) return x end,                    -- linear
        inventory_gain = function(x) return 1 - (1 - x) * (1 - x) end, -- easeOutQuad
        trap_single = function(x) return x * x end, -- easeInQuad
        trap_all = function(x) return x * x * x * x * x end, -- easeInQuint
    }

    for floor = 1, self.targetFloor do
        local dungeonPercentage = floor / maxFloor
        local floorModifier = math.max(1, math.floor(floor / 2))
        local choices = {
            inventory_loose = floorEventWeights.inventory_loose(dungeonPercentage) * 2,
            inventory_gain = floorEventWeights.inventory_gain(dungeonPercentage) * 4,
            trap_single = floorEventWeights.trap_single(dungeonPercentage) * 3,
            trap_all = floorEventWeights.trap_all(dungeonPercentage) * 5,
        }
        local evtType = Lume.weightedchoice(choices)

        -- Inventory Loose events
        if evtType == 'inventory_loose' then
            local amount = Utils:easeInOutQuad(dungeonPercentage) * 5 + love.math.random(3)
            amount = math.floor(amount) * -1

            local evtKinds = {
                { code = 'loose_gold', label = 'Lost Gold', targetAttribute = 'gold' },
                { code = 'loose_food', label = 'Lost Food', targetAttribute = 'food' },
            }
            local evtKind = Lume.randomchoice(evtKinds)
            local evt = Event(
                evtType,
                evtKind.code,
                evtKind.label,
                nil,
                'inventory',
                evtKind.targetAttribute,
                amount,
                inventoryChangeRecap
            )
            table.insert(self.events, floor, evt)
        elseif evtType == 'inventory_gain' then
            local amount = Utils:easeInOutQuad(dungeonPercentage) * 20 + love.math.random(3)
            amount = math.floor(amount)

            local evtKinds = {
                { code = 'find_gold', label = 'Found Gold', targetAttribute = 'gold' },
                { code = 'find_food', label = 'Found Food', targetAttribute = 'food' },
            }
            local evtKind = Lume.randomchoice(evtKinds)
            local evt = Event(
                evtType,
                evtKind.code,
                evtKind.label,
                nil,
                'inventory',
                evtKind.targetAttribute,
                amount,
                inventoryChangeRecap
            )
            table.insert(self.events, floor, evt)
        elseif evtType == 'trap_single' then
            local baseAmount = 1
            local amount = love.math.random(baseAmount) * -1
            amount = amount * floorModifier -- scale based on floor
            local evtKinds = {
                { code = 'spikes',       label = 'Tripped on Hidden Spikes', targetAttribute = 'hp' },
                { code = 'floor_uneven', label = 'Tripped on Uneven floor',  targetAttribute = 'hp' },
                { code = 'floor_hole',   label = 'Fell in Big Hole',         targetAttribute = 'hp' },
            }
            local evtKind = Lume.randomchoice(evtKinds)
            local evt = Event(
                evtType,
                evtKind.code,
                evtKind.label,
                nil,
                'party_single',
                evtKind.targetAttribute,
                amount,
                function(e, floorIndex, partyTarget)
                    local evtRecapMsg = 'Floor ' ..
                        floorIndex .. ': ' .. e.label .. ' ' .. partyTarget.name ..
                        ' took ' .. e.modifier .. ' damage'
                    return evtRecapMsg
                end
            )
            table.insert(self.events, floor, evt)
        elseif evtType == 'trap_all' then
            local baseAmount = 1
            local amount = love.math.random(baseAmount) * -1
            amount = amount * floorModifier -- scale based on floor
            local evtKinds = {
                { code = 'bolder',     label = 'Flattened by Boulder',    targetAttribute = 'hp' },
                { code = 'flame_wall', label = 'Ran into Wall of Flames', targetAttribute = 'hp' },
                { code = 'floor_hole', label = 'Fell in Big Hole',        targetAttribute = 'hp' },
            }
            local evtKind = Lume.randomchoice(evtKinds)
            local evt = Event(
                evtType,
                evtKind.code,
                evtKind.label,
                nil,
                'party_single',
                evtKind.targetAttribute,
                amount,
                function(e, floorIndex, partyTarget)
                    local evtRecapMsg = 'Floor ' ..
                        floorIndex .. ': ' .. e.label .. ' all party members took ' .. e.modifier .. ' damage'
                    return evtRecapMsg
                end
            )
            table.insert(self.events, floor, evt)
        end
    end
end

-- Mark: Run next floor
function Dungeon:runNextFloor(currentFloorIndex)
    local evt = self.events[currentFloorIndex]
    if evt then
        -- execute events
        if Lume.find({ 'inventory_loose', 'inventory_gain' }, evt.type) then
            self.inventory[evt.targetAttribute] = self.inventory[evt.targetAttribute] + evt.modifier
            -- workaround to prevent negative inventory items
            if self.inventory[evt.targetAttribute] < 0 then
                self.inventory[evt.targetAttribute] = 0
            end
            local evtRecapMsg = evt.getRecapFn(evt, currentFloorIndex)
            table.insert(self.recap, evtRecapMsg)
        elseif evt.type == 'trap_single' then
            local randomIndex = love.math.random(#self.party)
            local randomMember = self.party[randomIndex]
            randomMember.hp = randomMember.hp + evt.modifier
            local evtRecapMsg = evt.getRecapFn(evt, currentFloorIndex, randomMember)
            table.insert(self.recap, evtRecapMsg)

            if randomMember.hp <= 0 then
                -- Kill party member
                table.remove(self.party, randomIndex)
                self.assets.sfx.death:play()
                local evtRecapMsg = 'Floor ' .. currentFloorIndex .. ': ' .. randomMember.name .. ' died'
                table.insert(self.recap, evtRecapMsg)
            end
        elseif evt.type == 'trap_all' then
            local evtRecapMsg = evt.getRecapFn(evt, currentFloorIndex, nil)
            table.insert(self.recap, evtRecapMsg)

            for index, member in ipairs(self.party) do
                member.hp = member.hp + evt.modifier
                if member.hp <= 0 then
                    -- Kill party member
                    table.remove(self.party, index)
                    self.assets.sfx.death:play()
                    local evtRecapMsg = 'Floor ' .. currentFloorIndex .. ': ' .. member.name .. ' died'
                    table.insert(self.recap, evtRecapMsg)
                end
            end
        end
    end
end

-- Mark: Consume food
function Dungeon:consumeFood(currentFloorIndex)
    local feedOrder = Lume.shuffle(self.party)
    for index, memberClone in ipairs(feedOrder) do
        local member, memberIndex = Lume.match(self.party, function(m) return m.id == memberClone.id end)
        if member then
            local consumeAmount = member.hunger
            self.inventory.food = self.inventory.food - consumeAmount
            if self.inventory.food < 0 then
                self.inventory.food = 0
                member.hp = member.hp - 1
                local evtRecapMsg = 'Floor ' .. currentFloorIndex .. ': ' ..
                    member.name .. ' took 1 damage from starving'
                table.insert(self.recap, evtRecapMsg)

                if member.hp <= 0 then
                    table.remove(self.party, memberIndex)
                    self.assets.sfx.death:play()
                    evtRecapMsg = 'Floor ' .. currentFloorIndex .. ': ' .. member.name .. ' died'
                    table.insert(self.recap, evtRecapMsg)
                end
            end
        end
    end
end

-- Consume potion
function Dungeon:consumePotion(currentFloorIndex)
    local cureOrder = Lume.shuffle(self.party)
    for index, memberClone in ipairs(cureOrder) do
        local member, memberIndex = Lume.match(self.party, function(m) return m.id == memberClone.id end)
        if member and member.hp < member.maxHp and self.inventory.potions > 0 then
            self.inventory.potions = self.inventory.potions - 1
            member.hp = member.hp + 1
            local evtRecapMsg = 'Floor ' .. currentFloorIndex .. ': ' ..
                member.name .. ' healed 1 damage using potion'
            table.insert(self.recap, evtRecapMsg)
        end
    end
end

return Dungeon
