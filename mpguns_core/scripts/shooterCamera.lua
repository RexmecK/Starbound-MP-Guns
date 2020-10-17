include "updateable"
include "vec2"
include "aim"
include "camera"


shooterCamera = {}
shooterCamera.targetCameraRecoil = vec2(0,0)
shooterCamera.currentCameraRecoil = vec2(0,0)
shooterCamera.aimRatio = vec2(0,0)
shooterCamera.lerpRatio = 0.25
shooterCamera.shake = 0

function shooterCamera:init()

end

function shooterCamera:update()
	self.currentCameraRecoil = self.currentCameraRecoil:lerp(self.targetCameraRecoil, self.lerpRatio)
	if self.shake > 0 then
		self.currentCameraRecoil[1] = math.sin(os.clock() * 3000) * 0.03
    end
    
	camera.target = self:getAimCamera() + self.currentCameraRecoil
end


function shooterCamera:getAimCamera()
	return world.distance(activeItem.ownerAimPosition(), mcontroller.position()) * vec2(self.aimRatio / 2)
end

function shooterCamera:getTargetAim()
	return activeItem.ownerAimPosition()
end



updateable:add("shooterCamera")