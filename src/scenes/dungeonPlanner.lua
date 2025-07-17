local Plan = require 'src.layers.plan'
local Dungeon = require 'src.layers.dungeon'
local Recap = require 'src.layers.recap'
local Event = require 'src.event'
local PartyMember = require 'src.entities.partyMember'

local GraphicsSystem = require 'src.systems.graphicsSystem'

local world
local DungeonPlanner = {
    systems = {},
    layers = {},
    modes = { 'plan', 'dungeon', 'result' },
    images = {},
    music = {},
    sfx = {},
    inventory = {
        food = 0,
        gold = 10,
        potions = 0,
    },
    targetFloor = 1,
    party = {}
}

local maxFloor = 10
local cost = {
    food = 1,
    potion = 5
}

function DungeonPlanner:enter(previousState, inventory, targetFloor, party)
    -- load images
    self.images.tavern = love.graphics.newImage('assets/tavern.png')
    self.images.table = love.graphics.newImage('assets/table.png')
    self.images.dungeon = love.graphics.newImage('assets/dungeon.png')

    -- load music
    self.music.tavern = love.audio.newSource('assets/music/The Daily Brew Tavern (LOOP).wav', 'stream')
    -- self.music.dungeon = love.audio.newSource('assets/music/Lost.mp3', 'stream')
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


    self.nextPartyClass = 'rogue'
    self.party = party or self.party
    self.inventory = inventory or self.inventory

    self.targetFloor = targetFloor or self.targetFloor
    self.currentFloor = 0
    self.events = {}
    self.executedEvents = {}
    self.recap = {}

    self.days = 0
    self.quest = 0


    -- reset world
    world = ECSWorld()
    self.systems.graphics = GraphicsSystem()
    world:registerSystem(self.systems.graphics)

    -- reset entities
    for index, member in ipairs(self.party) do
        if not world.entities[member.id] then
            world:registerEntity(member)
        end
    end

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

                self.layers.plan:refreshIcons()
            else
                self.sfx.noGold:play()
            end
        end
    })
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

    self.layers.plan:update(dt, self.party, self.inventory, self.targetFloor, self.days)

    -- play music
    if GAME_SETTINGS.playMusic and not self.music.tavern:isPlaying() then
        self.music.tavern:play()
    end
    if GAME_SETTINGS.playMusic and not self.music.chatter:isPlaying() then
        self.music.chatter:play()
    end
end

-- Mark: Draw
function DungeonPlanner:draw()
    love.graphics.setColor(1, 1, 1, 1)
    -- draw environment
    local imgW, imgH = self.images.tavern:getWidth(), self.images.tavern:getHeight()
    local scaleX, scaleY = GAME_SETTINGS.baseWidth / imgW, GAME_SETTINGS.baseHeight / imgH
    love.graphics.draw(self.images.tavern, 0, 0, 0, scaleX, scaleY)

    -- draw party
    world:draw()

    -- draw table
    local tableScale = 3
    love.graphics.draw(self.images.table, 150, 200, 0, tableScale, tableScale)

    -- draw UI
    Luis.draw()
    -- DEBUG
end

-- Mark: Leave
function DungeonPlanner:leave()
    Luis.removeLayer(self.layers.plan.layerName)

    self.music.tavern:stop()
    self.music.chatter:stop()
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
    GameState.switch(GAME_STATES.dungeon, self.inventory, self.targetFloor, self.party)
end

function DungeonPlanner:setModePlan()
    self.layers.plan:showLayer()

    -- Reset events
    self.executedEvents = {}

    -- play music
    -- love.audio.stop(self.music.dungeon)
    -- love.audio.stop(self.sfx.drip)
    if GAME_SETTINGS.playMusic and not self.music.tavern:isPlaying() then
        self.music.tavern:play()
    end
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

    -- update UI party icons
    self.layers.plan:refreshIcons()
end


return DungeonPlanner
