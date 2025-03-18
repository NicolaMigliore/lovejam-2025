local Plan = require 'src.layers.plan'
local Dungeon = require 'src.layers.dungeon'
local Event = require 'src.event'

local DungeonPlanner = {
    layers = {},
    modes = { 'plan', 'dungeon', 'result' }
}

function DungeonPlanner:enter()
    self.party = {
        { id = 1, class = 'rogue',  race = 'goblin', maxHp = 10, hp = 5, dmg = 10 },
        { id = 2, class = 'archer', race = 'orc',    maxHp = 10, hp = 5, dmg = 10 }
    }
    self.inventory = {
        food = 10,
        gold = 5,
    }

    self.targetFloor = 3
    self.currentFloor = 0
    self.events = {}
    self.executedEvents = {}

    self.floors = {
        { label = 'floor -1', events = { self.events[1], self.events[2] } }
    }
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
            self.targetFloor = self.targetFloor + 1
        end,
        clickConfirm = function()
            self:setModeDungeon()
        end
    })
    -- dungeonEvents, questPercentage, targetFloor, currentFloor
    self.layers.dungeon = Dungeon(self.events, self.quest, self.targetFloor, self.currentFloor, {})
    -- self:setModeDungeon()
    self:setModePlan()
end

function DungeonPlanner:update(dt)
    if self.mode == 'plan' then
        self.layers.plan:update(dt, self.party, self.inventory, self.targetFloor)
    elseif self.mode == 'dungeon' then
        -- transition to Plan
        if self.quest == 1 then
            self:setModePlan()
        end

        self.layers.dungeon:update(dt, self.events, self.quest, self.targetFloor, self.currentFloor)

        -- run floors
        local currentIndex = math.floor(self.targetFloor * self.quest) + 1 --self.currentFloor
        local runNextFloor = currentIndex > self.currentFloor and currentIndex <= self.targetFloor

        if runNextFloor then
            -- run event
            local runNextEvent = true
            if runNextEvent then
                local evt = self.events[currentIndex]

                if evt then
                    -- Execute events
                    if Lume.find({ 'inventory_loose', 'inventory_gain' }, evt.type) then
                        self.inventory[evt.targetAttribute] = self.inventory[evt.targetAttribute] + evt.modifier
                    elseif evt.type == 'trap_single' then
                        local randomIndex = love.math.random(#self.party)
                        local randomMember = self.party[randomIndex]
                        randomMember.hp = randomMember.hp + evt.modifier
                        if randomMember.hp <= 0 then
                            table.remove(self.party, randomIndex)
                        end
                    elseif evt.type == 'trap_all' then
                        for index, member in ipairs(self.party) do
                            member.hp = member.hp + evt.modifier
                            if member.hp <= 0 then
                                table.remove(self.party, index)
                            end
                        end
                    end

                    table.insert(self.executedEvents, currentIndex, evt)
                end
            end

            -- consume food
            -- TODO: consume more or less food based on race
            local toConsume = #self.party * 1


            local feedOrder = Lume.shuffle(self.party)
            for index, memberClone in ipairs(feedOrder) do
                local member, memberIndex = Lume.match(self.party, function(m) return m.id == memberClone.id end)
                if member then
                    local consumeAmount = 1 -- TODO change based on race
                    self.inventory.food = self.inventory.food - consumeAmount
                    if self.inventory.food < 0 then
                        self.inventory.food = 0
                        member.hp = member.hp - 1
                        if member.hp <= 0 then
                            print('removing', Json.encode(member))
                            table.remove(self.party, index)
                            print(Json.encode(self.party))
                        end
                    end
                end
            end
            self.currentFloor = currentIndex
        end
    end
end

function DungeonPlanner:draw()
    if self.mode == 'plan' then
        -- draw party
    end

    -- love.graphics.setColor(1,1,1,1)
    -- love.graphics.print(self.currentFloor, 200, 200)
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
    -- Event('event', 'find_gold', 'Found Gold', nil, 'inventory', 'gold', 10),
    -- Event('event', 'loose_gold', 'Lost Gold', nil, 'inventory', 'gold', -3),
    -- Event('event', 'food_rot', 'Food Rot', nil, 'inventory', 'food', -2),


    local eventTypes = { 'inventory_loose', 'inventory_gain', 'trap_single', 'trap_all' }

    for floor = 1, self.targetFloor do
        local floorModifier = math.max(1, math.floor(floor/5))
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
                { code = 'spikes', label = 'Tripped on Hidden Spikes', targetAttribute = 'hp' },
                { code = 'floor_uneven', label = 'Tripped on Uneven floor', targetAttribute = 'hp' },
                { code = 'floor_hole', label = 'Fell in Big Hole', targetAttribute = 'hp' },
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
                { code = 'bolder', label = 'Flattened by Boulder', targetAttribute = 'hp' },
                { code = 'flame_wall', label = 'Ran into Wall of Flames', targetAttribute = 'hp' },
                { code = 'floor_hole', label = 'Fell in Big Hole', targetAttribute = 'hp' },
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

    self:generateEvents()

    self.quest = 0
    self.currentFloor = 0
    Flux.to(self, 5, { quest = 1 }):delay(.5)
end

function DungeonPlanner:setModePlan()
    self.mode = 'plan'
    self.layers.plan:showLayer()
    self.layers.dungeon:hideLayer()

    -- Reset events
    -- self.events = {}
    self.executedEvents = {}
end

return DungeonPlanner