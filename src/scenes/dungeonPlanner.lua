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
}

local partyClasses = { 'rogue', 'mage', 'warrior', 'archer' }

function DungeonPlanner:enter()
    self.systems.graphics = GraphicsSystem()
    world:registerSystem(self.systems.graphics)

    self.party = {}
    self.nextPartyClass = 'rogue'
    self.inventory = {
        food = 50,
        gold = 5,
        potions = 1,
    }

    self.targetFloor = 2
    self.currentFloor = 0
    self.events = {}
    self.executedEvents = {}
    self.recap = {}

    self.quest = 0

    self.mode = 'plan'

    -- create layers
    self.layers.plan = Plan(self.party, self.inventory, self.targetFloor, {
        clickFoodMinus = function()
            if self.inventory.food > 0 then
                self.inventory.gold = self.inventory.gold + 2
                self.inventory.food = self.inventory.food - 1
            end
        end,
        clickFoodPlus = function()
            if self.inventory.gold > 1 then
                self.inventory.gold = self.inventory.gold - 2
                self.inventory.food = self.inventory.food + 1
            end
        end,
        clickFloorMinus = function()
            if self.targetFloor > 1 then
                self.targetFloor = self.targetFloor - 1
            end
        end,
        clickFloorPlus = function()
            if self.targetFloor < 10 then
                self.targetFloor = self.targetFloor + 1
            end
        end,
        clickPotionsMinus = function()
            if self.inventory.potions > 0 then
                self.inventory.gold = self.inventory.gold + 5
                self.inventory.potions = self.inventory.potions - 1
            end
        end,
        clickPotionsPlus = function()
            if self.inventory.gold > 4 then
                self.inventory.gold = self.inventory.gold - 5
                self.inventory.potions = self.inventory.potions + 1
            end
        end,
        clickConfirm = function()
            if #self.party > 0 then
                self:setModeDungeon()
            end
        end,
        nextPartyMemberChange = function(val)
            self.nextPartyClass = val
        end,
        clickAddPartyMember = function()
            self:addPartyMember(self.nextPartyClass)
        end
    })
    self.layers.dungeon = Dungeon(self.events, self.quest, self.targetFloor, self.currentFloor, {})
    self.layers.recap = Recap(self.recap, {
        clickContinue = function() self:setModePlan() end
    })
    -- self:setModeRecap()
    self:setModePlan()

    -- load images
    self.images.table = love.graphics.newImage('assets/table.png')
end

function DungeonPlanner:update(dt)
    world:update(dt)
    love.graphics.setBackgroundColor(.30, .48, .65)
    if self.mode == 'plan' then
        self.layers.plan:update(dt, self.party, self.inventory, self.targetFloor)
    elseif self.mode == 'dungeon' then
        -- transition to Plan
        if self.quest == 1 then
            self:setModeRecap()
        end

        self.layers.dungeon:update(dt, self.events, self.quest, self.targetFloor, self.currentFloor)

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
                        local evtRecapMsg = 'Floor '..currentIndex..': '..evt.label
                        if evt.modifier > 0 then
                            evtRecapMsg = evtRecapMsg..' +'..evt.modifier
                        else
                            evtRecapMsg = evtRecapMsg..' '..evt.modifier
                        end
                        table.insert(self.recap, evtRecapMsg)
                    elseif evt.type == 'trap_single' then
                        local randomIndex = love.math.random(#self.party)
                        local randomMember = self.party[randomIndex]
                        randomMember.hp = randomMember.hp + evt.modifier
                        local evtRecapMsg = 'Floor '..currentIndex..': '..evt.label..' '..randomMember.name..' took '..evt.modifier..' damage'
                        table.insert(self.recap, evtRecapMsg)
                        if randomMember.hp <= 0 then
                            -- Kill party member
                            table.remove(self.party, randomIndex)
                            local evtRecapMsg = 'Floor '..currentIndex..': '..randomMember.name..' died'
                            table.insert(self.recap, evtRecapMsg)
                        end
                    elseif evt.type == 'trap_all' then
                        local evtRecapMsg = 'Floor '..currentIndex..': '..evt.label..' all party members took '..evt.modifier..' damage'
                        table.insert(self.recap, evtRecapMsg)
                        for index, member in ipairs(self.party) do
                            member.hp = member.hp + evt.modifier
                            if member.hp <= 0 then
                                table.remove(self.party, index)
                                local evtRecapMsg = 'Floor '..currentIndex..': '..member.name..' died'
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
                        local evtRecapMsg = 'Floor '..currentIndex..': '..member.name..' took 1 damage from starving'
                        table.insert(self.recap, evtRecapMsg)
                        if member.hp <= 0 then
                            table.remove(self.party, index)
                            local evtRecapMsg = 'Floor '..currentIndex..': '..member.name..' died'
                            table.insert(self.recap, evtRecapMsg)
                        end
                    end
                end
            end
            self.currentFloor = currentIndex
        end
    elseif self.mode == 'recap' then
        self.layers.recap:update(dt, self.recap)
    end
end

function DungeonPlanner:draw()
    world:draw()
    if self.mode == 'plan' then
        -- draw party
        love.graphics.draw(self.images.table, 150, 200, 0, 3, 3)
    elseif self.mode == 'dungeon' then
    end

    -- draw UI
    Luis.draw()
    -- DEBUG
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

    for floor = 1, self.targetFloor do
        local floorModifier = math.max(1, math.floor(floor / 5))
        local evtType = Lume.randomchoice(eventTypes)
        -- Inventory Loose events
        if evtType == 'inventory_loose' then
            local baseAmount = 3
            local amount = love.math.random(baseAmount) * -1
            amount = amount * floorModifier -- scale based on floor

            local evtKinds = {
                { code = 'loose_gold', label = 'Lost Gold', targetAttribute = 'gold' },
                { code = 'loose_food', label = 'Lost Food', targetAttribute = 'food' },
            }
            local evtKind = Lume.randomchoice(evtKinds)
            local evt = Event(evtType, evtKind.code, evtKind.label, nil, 'inventory', evtKind.targetAttribute, amount)
            table.insert(self.events, floor, evt)
        elseif evtType == 'inventory_gain' then
            local baseAmount = 2
            local amount = love.math.random(baseAmount)
            amount = amount * floorModifier -- scale based on floor

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
end

function DungeonPlanner:setModePlan()
    self.mode = 'plan'
    self.layers.plan:showLayer()
    self.layers.dungeon:hideLayer()
    self.layers.recap:hideLayer()

    -- Reset events
    -- self.events = {}
    self.executedEvents = {}
end

function DungeonPlanner:setModeRecap()
    self.mode = 'recap'
    self.layers.plan:hideLayer()
    self.layers.dungeon:hideLayer()
    self.layers.recap:showLayer()
end

function DungeonPlanner:addPartyMember(class)
    local pm = PartyMember(class)
    table.insert(self.party, pm)
    world:registerEntity(pm)

end

function DungeonPlanner:generateIcons()
    local icon
    self.icons = { icon }
end

return DungeonPlanner
