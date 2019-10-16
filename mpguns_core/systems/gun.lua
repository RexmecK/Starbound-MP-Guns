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
main.burstCooldown = 0
main.queuedFire = 0
main.reloadLooping = false

function main:setupEvents()
	animations:addEvent("recoil", function() aim:recoil(self.config.recoil) end)
	animations:addEvent("reloadLoop", function() self.reloadLooping = true end)
	animations:addEvent("reload", function() self:reload() end)
	animations:addEvent("reload1", function() self:reload(1) end)
	animations:addEvent("eject", function() self:eject() end)
	animations:addEvent("load", function() self:load() end)
	animations:addEvent("unload", function() self:unload() end)
end

function main:init()
	self.config = {}

	if type(config.gun) == "string" then
		self.config = root.assetJson(directory(config.gun))
	else
		self.config = config.gun
	end
	aim.recoilRecovery = self.config.recoilRecovery or 8
	aim.recoilResponse = self.config.recoilResponse or 1

	sprites:load(config.sprites)

	self.storage = config.storage or {}
	self.storage.ammo = self.storage.ammo or self.config.magazineCapacity
	self.storage.loaded = self.storage.loaded or 0
	
	if type(self.storage.dry) == "boolean" and not self.storage.dry then
		self.storage.dry = false
	else
		self.storage.dry = true
	end

	if config.altscript then
		require(directory(config.altscript, modPath.."altscripts/", ".lua"))
	end

	if config.additionnalScripts then
		for i,v in pairs(config.additionnalScripts) do
			require(directory(v, modPath.."scripts/", ".lua"))
		end
	end

	if alt and alt.init then
		alt:init()
	end

	transforms:init()
	animations:init()
	self:animate("draw")
	self:setupEvents()
end

function main:update(dt, firemode, shift, moves)
	if alt and alt.update then
		alt:update(dt, firemode, shift, moves)
	end

	if self.fireCooldown > 0 then
		self.fireCooldown = math.max(self.fireCooldown - dt, 0)
	elseif self.storage.canLoad and self.storage.loaded ~= 1 then
		self:load()
		self.storage.canLoad = false
		self:save()
	end

	if self.burstCooldown > 0 and self.fireCooldown == 0 then
		self.burstCooldown = math.max(self.burstCooldown - dt, 0)
	end

	if firemode == "primary" and (self.storage.ammo > 0 or self.storage.loaded == 1) and self.queuedFire == 0 and self.fireCooldown == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) then
		if self.config.firemode == "auto" then
			self.queuedFire = 1
		elseif self.config.firemode == "burst" and self.burstCooldown == 0 then
			self.queuedFire = 3
			self.burstCooldown = 0.3
		elseif self.config.firemode == "semi" and update_lastInfo[2] ~= "primary" then
			self.queuedFire = 1
		end
	end
	self:updateFire(dt)

	if self.reloadLooping and firemode ~= "none" then
		self.interuptReload = true
	end

	if self.reloadLooping and not animations:isAnyPlaying() then
		if self.storage.ammo < self.config.magazineCapacity and not self.interuptReload then
			self:animate("reloadLoop")
		else
			self:animate("reloadLoopEnd")
			self.reloadLooping = false
			self.interuptReload = false
		end
	else
		if ((shift and moves.up) or (self.storage.loaded ~= 1 and self.storage.ammo == 0)) and (self.storage.ammo < self.config.magazineCapacity or self.config.magazineCapacity == 0) and firemode == "none" and not animations:isAnyPlaying() then
			self:animate("reload")
		end
		if ((not shift and moves.up) or (self.storage.loaded ~= 1 and self.storage.ammo ~= 0)) and not animations:isAnyPlaying() then
			self:animate("load")
		end
	end


	camera.target = ((activeItem.ownerAimPosition() - mcontroller.position()) * vec2(self.config.aimRatio / 2)) + vec2(0, aim:getRecoil() * 0.03125)
	muzzle.inaccuracy = self:getInaccuracy()
	crosshair.value = (muzzle.inaccuracy / math.max(self.config.movingInaccuracy, self.config.standingInaccuracy)) * 10
	item.setCount(math.max(self:ammoCount(), 1))
	animations:update(dt)
	if animations:isAnyPlaying() then
		transforms:reset()
		transforms:apply(animations:transforms())
	end
	transforms:update(dt)

	aim:at(activeItem.ownerAimPosition())
	aim:update(dt)
end

function main:uninit()
	if alt and alt.uninit then
		alt:uninit()
	end

	self:save()
	item.setCount(1)
end

function main:updateFire(dt)
	if self.queuedFire > 0 and self.fireCooldown == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) then
		if self:fire() then
			self.queuedFire = self.queuedFire - 1
		end
	elseif self.queuedFire > 0 and self.storage.ammo <= 0 and self.storage.loaded ~= 1 then
		self.queuedFire = 0
	end
end

function main:fire()
	if self.storage.loaded == 1 then
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
		return true
	else
		return false
	end
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

main.overridenAnimates = {

}

function main:animate(animationname)
	if self.overridenAnimates[animationname] then
		animationname = self.overrideAnimates[animationname]
	end

	animations:stop(animationname)
	animations:stop(animationname.."_dry")
	if self.storage.dry and animations:has(animationname.."_dry") then
		animations:play(animationname.."_dry")
	else
		animations:play(animationname)
	end
end

function main:overrideAnimate(animationname, newanimationname) --temporary animation replacement
	animations:stop(animationname)
	animations:stop(animationname.."_dry")
	self.overrideAnimate[animationname] = newanimationname
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
	if self.storage.loaded > 0 then
		main:eject()
	end
	if self.storage.ammo <= 0 then return end
	self.storage.loaded = 1
	self.storage.ammo = self.storage.ammo - 1
	self.storage.dry = false
	self:save()
end

function main:unload()
	if self.storage.ammo <= 0 then return end
	self.storage.ammo = 0
	self:save()
end

function main:fireProjectile()
	for i=1,self.config.projectileCount or 1 do
		muzzle:fireProjectile(self.config.projectileName, self.config.projectileConfig)
	end
end