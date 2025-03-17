local Plan = require 'src.layers.plan'
local Dungeon = require 'src.layers.dungeon'

local DungeonPlanner = {
    layers = {},
    modes = { 'plan', 'dungeon', 'result' }
}

function DungeonPlanner:enter()
    self.party = {
        { id = 1, class = 'rogue', race = 'goblin', hp = 1,  dmg = 10 },
        { id = 2, class = 'archer', race = 'orc', hp = 2,  dmg = 10 }
    }
    self.inventory = {
        food = 10,
        gold = 5,
    }

    self.targetFloor = 3
    self.currentFloor = 0
    self.events = {
        { type = 'event', code = 'food_rot', label = 'food rot', target = 'inventory', targetAttribute = 'food', modifier = -3 },
        -- { type = 'event', code = 'env_damage', label = 'poison trap', target = 'party', targetAttribute = 'hp', modifier = -5 },
        -- { type = 'event', code = 'food_rot', label = 'food rot', target = 'inventory', targetAttribute = 'food', modifier = -1 },
        -- -- { type = 'battle', label = 'battle skeleton', enemyParty = { { class= 'archer'}},  }
    }
    self.executedEvents = {}

    self.floors = {
        { label = 'floor -1', events = { self.events[1], self.events[2] }}
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
    self:setModeDungeon()
    -- self:setModePlan()
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
                    -- { type = 'event', code = 'food_rot', label = 'food rot', target = 'inventory', targetAttribute = 'food', modifier = -3 }
                    -- print(evt.type, evt.label)
                    if evt.code == 'food_rot' then
                        self.inventory[evt.targetAttribute] = self.inventory[evt.targetAttribute] + evt.modifier
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
                    local consumeAmount = 1     -- TODO change based on race
                    self.inventory.food = self.inventory.food - consumeAmount
                    if self.inventory.food < 0 then
                        self.inventory.food = 0
                        member.hp = member.hp -1
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
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(self.currentFloor, 200, 200)


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

function DungeonPlanner:setModeDungeon()
    self.mode = 'dungeon'
    self.layers.plan:hideLayer()
    self.layers.dungeon:showLayer()

    self.quest = 0
    self.currentFloor = 0
    Flux.to(self, 5, { quest = 1}):delay(.5)
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