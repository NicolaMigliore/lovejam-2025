local Plan = require 'src.layers.plan'
local Dungeon = require 'src.layers.dungeon'
local Recap = require 'src.layers.recap'
local Event = require 'src.event'
local PartyMember = require 'src.entities.partyMember'

local GraphicsSystem = require 'src.systems.graphicsSystem'

local world = ECSWorld()
local DungeonPlanner = {
    systems = {},
    layers = {},
    modes = { 'plan', 'dungeon', 'result' },
    images = {},
    music = {},
    sfx = {}
}

local maxFloor = 10
local cost = {
    food = 1,
    potion = 5
}

function DungeonPlanner:enter()
    -- load images
    self.images.tavern = love.graphics.newImage('assets/tavern.png')
    self.images.table = love.graphics.newImage('assets/table.png')
    self.images.dungeon = love.graphics.newImage('assets/dungeon.png')

    -- load music
    self.music.tavern = love.audio.newSource('assets/music/The Daily Brew Tavern (LOOP).wav', 'stream')
    self.music.dungeon = love.audio.newSource('assets/music/Lost.mp3', 'stream')
    self.music.chatter = love.audio.newSource('assets/music/695295__brunoboselli__pirate-tavern.wav', 'stream')

    -- load sfx
    self.sfx.click = love.audio.newSource('assets/sounds/click.wav', 'static')
    self.sfx.drip = love.audio.newSource('assets/sounds/water-drop-night-horror-effects-304065.mp3', 'static')
    self.sfx.noGold = love.audio.newSource('assets/sounds/Fantasy_UI (8).wav', 'static')

    self.sfx.effortGoblin = love.audio.newSource('assets/sounds/11. Effort Grunt (Male).wav', 'static')
    self.sfx.effortHuman = love.audio.newSource('assets/sounds/05. Effort Grunt (Male).wav', 'static')
    self.sfx.effortElf = love.audio.newSource('assets/sounds/09. Effort Grunt (Male).wav', 'static')
    self.sfx.effortOrc = love.audio.newSource('assets/sounds/13. Effort Grunt (Male).wav', 'static')
    self.sfx.death = love.audio.newSource('assets/sounds/34. Effort Grunt (Male).wav', 'static')

    -- reset world
    world = ECSWorld()
    self.systems.graphics = GraphicsSystem()
    world:registerSystem(self.systems.graphics)

    self.party = {}
    self.nextPartyClass = 'rogue'
    self.inventory = {
        food = 0,
        gold = 10,
        potions = 0,
    }

    self.targetFloor = 1
    self.currentFloor = 0
    self.events = {}
    self.executedEvents = {}
    self.recap = {}

    self.days = 0
    self.quest = 0

    self.mode = 'plan'

    -- create layers
    self.layers.plan = Plan(self.party, self.inventory, self.targetFloor, self.days, {
        clickFoodMinus = function()
            if self.inventory.food > 0 then
                self.inventory.gold = self.inventory.gold + cost.food
                self.inventory.food = self.inventory.food - 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        clickFoodPlus = function()
            if self.inventory.gold > 1 then
                self.inventory.gold = self.inventory.gold - cost.food
                self.inventory.food = self.inventory.food + 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        clickFloorMinus = function()
            if self.targetFloor > 1 then
                self.targetFloor = self.targetFloor - 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        clickFloorPlus = function()
            if self.targetFloor < maxFloor then
                self.targetFloor = self.targetFloor + 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        clickPotionsMinus = function()
            if self.inventory.potions > 0 then
                self.inventory.gold = self.inventory.gold + cost.potion
                self.inventory.potions = self.inventory.potions - 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        clickPotionsPlus = function()
            if self.inventory.gold > 4 then
                self.inventory.gold = self.inventory.gold - cost.potion
                self.inventory.potions = self.inventory.potions + 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        clickConfirm = function()
            if #self.party > 0 then
                self:setModeDungeon()
                self.days = self.days + 1
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end,
        nextPartyMemberChange = function(val)
            self.nextPartyClass = val
            self.sfx.click:play()
        end,
        clickAddPartyMember = function()
            if #self.party < 4 then
                self:addPartyMember(self.nextPartyClass)
            end
        end,
        clickRemovePartyMember = function(index)
            local member = self.party[index]
            if member then
                self.inventory.gold = self.inventory.gold + member.cost
                world:unregisterEntity(member.id)
                table.remove(self.party, index)
                self.sfx.click:play()
            else
                self.sfx.noGold:play()
            end
        end
    })
    self.layers.dungeon = Dungeon(self.events, self.quest, self.targetFloor, self.currentFloor, {})
    self.layers.recap = Recap(self.recap, false, {
        clickContinue = function()
            local hasWon = self.targetFloor == maxFloor and #self.party > 0
            if hasWon then
                GameState.switch(GAME_STATES.winScreen, self.days)
            else
                self:setModePlan()
            end
            self.sfx.click:play()
        end,
        clickExit = function()
            GameState.switch(GAME_STATES.title)
            self.sfx.click:play()
        end,
    })
    -- self:setModeRecap()
    self:setModePlan()
