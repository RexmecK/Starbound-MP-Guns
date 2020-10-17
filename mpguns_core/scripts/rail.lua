include "vec2"
include "tableutil"
include "animator"
include "rails"

rail = {}
rail.config = {}

function rail:new(config)
    local n = table.copy(self)
    n.config = config
	return n
end

function rail:init()
    self:resetScale()
end

function rail:update(dt)
    --world.debugPoint(mcontroller.position() + activeItem.handPosition(animator.transformPoint({0,0}, self.config.part)), "pink")
end

function rail:uninit()

end

function rail:setImage(image)
    if not self.config.part then return end
    animator.setPartTag(self.config.part, "partImage", image)
end

function rail:setImageFullbright(image)
    if not self.config.partFullbright then return end
    animator.setPartTag(self.config.partFullbright, "partImage", image)
end

function rail:resetScale()
    scale = 1
    if self.config.transform and self.config.part then
        animator.resetTransformationGroup(self.config.transform)
        animator.scaleTransformationGroup(
            self.config.transform, 
            vec2(1,1) / (animator.transformPoint({1,0.875}, self.config.part) - animator.transformPoint({0,0}, self.config.part)), 
            animator.partProperty(self.config.part, "offset") or {0,0}
        )
    end
end

function rail:setScale(scale)
    self:resetScale()
    scale = scale or 1
    if self.config.transform and self.config.part then
        animator.scaleTransformationGroup(
            self.config.transform, 
            vec2(scale), 
            animator.partProperty(self.config.part, "offset") or {0,0}
        )
    end
end

function rail:applyStats(stats)
    rails:applyStats(stats)
end