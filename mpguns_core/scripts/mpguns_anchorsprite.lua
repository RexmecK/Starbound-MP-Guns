include "events"
include "animator"
include "updateable"
include "vec2"
include "mcontroller"
include "activeItem"

local function setOffsets(transform, sprite)
    local rect1 = root.nonEmptyRegion(sprite)
    if rect1 and animator.hasTransformationGroup(transform) then
        sb.logInfo("load : "..transform.."; SET ["..rect1[1]..", "..rect1[2].."]")
        animator.resetTransformationGroup(transform)
        animator.translateTransformationGroup(transform, {rect1[1] * 0.125, rect1[2] * 0.125})
    end
end

events:add("sprite.load.muzzleOffset", 
    function(sprite)
        setOffsets("muzzleOffset", sprite)
    end
)

events:add("sprite.load.casingOffset", 
    function(sprite)
        setOffsets("casingOffset", sprite)
    end
)

events:add("sprite.load.magOffset", 
    function(sprite)
        setOffsets("magOffset", sprite)
    end
)

MPGUNSANCHORDEBUG = {}


local function debugPart(part, color)
        world.debugPoint(mcontroller.position() + activeItem.handPosition(animator.transformPoint({0,0}, part)), color) 
end

function MPGUNSANCHORDEBUG:update()
    debugPart("muzzlePosition", "red")
    debugPart("casingPosition", "green")
    debugPart("magPosition", "blue")
end

--updateable:add("MPGUNSANCHORDEBUG")