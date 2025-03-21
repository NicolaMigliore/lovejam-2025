local Vector2D = require("luis.3rdparty.vector")
local decorators = require("luis.3rdparty.decorators")

local icon = {}

local luis  -- This will store the reference to the core library
function icon.setluis(luisObj)
    luis = luisObj
end

-- Icon
function icon.new(iconPath, animation, size, row, col, customTheme)
    local iconTheme = customTheme or luis.theme.icon
    local icon = iconPath
    if type(iconPath) == 'string' then
        icon = love.graphics.newImage(iconPath)
    end
    return {
        type = "IconAnimated",
        iconImage = icon,
        width = size * luis.gridSize,
        height = size * luis.gridSize,
        position = Vector2D.new((col - 1) * luis.gridSize, (row - 1) * luis.gridSize),
		theme = iconTheme,
		decorator = nil,
        animation = animation,
        
        defaultDraw = function(self)
            love.graphics.setColor(iconTheme.color)
            self.animation:draw(self.iconImage, self.position.x, self.position.y, 0, self.width / 32, self.height / 32)
            -- if self.quad then
            --     -- love.graphics.draw(self.icon, self.quad, self.position.x, self.position.y, 0, self.width / self.icon:getWidth(), self.height / self.icon:getHeight())
            --     love.graphics.draw(self.icon, self.quad, self.position.x, self.position.y, 0, self.width / 16, self.height / 16)
            -- else
            --     love.graphics.draw(self.icon, self.position.x, self.position.y, 0, self.width / self.icon:getWidth(), self.height / self.icon:getHeight())
            -- end
        end,

		-- Draw method that can use a decorator
		draw = function(self)
			if self.decorator then
				self.decorator:draw()
			else
				self:defaultDraw()
			end
		end,

		-- Method to set a decorator
		setDecorator = function(self, decoratorType, ...)
			self.decorator = decorators[decoratorType].new(self, ...)
		end,
    }
end

return icon
