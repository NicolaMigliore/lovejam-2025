local Plan = require 'src.layers.plan'
local PartyMember = require 'src.entities.partyMember'
local GraphicsSystem = require 'src.systems.graphicsSystem'
local Event = require 'src.event'

local Tutorial = {
    systems = {},
    layers = {},
    images = {},
    music = {},
    sfx = {},
    inventory = {
        food = 0,
        gold = 11,
        potions = 0,
    },
    targetFloor = 1,
    party = {},
    cur_step = 0,
    cur_msg = nil,
    can_advance = true,
}

local maxFloor = 10
local cost = {
    food = 1,
    potion = 5
}
-- MARK: Enter
function Tutorial:enter(previousState, inventory, targetFloor, party)
    self:loadStaticAssets()

    self.nextPartyClass = 'rogue'
    self.party = party or self.party
    self.inventory = inventory or self.inventory

    self.targetFloor = targetFloor or self.targetFloor
    self.days = 0

    -- reset world
    self.world = ECSWorld()
    self.systems.graphics = GraphicsSystem()
    self.world:registerSystem(self.systems.graphics)

    -- reset entities
    for index, member in ipairs(self.party) do
        if not self.world.entities[member.id] then
            self.world:registerEntity(member)
        end
    end

    self:createUI()
    self:setModePlan()
end

-- MARK: Update
function Tutorial:update(dt)
    self.world:update(dt)

    -- update entity position
    for index, member in ipairs(self.party) do
        local x = 200 + index * (member.size.w / 2 + 50)
        local y = 245 + index * 10 -- simulate basic z-sorting
        member.body.position.x = x
        member.body.position.y = y
    end

    love.graphics.setBackgroundColor(.30, .48, .65)

    local showParty = self.cur_step > 2
    local showInventory = self.cur_step > 3
    local showConfirm = self.cur_step > 4
    local showList = {showParty,showInventory,showConfirm}

    self.layers.plan:update(
        dt,
        self.party,
        self.inventory,
        self.targetFloor,
        self.days,
        showList
    )

    -- play music
    if GAME_SETTINGS.playMusic and not self.music.tavern:isPlaying() then
        self.music.tavern:play()
    end
    if GAME_SETTINGS.playMusic and not self.music.chatter:isPlaying() then
        self.music.chatter:play()
    end

    -- check if message can advance
    if self.cur_step == 4 then
        local has_food = self.inventory.food == 2
        local has_potion = self.inventory.potions == 1
        local correct_floor = self.targetFloor == 2
        self.can_advance = has_food and has_potion and correct_floor
    end
end

-- MARK: Draw
function Tutorial:draw()
    love.graphics.setColor(1, 1, 1, 1)
    -- draw environment
    local imgW, imgH = self.images.tavern:getWidth(), self.images.tavern:getHeight()
    local scaleX, scaleY = GAME_SETTINGS.baseWidth / imgW, GAME_SETTINGS.baseHeight / imgH
    love.graphics.draw(self.images.tavern, 0, 0, 0, scaleX, scaleY)

    -- draw party
    self.world:draw()

    -- draw table
    local tableScale = 3
    love.graphics.draw(self.images.table, 150, 200, 0, tableScale, tableScale)

    -- draw UI
    Luis.draw()
end

-- MARK: Leave
function Tutorial:leave()
    Luis.removeLayer(self.layers.plan.layerName)
    Luis.removeLayer(self.layers.tutorialMsg.layerName)

    self.music.tavern:stop()
    self.music.chatter:stop()
end

function Tutorial:keypressed(key, code, isRepeat)
end

function Tutorial:loadStaticAssets()
    -- load images
    self.images = {}
    self.images.tavern = love.graphics.newImage('assets/tavern.png')
    self.images.table = love.graphics.newImage('assets/table.png')
    self.images.dungeon = love.graphics.newImage('assets/dungeon.png')

    -- load music
    self.music = {}
    self.music.tavern = love.audio.newSource('assets/music/The Daily Brew Tavern (LOOP).wav', 'stream')
    self.music.chatter = love.audio.newSource('assets/music/695295__brunoboselli__pirate-tavern.wav', 'stream')

    -- load sfx
    self.sfx = {}
    self.sfx.click = love.audio.newSource('assets/sounds/click.wav', 'static')
    self.sfx.drip = love.audio.newSource('assets/sounds/water-drop-night-horror-effects-304065.mp3', 'static')
    self.sfx.noGold = love.audio.newSource('assets/sounds/Fantasy_UI (8).wav', 'static')

    self.sfx.effortGoblin = love.audio.newSource('assets/sounds/11. Effort Grunt (Male).wav', 'static')
    self.sfx.effortHuman = love.audio.newSource('assets/sounds/05. Effort Grunt (Male).wav', 'static')
    self.sfx.effortElf = love.audio.newSource('assets/sounds/09. Effort Grunt (Male).wav', 'static')
    self.sfx.effortOrc = love.audio.newSource('assets/sounds/13. Effort Grunt (Male).wav', 'static')
    -- self.sfx.death = love.audio.newSource('assets/sounds/34. Effort Grunt (Male).wav', 'static')
end

function Tutorial:createUI()
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
            if self.inventory.gold >= cost.food then
                self.inventory.gold = self.inventory.gold - cost.food
                self.inventory.food = self.inventory.food + 1
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
            if self.inventory.gold >= cost.potion then
                self.inventory.gold = self.inventory.gold - cost.potion
                self.inventory.potions = self.inventory.potions + 1
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
    
    self.layers.tutorialMsg = self:CreateMessages()
    self:setStep(1)
end

function Tutorial:setModePlan()
    self.layers.plan:showLayer()
    self.layers.tutorialMsg:showLayer()

    if GAME_SETTINGS.playMusic and not self.music.tavern:isPlaying() then
        self.music.tavern:play()
    end
