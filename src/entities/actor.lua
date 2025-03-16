local Entity = require 'src.entities.entity'
local Body = require 'src.components.body'
local Size = require 'src.components.size'
local actionComponents = require 'src.components.action'
local ActionController, Action = actionComponents[1], actionComponents[2]
-- local Texture = require 'src.components.texture'
-- local Control = require 'src.components.control'
-- local AnimationController = require 'src.components.animationController'

local Actor = Entity:extend()

function Actor:new(actions, collider)
    Actor.super.new(self)

    self.body = Body(Vector(64, 64), Vector(0, 0), 1.5)
    self.size = Size(16, 16)
    self.collider = collider

    local speed = 100
    -- local act1 = Action(function(dt, e) print('go right', e.id) e.body.acceleration = Vector(1, 0) * speed * dt e.actionController.cooldown = false end, 1, 'Go Right')
    -- local act2 = Action(function(dt, e) print('go down', e.id) e.body.acceleration = Vector(0, 1) * speed * dt e.actionController.cooldown = false end, 1, 'Go Down')
    -- local act3 = Action(function(dt, e) print('go right', e.id) e.body.acceleration = Vector(1, 0) * speed * dt e.actionController.cooldown = false end, 1, 'Go Right')
    -- local act4 = Action(function(dt, e) print('go down', e.id) e.body.acceleration = Vector( 0, 1) * speed * dt e.actionController.cooldown = false end, 1, 'Go Down')

    -- self.actionController = ActionController({ act1, act2, act3, act4 })
    self.actionController = ActionController(actions)

    -- Configure animation

    -- Configure state

    -- Configure controller
end

return Actor
