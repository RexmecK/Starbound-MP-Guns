include "config"
include "vec2"

globalRecoil = {}
globalRecoil.recoveryLerp = 0.125
globalRecoil.offset = vec2(0,0)
globalRecoil.offsetTarget = vec2(0,0)

local function lerp(a,b,r)
    return a + (b - a) * r
end

function globalRecoil:init()

end

function globalRecoil:update()
    self.offsetTarget = self.offsetTarget:lerp(self.offset, 0.25)
    self.offsetTarget.x = math.max(self.offsetTarget.x, -0.5)
    self.offset = self.offset:lerp({0,0}, self.recoveryLerp)
	if animator.hasTransformationGroup("globalRecoil") then
		animator.resetTransformationGroup("globalRecoil") 
        animator.translateTransformationGroup("globalRecoil", self.offsetTarget)
    end
end

updateable:add("globalRecoil")