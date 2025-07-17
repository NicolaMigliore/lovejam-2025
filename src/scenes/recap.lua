local cW, cH = 40, 25
local pW, pH = 20, 2
local lW, lH = 15, 2
local maxFloor = 10

local Recap = {
    assets = { images = {}, music = {}, sfx = {} },
    ui = {},
    eventRecap = {},
    isGameOver = false,
}

-- Mark: Enter
function Recap:enter(previousState, inventory, targetFloor, party, eventRecap, music)
    -- reset state
    self.inventory = inventory
    self.targetFloor = targetFloor
    self.party = party
    self.eventRecap = eventRecap
    self.isGameOver = false

    -- load assets
    self.assets.images.dungeon = love.graphics.newImage('assets/dungeon.png')
    self.assets.images.borderImage = love.graphics.newImage('assets/scroll.png')
    -- self.assets.music.dungeon = love.audio.newSource('assets/music/Lost.mp3', 'stream')
    -- self.assets.music.drip = love.audio.newSource('assets/sounds/water-drop-night-horror-effects-304065.mp3', 'static')
    self.assets.music = music
    self.assets.sfx.click = love.audio.newSource('assets/sounds/click.wav', 'static')

    self:createUI()
end

-- Mark: Update
function Recap:update(dt)
    self.isGameOver = #self.party == 0 and self.inventory.gold < 4

    -- update ui
    self:updateUI(dt)

    -- play music
    if GAME_SETTINGS.playMusic and not self.assets.music.dungeon:isPlaying() then
        self.assets.music.dungeon:play()
    end
    if GAME_SETTINGS.playMusic and not self.assets.music.drip:isPlaying() then
        self.assets.music.drip:play()
    end
end

-- Mark: Draw
function Recap:draw()
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
function Recap:leave()
    Luis.removeLayer('recap')

    print('love.audio.getActiveEffects', Inspect(love.audio.getActiveEffects()))

    self.assets.music.dungeon:stop()
    self.assets.music.drip:stop()
end

function Recap:keypressed(key, code, isRepeat)
    if key == 'escape' then
        love.event.quit(0)
    end
end

-- Mark:CreateUI
function Recap:createUI()
    local layerName = 'recap'
    Luis.newLayer(layerName)
    self.ui.recap = {}

    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    local gridMaxCol, gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    local offsetRow, offsetCol = (gridMaxRow / 2 - cH / 2), (gridMaxCol / 2 - cW / 2)
    local c_recap = Luis.createElement(layerName, 'FlexContainer2', cW, cH, offsetRow, offsetCol, nil, 'recapContainer')
    c_recap:setDecorator("Slice9Decorator", self.assets.images.borderImage, 48, 24, 28, 36)
    self.ui.recap.c_recap = c_recap

    -- Recap Events
    self.ui.recap.floorItems = {}
    lW = cW
    offsetRow, offsetCol = cH / 2 - pH - 2, cW / 2 - lW / 2 + 1
    for index, evtRecapMsg in ipairs(self.eventRecap) do
        local l_recap = Luis.newLabel(evtRecapMsg, lW, lH, offsetRow + index, offsetCol, 'center',
            GAME_SETTINGS.labelTheme)
        c_recap:addChild(l_recap, offsetRow + index, offsetCol)

        -- save item
        table.insert(self.ui.recap.floorItems, { label = l_recap, row = offsetRow + index, col = offsetCol })
    end

    -- Continue
    self.ui.recap.buttonItems = {}
    local bW, bH = 20, 3
    local continueFn = function()
        local hasWon = self.targetFloor == maxFloor and #self.party > 0
        if hasWon then
            GameState.switch(GAME_STATES.winScreen, self.days)
        else
            GameState.switch(GAME_STATES.dungeonPlanner, self.inventory, self.targetFloor, self.party)
        end
        self.assets.sfx.click:play()
    end
    offsetRow = gridMaxRow - bH
    offsetCol = gridMaxCol / 2 - bW / 2
    local b_continue = Luis.createElement(layerName, 'Button', 'Continue XX', bW, bH, continueFn, nil, offsetRow, offsetCol)
    self.ui.recap.buttonItems.b_continue = b_continue

    Luis.enableLayer(layerName)
end

-- Mark: UpdateUI
function Recap:updateUI(dt)
    local gridCellSize = Luis.getGridSize()
    local screenW, screenH = love.window.getMode()
    local gridMaxCol, gridMaxRow = math.floor(screenW / gridCellSize), math.floor(screenH / gridCellSize)

    -- Show game over message
    if self.isGameOver then
        -- remove continue button
        if self.ui.recap.buttonItems.b_continue then
            Luis.removeElement('recap', self.ui.recap.buttonItems.b_continue)
            self.ui.recap.buttonItems.b_continue = nil
        end
        -- add exit button
        if not self.ui.recap.buttonItems.b_exit then
            local bW, bH = 20, 3
            local offsetRow = gridMaxRow - bH
            local offsetCol = gridMaxCol / 2 - bW / 2
            local b_exit = Luis.createElement('recap', 'Button', 'Back to Title', bW, bH,
                function()
                    GameState.switch(GAME_STATES.title)
                    self.assets.sfx.click:play()
                 end, nil, offsetRow, offsetCol)
            self.ui.recap.buttonItems.b_exit = b_exit
        end
    end
end

return Recap
