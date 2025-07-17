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
        show = true,

        update = function(self, mx, my, dt)
            self.animation:update(dt)
        end,

        defaultDraw = function(self)
            if self.show then
                love.graphics.setColor(iconTheme.color)
                self.animation:draw(self.iconImage, self.position.x, self.position.y, 0, self.width / 32, self.height / 32)
            end
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

        setAnimation = function(self, newAnimation)
            self.animation = newAnimation
        end,

        getPosition = function(self)
            return self.position.x, self.position.y
        end,
        setPosition = function(self, r, c)
            self.position = Vector2D.new((c - 1) * luis.gridSize, (r - 1) * luis.gridSize)
        end,
        setShow = function(self, show)
            self.show = show
        end
    }
end

return icon
