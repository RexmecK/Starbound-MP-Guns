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


for i,v in pairs(config.spriteAnchors or {}) do
    events:add("sprite.load."..v, 
        function(sprite)
            setOffsets(v, sprite)
        end
    )
end
