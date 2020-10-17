include "config"
include "vec2"
include "animator"
include "world"
include "mcontroller"
include "activeItem"
include "updateable"

muzzle = {}
muzzle._flash = {}
muzzle._parts = {}
muzzle.inaccuracy = 0
muzzle.ownerEntityId = 0

function muzzle:init()
	local muzzleConfig = config.muzzle or {}
	for i,v in pairs(muzzleConfig) do
		self:addPart(v.part, v.offset)
	end
	self._flash = config.muzzleFlash or {animationStates = {}}
	self.ownerEntityId = activeItem.ownerEntityId()
end

function muzzle:flash()
	for i,v in pairs(self._flash.animationStates) do
		animator.setAnimationState(i,v)
	end
end

function muzzle:addPart(part, offset)
	self._parts[part] = vec2(offset or {0,0})
end

function muzzle:getPositions()
	local positions = {}
	for i,v in pairs(self._parts) do
		positions[i] = activeItem.handPosition(animator.transformPoint(v,i))
	end
	return positions
end

function muzzle:getItemPositions()
	local positions = {}
	for i,v in pairs(self._parts) do
		positions[i] = animator.transformPoint(v,i)
	end
	return positions
end

function muzzle:fireProjectile(projectileName, projectileConfig, damageMultiplier)
	local indiscriminateMode = status.statusProperty("indiscriminateMode")
	for i,v in pairs(self._parts) do
		-- world.spawnProjectile(`String` projectileName [arg1], `Vec2F` position [arg2], [`EntityId` sourceEntityId] [arg3], [`Vec2F` direction] [arg4], [`bool` trackSourceEntity] [arg5], [`Json` parameters] [arg6])

		local position = activeItem.handPosition(animator.transformPoint(v,i))
		local end_position = activeItem.handPosition(animator.transformPoint(v + vec2(1,0), i))

		--inaccuracy
		local direction = end_position - position
		if self.inaccuracy ~= 0 then
			local rand = math.random(math.floor(-self.inaccuracy * 100), math.ceil(self.inaccuracy * 100)) / 100
			direction = direction:rotate(math.rad(rand))
		end

		--damageMultiplier
		if type(projectileConfig) ~= "table" then
			projectileConfig = {}
		end

		projectileConfig.powerMultiplier = activeItem.ownerPowerMultiplier() * (damageMultiplier or 1)

		if indiscriminateMode then
			projectileConfig.damageTeam = { type = "indiscriminate" }
		end

		world.spawnProjectile(projectileName, position + mcontroller.position(), self.ownerEntityId, direction, false, projectileConfig)
	end
end

function muzzle:canFire()
	for i,v in pairs(self._parts) do
		local position = mcontroller.position()
		local end_position = activeItem.handPosition(animator.transformPoint(v, i)) + position
		if world.lineCollision(position, end_position) then
			return false
		end
	end
	return true
end

updateable:add("muzzle")