end

function DungeonPlanner:update(dt)
    world:update(dt)

    -- update entity position
    for index, member in ipairs(self.party) do
        local x = 200 + index * (member.size.w / 2 + 50)
        local y = 245 + index * 10 -- simulate basic z-sorting
        member.body.position.x = x
        member.body.position.y = y
    end

    love.graphics.setBackgroundColor(.30, .48, .65)
    if self.mode == 'plan' then
        self.layers.plan:update(dt, self.party, self.inventory, self.targetFloor, self.days)

        -- play music
        if GAME_SETTINGS.playMusic and not self.music.tavern:isPlaying() then
            self.music.tavern:play()
        end
        if GAME_SETTINGS.playMusic and not self.music.chatter:isPlaying() then
            self.music.chatter:play()
        end
    elseif self.mode == 'dungeon' then
        -- transition to Plan
        if self.quest == 1 then
            self:setModeRecap()
        end

        self.layers.dungeon:update(dt, self.events, self.quest, self.targetFloor, self.currentFloor, self.party)

        -- play music
        if GAME_SETTINGS.playMusic and not self.music.dungeon:isPlaying() then
            self.music.dungeon:play()
        end

        -- run floors
        local currentIndex = math.floor(self.targetFloor * self.quest) + 1 --self.currentFloor
        local runNextFloor = currentIndex > self.currentFloor and currentIndex <= self.targetFloor and #self.party > 0

        if runNextFloor then
            -- run event
            local runNextEvent = true
            if runNextEvent then
                local evt = self.events[currentIndex]

                if evt then
                    -- Execute events
                    if Lume.find({ 'inventory_loose', 'inventory_gain' }, evt.type) then
                        self.inventory[evt.targetAttribute] = self.inventory[evt.targetAttribute] + evt.modifier
                        -- workaround to prevent negative inventory items
                        if self.inventory[evt.targetAttribute] < 0 then
                            self.inventory[evt.targetAttribute] = 0
                        end

                        local evtRecapMsg = 'Floor ' .. currentIndex .. ': ' .. evt.label
                        if evt.modifier > 0 then
                            evtRecapMsg = evtRecapMsg .. ' +' .. evt.modifier
                        else
                            evtRecapMsg = evtRecapMsg .. ' ' .. evt.modifier
                        end
                        table.insert(self.recap, evtRecapMsg)
                    elseif evt.type == 'trap_single' then
                        local randomIndex = love.math.random(#self.party)
                        local randomMember = self.party[randomIndex]
                        randomMember.hp = randomMember.hp + evt.modifier
                        local evtRecapMsg = 'Floor ' ..
                            currentIndex .. ': ' .. evt.label .. ' ' .. randomMember.name ..
                            ' took ' .. evt.modifier .. ' damage'
                        table.insert(self.recap, evtRecapMsg)
                        if randomMember.hp <= 0 then
                            -- Kill party member
                            world:unregisterEntity(randomMember.id)
                            table.remove(self.party, randomIndex)
                            self.sfx.death:play()
                            local evtRecapMsg = 'Floor ' .. currentIndex .. ': ' .. randomMember.name .. ' died'
                            table.insert(self.recap, evtRecapMsg)
                        end
                    elseif evt.type == 'trap_all' then
                        local evtRecapMsg = 'Floor ' ..
                            currentIndex .. ': ' .. evt.label .. ' all party members took ' .. evt.modifier .. ' damage'
                        table.insert(self.recap, evtRecapMsg)
                        for index, member in ipairs(self.party) do
                            member.hp = member.hp + evt.modifier
                            if member.hp <= 0 then
                                world:unregisterEntity(member.id)
                                table.remove(self.party, index)
                                self.sfx.death:play()
                                local evtRecapMsg = 'Floor ' .. currentIndex .. ': ' .. member.name .. ' died'
                                table.insert(self.recap, evtRecapMsg)
                            end
                        end
                    end
                    table.insert(self.executedEvents, currentIndex, evt)
                end
            end

            -- consume food
            local feedOrder = Lume.shuffle(self.party)
            for index, memberClone in ipairs(feedOrder) do
                local member, memberIndex = Lume.match(self.party, function(m) return m.id == memberClone.id end)
                if member then
                    local consumeAmount = member.hunger
                    self.inventory.food = self.inventory.food - consumeAmount
                    if self.inventory.food < 0 then
                        self.inventory.food = 0
                        member.hp = member.hp - 1
                        local evtRecapMsg = 'Floor ' .. currentIndex .. ': ' ..
                            member.name .. ' took 1 damage from starving'
                        table.insert(self.recap, evtRecapMsg)
                        if member.hp <= 0 then
                            world:unregisterEntity(member.id)
                            table.remove(self.party, index)
                            self.sfx.death:play()
                            local evtRecapMsg = 'Floor ' .. currentIndex .. ': ' .. member.name .. ' died'
                            table.insert(self.recap, evtRecapMsg)
                        end
                    end
                end
            end

            -- consume potions
            local cureOrder = Lume.shuffle(self.party)
            for index, memberClone in ipairs(cureOrder) do
                local member, memberIndex = Lume.match(self.party, function(m) return m.id == memberClone.id end)
                if member and member.hp < member.maxHp and self.inventory.potions > 0 then
                    self.inventory.potions = self.inventory.potions - 1
                    member.hp = member.hp + 1
                    local evtRecapMsg = 'Floor ' .. currentIndex .. ': ' ..
                        member.name .. ' healed 1 damage using potion'
                    table.insert(self.recap, evtRecapMsg)
                end
            end

            self.currentFloor = currentIndex
        end
    elseif self.mode == 'recap' then
        local isGameOver = #self.party == 0 and self.inventory.gold < 4 -- 4 is the cost of a rogue
        self.layers.recap:update(dt, self.recap, isGameOver)

        -- play music
        if GAME_SETTINGS.playMusic and not self.music.dungeon:isPlaying() then
            self.music.dungeon:play()
        end
    end
end

function DungeonPlanner:draw()
    love.graphics.setColor(1, 1, 1, 1)

    if self.mode == 'plan' then
        -- draw environment
        local imgW, imgH = self.images.tavern:getWidth(), self.images.tavern:getHeight()
        local scaleX, scaleY = GAME_SETTINGS.baseWidth / imgW, GAME_SETTINGS.baseHeight / imgH
        love.graphics.draw(self.images.tavern, 0, 0, 0, scaleX, scaleY)

        -- draw party
        world:draw()

        -- draw table
        local tableScale = 3
        love.graphics.draw(self.images.table, 150, 200, 0, tableScale, tableScale)
    elseif self.mode == 'dungeon' or self.mode == 'recap' then
        -- draw environment
        local imgW, imgH = self.images.dungeon:getWidth(), self.images.dungeon:getHeight()
        local scaleX, scaleY = GAME_SETTINGS.baseWidth / imgW, GAME_SETTINGS.baseHeight / imgH
        love.graphics.draw(self.images.dungeon, 0, 0, 0, scaleX, scaleY)
    end

    -- draw UI
    Luis.draw()
    -- DEBUG

end

function DungeonPlanner:leave()
    Luis.removeLayer(self.layers.plan.layerName)
    Luis.removeLayer(self.layers.dungeon.layerName)
    Luis.removeLayer(self.layers.recap.layerName)

    self.music.tavern:stop()
    self.music.dungeon:stop()
    self.sfx.drip:stop()
end

function DungeonPlanner:keypressed(key, code, isRepeat)
    if key == 'escape' then
        love.event.quit(0)
    end
end

function DungeonPlanner:mousepressed(x, y, button, istouch, presses)
    -- local worldX, worldY = self.graphicsSystem.camera:toWorld(x, y)
    -- world:mousepressed(worldX, worldY, button, istouch, presses)
end

function DungeonPlanner:resize(w, h)
    -- self.graphicsSystem:setCameraScale()
end

function DungeonPlanner:generateEvents()
    self.events = {}
    local eventTypes = { 'inventory_loose', 'inventory_gain', 'trap_single', 'trap_all' }

    local floorEventWeights = {
        inventory_loose = function(x) return x end,                    -- linear
        inventory_gain = function(x) return 1 - (1 - x) * (1 - x) end, -- easeOutQuad
        trap_single = function(x) return x * x end,                    -- easeInQuad
        trap_all = function(x) return x * x * x * x * x end,           -- easeInQuint
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
            local evt = Event(evtType, evtKind.code, evtKind.label, nil, 'inventory', evtKind.targetAttribute, amount)
            table.insert(self.events, floor, evt)
        elseif evtType == 'inventory_gain' then
            local amount = Utils:easeInOutQuad(dungeonPercentage) * 20 + love.math.random(3)
            amount = math.floor(amount)

            local evtKinds = {
                { code = 'find_gold', label = 'Found Gold', targetAttribute = 'gold' },
                { code = 'find_food', label = 'Found Food', targetAttribute = 'food' },
            }
            local evtKind = Lume.randomchoice(evtKinds)
            local evt = Event(evtType, evtKind.code, evtKind.label, nil, 'inventory', evtKind.targetAttribute, amount)
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
            local evt = Event(evtType, evtKind.code, evtKind.label, nil, 'party_single', evtKind.targetAttribute, amount)
            table.insert(self.events, floor, evt)
            -- Event('trap', 'environmental_trap', 'Hidden Spikes', nil, 'party_single', 'hp', -2),
            -- Event('trap', 'environmental_trap', 'Poison Fog', nil, 'party_all', 'hp', -1),
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
            local evt = Event(evtType, evtKind.code, evtKind.label, nil, 'party_single', evtKind.targetAttribute, amount)
            table.insert(self.events, floor, evt)
        end
    end
end

function DungeonPlanner:setModeDungeon()
    self.mode = 'dungeon'
    self.layers.plan:hideLayer()
    self.layers.dungeon:showLayer()
    self.layers.recap:hideLayer()

    self:generateEvents()

    self.quest = 0
    self.currentFloor = 0
    self.recap = {}
    Flux.to(self, 5, { quest = 1 }):delay(.5)

    -- play music
    love.audio.stop(self.music.tavern)
    love.audio.stop(self.music.chatter)
    if GAME_SETTINGS.playMusic and not self.music.dungeon:isPlaying() then
        self.music.dungeon:play()
    end
    self.sfx.drip:play()
end

function DungeonPlanner:setModePlan()
    self.mode = 'plan'
    self.layers.plan:showLayer()
    self.layers.dungeon:hideLayer()
    self.layers.recap:hideLayer()

    -- Reset events
    -- self.events = {}
    self.executedEvents = {}

    -- play music
    love.audio.stop(self.music.dungeon)
    love.audio.stop(self.sfx.drip)
    if GAME_SETTINGS.playMusic and not self.music.tavern:isPlaying() then
        self.music.tavern:play()
    end
end

function DungeonPlanner:setModeRecap()
    self.mode = 'recap'
    self.layers.plan:hideLayer()
    self.layers.dungeon:hideLayer()
    self.layers.recap:showLayer()
end

function DungeonPlanner:addPartyMember(class)
    local classSounds = {
        rogue = self.sfx.effortGoblin,
        archer = self.sfx.effortHuman,
        mage = self.sfx.effortElf,
        warrior = self.sfx.effortOrc,
    }

    local pm = PartyMember(class, 0, 0)
    if pm.cost <= self.inventory.gold then
        self.inventory.gold = self.inventory.gold - pm.cost
        table.insert(self.party, pm)
        world:registerEntity(pm)
        self.sfx.click:play()
        classSounds[class]:play()
    else
        self.sfx.noGold:play()
        -- TODO: give player feedback SFX, text color
    end
end

function DungeonPlanner:generateIcons()
    local icon
    self.icons = { icon }
end

return DungeonPlanner
