
require 'globals'

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setFont(love.graphics.newFont(14, "normal"))

    -- Configure Luis grid
    -- Luis.setGridSize(20)

    -- Set your base resolution
    Luis.baseWidth = GAME_SETTINGS.baseWidth
    Luis.baseHeight = GAME_SETTINGS.baseHeight

    -- Set window mode using these dimensions
    love.window.setMode(Luis.baseWidth, Luis.baseHeight, { resizable=true, fullscreen = false, display = 1 })
    Luis.setGridSize(Luis.baseWidth / 60)

    -- Configure game states
    GameState.registerEvents({ 'draw', 'update', 'quit', 'keypressed', 'mousepressed', 'resize' })
    GameState.switch(GAME_STATES.title)
end

local time = 0
function love.update(dt)
    love.math.setRandomSeed(love.timer.getTime())
    Flux.update(dt)
    
	time = time + dt
	if time >= 1/60 then	
		Luis.flux.update(time)
		time = 0
	end
    -- Update scaling (handles window resizing)
    Luis.updateScale()
    Luis.update(dt)
    Timer.update(dt)
end

function love.draw()
end

function love.mousepressed(x, y, button, istouch)
    Luis.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    Luis.mousereleased(x, y, button, istouch)
end

function love.wheelmoved(x, y)
    Luis.wheelmoved(x, y)
end

function love.keypressed(key)
    if key == "escape" then
        if Luis.currentLayer == "main" then
            love.event.quit()
        end
    elseif key == "tab" then -- Debug View
        Luis.showGrid = not Luis.showGrid
        Luis.showLayerNames = not Luis.showLayerNames
        Luis.showElementOutlines = not Luis.showElementOutlines
    else
        Luis.keypressed(key)
    end
end