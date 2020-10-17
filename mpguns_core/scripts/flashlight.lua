include "updateable"
include "animator"
include "vec2"

flashlight = {}
flashlight.toggled = false
flashlight.anchored = false


function flashlight:update()
    if self.anchored and animator.hasTranformationGroup("flashlight") then
        animator.resetTransformationGroup("flashlight")
        local a = animator.transformPoint({0,0}, self.anchored[1])
        local b = animator.transformPoint({1,0}, self.anchored[1])
        animator.rotateTransformationGroup("flashlight", (b-a):angle())
        animator.translateTransformationGroup("flashlight", a)
    end
end

function flashlight:uninit()
    self.toggled = not self.toggled
    animator.setLightActive("flashlight", false)
end

function flashlight:anchor(partName, offset)
    self.anchored = {partName, offset or {0,0}}
end

function flashlight:unanchor(partName, offset)
    animator.setLightActive("flashlight", false)
    self.anchored = false
end

function flashlight:toggle()
    self.toggled = not self.toggled
    animator.setLightActive("flashlight", self.toggled)
end


updateable:add("flashlight")