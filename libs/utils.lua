local Utils = Object.extend(Object)

--- calc distance between two points
---@param x1 number point 1 x coord
---@param y1 number point 1 y coord
---@param x2 number point 2 x coord
---@param y2 number point 2 y coord
---@return number
function Utils.pointDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function Utils.drawDashedLine(x1, y1, x2, y2, dashLength, gapLength)
    dashLength = dashLength or 10
    gapLength = gapLength or 5
    local dx = x2 - x1
    local dy = y2 - y1
    local totalLength = math.sqrt(dx * dx + dy * dy)

    local numDashes = math.floor(totalLength / (dashLength + gapLength))

    -- Normalize direction vector
    local dirX = dx / totalLength
    local dirY = dy / totalLength

    for i = 0, numDashes do
        local startX = x1 + dirX * (i * (dashLength + gapLength))
        local startY = y1 + dirY * (i * (dashLength + gapLength))
        local endX = startX + dirX * dashLength
        local endY = startY + dirY * dashLength

        love.graphics.line(startX, startY, endX, endY)
    end
end

--- Check if a point is colliding with a box area
--- @param px number Point X coord
--- @param py number Point Y coord
--- @param rx1 number Rect top-left corner X coord
--- @param ry1 number Rect top-left corner Y coord
--- @param rx2 number Rect bottom-right corner X coord
--- @param ry2 number Rect bottom-right corner Y coord
--- @return boolean
function Utils.pointRectCollision(px, py, rx1, ry1, rx2, ry2)
    if px >= rx1 and py >= ry1 and px <= rx2 and py <= ry2 then
        return true
    else
        return false
    end
end

--- Normalize a Vector2. Usefull to calculate diagonal movement.
--- @param vx number Vector x value from 0 to 1
--- @param vy number Vector y value from 0 to 1
--- @return table
function Utils.normalizeVector2(vx, vy)
    local length = math.sqrt(vx ^ 2 + vy ^ 2)
    local normalizedX, normalizedY = 0, 0
    if length > 0 then
        normalizedX = vx / length
        normalizedY = vy / length
    end
    return { x = normalizedX, y = normalizedY }
end

--- Check if a table (as a list) contains a given vlaue
--- @param table table The table to check
--- @param value any The value to find
function Utils.tableContains(table, value)
    for i = 1, #table do
        if (table[i] == value) then
            return true
        end
    end
    return false
end

function Utils.tabelCount(table)
    local cnt = 0
    for k,v in pairs(table) do
        cnt = cnt + 1
    end
    return cnt
end

local random = math.random
function Utils:uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function Utils:sign(number)
  if number >= 0 then
     return 1
  elseif number < 0 then
     return -1
  end
end


function Utils:mid(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

function Utils:round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

--- https://easings.net/#easeInOutQuad
function Utils:easeInOutQuad(x)
    if x < 0.5 then
        return 2 * x * x
    else
        return 1 - (-2 * x + 2)^2 / 2
    end
end

return Utils
