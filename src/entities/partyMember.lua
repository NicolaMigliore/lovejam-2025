local Entity = require 'src.entities.entity'
local Body = require 'src.components.body'
local AnimationController = require 'src.components.animationController'

local PartyMember = Entity:extend()

local idleSpritesFile = 'assets/party-idle.png'
local classes = {
    rogue = { race = 'goblin', maxHp = 5, hp = 5, dmg = 4, huger = 1, idleFramesRow = 1 },
    warrior = { race = 'orc', maxHp = 10, hp = 10, dmg = 4, huger = 5, idleFramesRow = 2 },
    mage = { race = 'elf', maxHp = 10, hp = 10, dmg = 4, huger = 3, idleFramesRow = 3 },
    archer = { race = 'human', maxHp = 10, hp = 10, dmg = 4, huger = 3, idleFramesRow = 4 },
}

function PartyMember:new(class)
    PartyMember.super.new(self)

    -- data
    local classItem = classes[class]
    self.class = class
    self.race = classItem.race
    self.maxHp = classItem.maxHp
    self.hp = classItem.hp
    self.dmg = classItem.dmg
    self.hunger = classItem.huger

    -- setup animations
    self.image = love.graphics.newImage(idleSpritesFile)
    local animGrid = Anim8.newGrid(32, 32, self.image:getDimensions())
    local durationMod = math.random() * .05
    self.animations = {
        idle = Anim8.newAnimation(animGrid('1-4', classItem.idleFramesRow), .1 + durationMod)
    }
    self.animationController = AnimationController(self.image, self.animations, 'idle')

    -- other components
    self.body = Body(Vector(-100, -100))
end

return PartyMember
