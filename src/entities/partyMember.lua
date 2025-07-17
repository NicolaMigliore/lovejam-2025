local Entity = require 'src.entities.entity'
local Body = require 'src.components.body'
local Size = require 'src.components.size'
local AnimationController = require 'src.components.animationController'

local PartyMember = Entity:extend()

local idleSpritesFile = 'assets/party-idle.png'
local classes = {
    rogue = { race = 'goblin', maxHp = 5, hp = 5, dmg = 4, hunger = 1, cost = 4, idleFramesRow = 1 },
    archer = { race = 'human', maxHp = 10, hp = 10, dmg = 4, hunger = 3, cost = 6, idleFramesRow = 4 },
    mage = { race = 'elf', maxHp = 10, hp = 10, dmg = 4, hunger = 3, cost = 8, idleFramesRow = 3 },
    warrior = { race = 'orc', maxHp = 10, hp = 10, dmg = 4, hunger = 5, cost = 10, idleFramesRow = 2 },
}
local names = {
    rogue = { 'Snarl', 'Kalp', 'Rangr', 'Trisp', 'Limr', 'Skraak'},
    warrior = { 'Gorn', 'Slugn', 'Ragnuk', 'Lugnup', 'Truk', 'Snagmu'},
    mage = { 'Kaal-Sin', 'Servin', 'Alavar', 'Stelfum', 'Faersy', 'Sfabeen'},
    archer = { 'Gahal', 'Marsel', 'Istia', 'Franler', 'Meeria', 'Laureet'},
}

function PartyMember:new(class, x, y)
    PartyMember.super.new(self)

    -- data
    local classItem = classes[class]
    self.class = class
    self.race = classItem.race
    self.maxHp = classItem.maxHp
    self.hp = classItem.hp
    self.dmg = classItem.dmg
    self.hunger = classItem.hunger
    self.name = names[class][love.math.random(#names[class])]
    self.cost = classItem.cost

    -- setup animations
    self.image = love.graphics.newImage(idleSpritesFile)
    local animGrid = Anim8.newGrid(32, 32, self.image:getDimensions())
    local durationMod = math.random() * .05
    self.animations = {
        -- idle = Anim8.newAnimation(animGrid('1-4', classItem.idleFramesRow), .1 + durationMod)
        idle = self:makeAnimation('idle')
    }
    self.animationController = AnimationController(self.image, self.animations, 'idle')

    -- other components
    self.body = Body(Vector(x, y))
    self.size = Size(250, 250)
end

function PartyMember:makeAnimation(animName)
    local animation
    local animGrid = Anim8.newGrid(32, 32, self.image:getDimensions())
    local durationMod = math.random() * .05
    local classItem = classes[self.class]
    if animName == 'idle' then
        animation = Anim8.newAnimation(animGrid('1-4', classItem.idleFramesRow), .1 + durationMod)
    end
    return animation
end

return PartyMember
