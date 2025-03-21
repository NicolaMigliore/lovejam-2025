local AnimationController = Object:extend()

function AnimationController:new(image, animations, activeAnimName)
    local animationName = activeAnimName or 'idle'
    self.image = image
    self.animations = animations
    self.activeAnimationName = animationName
    self.activeAnimation = self.animations[self.activeAnimationName]
end

function AnimationController:setAnimation(animationName)
    self.activeAnimationName = animationName
    self.activeAnimation = self.animations[self.activeAnimationName]
end

--- Returns the current animation name
function AnimationController:getCurrent()
    return self.activeAnimationName
end

return AnimationController