end

function Tutorial:setModeDungeon()
    local events = {
        Event(
            'inventory_gain',
            'find_gold',
            'Found Gold',
            nil,
            'inventory',
            'gold',
            3,
            function(e, floorIndex, partyTarget)
                local evtRecapMsg = 'Floor ' .. floorIndex .. ': ' .. e.label
                if e.modifier > 0 then
                    evtRecapMsg = evtRecapMsg .. ' +' .. e.modifier
                else
                    evtRecapMsg = evtRecapMsg .. ' ' .. e.modifier
                end
                return evtRecapMsg
            end
        ),
        Event(
            'trap_single',
            'spikes',
            'Tripped on Hidden Spikes',
            nil,
            'party_single',
            'hp',
            1,
            function(e, floorIndex, partyTarget)
                local evtRecapMsg = 'Floor ' ..
                    floorIndex .. ': ' .. e.label .. ' ' .. partyTarget.name ..
                    ' took ' .. e.modifier .. ' damage'
                return evtRecapMsg
            end
        )
    }


    GameState.switch(GAME_STATES.dungeon, self.inventory, self.targetFloor, self.party, events)
end

function Tutorial:addPartyMember(class)
    -- tutorial functionality
    if self.cur_step == 3 then
        self.can_advance = true
    end

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
        self.world:registerEntity(pm)
        self.sfx.click:play()
        classSounds[class]:play()
    else
        self.sfx.noGold:play()
        -- TODO: give player feedback SFX, text color
    end

    -- update UI party icons
    self.layers.plan:refreshIcons()
end

function Tutorial:CreateMessages()
    local layer = {
        layerName = 'tutorialMsg',
        containers = {},
        showLayer = function()
            Luis.enableLayer('tutorialMsg')
        end,
    }

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    layer.gridMaxCol, layer.gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    Luis.newLayer(layer.layerName)
    
    local cW, cH = 20, 15
    local bW, bH = 7, 2
    local offsetRow, offsetCol = layer.gridMaxRow / 2 - cH / 2, layer.gridMaxCol / 2 - cW / 2
    local borderImage = love.graphics.newImage('assets/ui.png')
    
    -- MARK: Messages
    local c_msg_1 = Luis.createElement(layer.layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'msgContainer_1')
    c_msg_1:setDecorator("Slice9Decorator", borderImage, 6, 6, 6, 6)
    layer.containers.c_msg_1 = c_msg_1

    local theme = GAME_SETTINGS.labelTheme
    -- theme.align = 'center'
    local lW, lH = cW - 2, 5
    offsetRow, offsetCol = 1, 1 + (cW / 2)- lW/2
    local l_msg_1 = Luis.createElement(layer.layerName, 'Label', '', lW, lH, offsetRow, offsetCol, 'center', theme)
    c_msg_1:addChild(l_msg_1, offsetRow, offsetCol)

    lW,lH = 3,1
    offsetRow, offsetCol = cH - lH, cW - lW
    local l_counter = Luis.createElement(layer.layerName, 'Label', '', lW, lH, offsetRow, offsetCol, 'right', theme)
    c_msg_1:addChild(l_counter, offsetRow, offsetCol)


    offsetRow = cH - bH
    offsetCol = 1 + cW / 2 - bW / 2
    local b_confirm = Luis.createElement(layer.layerName, 'Button', 'Next', bW, bH,
        function() if self.can_advance then self:setStep(self.cur_step + 1)end end, nil,
        offsetRow, offsetCol)
    c_msg_1:addChild(b_confirm, offsetRow, offsetCol)


    return layer
end

function Tutorial:setStep(newStep)
    local msgs = {
        'Welcome to Party Planner!\n\n\nGreat treasures are hidden within the dungeon and with the correct planning they will be yours.\nOf course th dungeon is filled with dangers, you best find a some fools to send in your stead, while you knock back some ale at the tavern.',
        'To start, we best enroll some gullable adventurer to send in the dungeons.\nUsing the ledger on the left you can enroll up to 4 party members to send exploring.',
        'Lucky you, a young goblin rogue has just entered the tavern!\nThe dropdown selector allows you to select an adventurer and review their stats.\n Each class will have different food requirements (F) and recruitment cost (C) that will be required to add them to your party.\n\nFor now don\'t worry about the cost, just recruit that goblin then press "Next".',
        'Now you need to buy some equipment.\nYou best invest in 2 food rations and 1 potion.\n\nFinally you choose howmany floors of the dungeon the party should explore. The goblin will eat 1 food ration each floor, if they run out they will start takinf damage, so best explore 2 floors for now.\n\nWhen you are done, click on the "Next" button.',
        'The party is ready to head for adventure.\nClick on the "Continue" button to send them exploring.\n\nYou will be presented with a recap of their adventure, then you can plan the next expedition!'
    }

    self.cur_step = newStep
    self.cur_msg = msgs[self.cur_step] or 'missing message'

    self.layers.tutorialMsg.containers.c_msg_1.children[1]:setText(self.cur_msg)
    self.layers.tutorialMsg.containers.c_msg_1.children[2]:setText(self.cur_step..'/'..#msgs)

    -- custom logic for the various steps...
    if self.cur_step == 2 then
        -- update dropdown list
        local layer = self.layers.plan
        local partyClassLabels = {'Select party member...', 'rogue (F:1, C:4)'}
        for i,child in ipairs(layer.containers.c_party.children) do
            if child.type == 'DropDown' then
                child.items = partyClassLabels
            end
        end
    elseif self.cur_step == 3 or self.cur_step == 4 or self.cur_step == 5 then
        self.can_advance = false
    end
end

return Tutorial