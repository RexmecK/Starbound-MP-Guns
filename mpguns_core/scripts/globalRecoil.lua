include "config"
include "vec2"
include "aim"

globalRecoil = {}
globalRecoil.recoveryLerp = 0.125
globalRecoil.offset = vec2(0,0)
globalRecoil.offsetTarget = vec2(0,0)
globalRecoil.shoulderbob = false

local function lerp(a,b,r)
    return a + (b - a) * r
end

function globalRecoil:init()

end

function globalRecoil:update()
    self.offsetTarget = self.offsetTarget:lerp(self.offset, 0.25)
    self.offsetTarget.x = math.max(self.offsetTarget.x, -0.5)
    self.offset = self.offset:lerp({0,0}, self.recoveryLerp)
    local target = {0,0}
    if self.shoulderbob then
        target = {
            self.offsetTarget.x + math.max(-0.25 * (aim:angle() / math.rad(90)), 0),
            -0.5 * (aim:angle() / math.rad(90))
        }
    else
        target = self.offsetTarget
    end
    if self.vanillaRecoil then
        if target[1] < -0.0625 then
            activeItem.setRecoil(true)
        else
            activeItem.setRecoil(false)
        end
	elseif animator.hasTransformationGroup("globalRecoil") then
		animator.resetTransformationGroup("globalRecoil") 
        animator.translateTransformationGroup("globalRecoil", target)
    end
end

updateable:add("globalRecoil")