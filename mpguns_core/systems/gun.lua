include "config"
include "activeItem"
include "aim"
include "muzzle"
include "transforms"
include "animations"
include "animator"
include "arms"
include "sprites"
include "directory"
include "camera"
include "crosshair"

main = {}
main.config = {}
main.storage = {}
main.fireCooldown = 0
main.reloadLooping = false

function main:setupEvents()
	animations:addEvent("recoil", function() aim:recoil(self.config.recoil) end)
	animations:addEvent("reloadLoop", function() self.reloadLooping = true end)
	animations:addEvent("reload", function() self:reload() end)
	animations:addEvent("reload1", function() self:reload(1) end)
	animations:addEvent("eject", function() self:eject() end)
	animations:addEvent("load", function() self:load() end)
end

function main:init()
	self.config = {}

	if type(config.gun) == "string" then
		self.config = root.assetJson(directory(config.gun))
	else
		self.config = config.gun
	end
	aim.recoilRecovery = self.config.recoilRecovery

	sprites:load(config.sprites)

	self.storage = config.storage or {}
	self.storage.ammo = self.storage.ammo or self.config.magazineCapacity
	self.storage.loaded = self.storage.loaded or 0

	transforms:init()
	animations:init()
	self:animate("draw")
	self:setupEvents()
end

function main:update(dt, firemode, shift, moves)
	if self.fireCooldown > 0 then
		self.fireCooldown = math.max(self.fireCooldown - dt, 0)
	elseif self.storage.canLoad and self.storage.loaded ~= 1 then
		self:load()
		self.storage.canLoad = false
		self:save()
	end
	
	if firemode == "primary" and self.storage.loaded == 1 and self.fireCooldown == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) then
		if self.config.chamberEject then
			self:eject()
		else
			self.storage.loaded = 2
			self:save()
		end
		if self.config.chamberAutoLoad and self.storage.ammo > 0 then
			self.storage.canLoad = true
			self:save()
		end

		self:fireProjectile()
		self.fireCooldown = 60 / self.config.rpm

		if self.storage.ammo == 0 then
			self.storage.dry = true
			self:save()
		end

		self:animate("fire")
	end

	if self.reloadLooping and not animations:isAnyPlaying() then
		if self.storage.ammo < self.config.magazineCapacity then
			self:animate("reloadLoop")
		else
			self:animate("reloadLoopEnd")
			self.reloadLooping = false
		end
	else
		if ((shift and moves.up) or (self.storage.loaded ~= 1 and self.storage.ammo == 0)) and not animations:isAnyPlaying() then
			self:animate("reload")
		end
		if ((not shift and moves.up) or (self.storage.loaded ~= 1 and self.storage.ammo ~= 0)) and not animations:isAnyPlaying() then
			self:animate("load")
		end
	end


	camera.target = ((activeItem.ownerAimPosition() - mcontroller.position()) * vec2(self.config.aimRatio / 2)) + vec2(0, aim:getRecoil() * 0.125)
	muzzle.inaccuracy = self:getInaccuracy()
	crosshair.value = (muzzle.inaccuracy / math.max(self.config.movingInaccuracy, self.config.standingInaccuracy)) * 10
	item.setCount(math.max(self:ammoCount(), 1))
	animations:update(dt)
	transforms:reset()
	transforms:apply(animations:transforms())
	transforms:update(dt)

	aim:at(activeItem.ownerAimPosition())
	aim:update(dt)
end

function main:uninit()
	self:save()
end

function main:save()
	config.storage = self.storage
end

function main:reload(amount)
	if amount then
		self.storage.ammo = self.storage.ammo + amount
	else
		self.storage.ammo = self.config.magazineCapacity
	end
	self:save()
end

function main:animate(animationname)
	if self.storage.dry and animations:has(animationname.."_dry") then
		animations:play(animationname.."_dry")
	else
		animations:play(animationname)
	end
end

function main:isPlaying(animationname)
	if self.storage.dry and animations:has(animationname.."_dry") then
		return animations:isPlaying(animationname.."_dry")
	else
		return animations:isPlaying(animationname)
	end
end

function main:getInaccuracy()
	local vel = math.max(math.abs(mcontroller.xVelocity()), math.abs(mcontroller.yVelocity() + 1.27))
	local movingRatio = math.min(vel / 14, 1)

	local acc = (self.config.movingInaccuracy * movingRatio) + (self.config.standingInaccuracy * (1 - movingRatio))

	if mcontroller.crouching() then
		return acc * self.config.crouchInaccuracyMultiplier
	else
		return acc
	end
end

function main:ammoCount()
	local ammo = self.storage.ammo
	if self.storage.loaded and self.storage.loaded == 1 then
		ammo = ammo + 1
	end
	return ammo
end

function main:eject()
	if self.storage.loaded > 0 and self.config.casingParticle then
		animator.burstParticleEmitter(self.config.casingParticle)
	end
	self.storage.loaded = 0
	self:save()
end

function main:load()
	if self.storage.ammo <= 0 then return end
	self.storage.loaded = 1
	self.storage.ammo = self.storage.ammo - 1
	self.storage.dry = false
	self:save()
end

function main:fireProjectile()
	muzzle:fireProjectile(self.config.projectileName, self.config.projectileConfig)
end