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
include "events"
include "mpguns"
include "skin"
include "vec2"

main = {}
main.config = {}
main.storage = {}
main.fireCooldown = 0
main.burstCooldown = 0
main.queuedFire = 0
main.reloadLooping = false
main.overridenAnimates = {}

function main:setupEvents()
	animations:addEvent("recoil", function() 
			local angle = self.config.recoil
			local recoilMultiplier = 1
			if not mpguns:getPreference("cameraRecoil") then
				recoilMultiplier = recoilMultiplier * 2
			end
			
			if self.config.crouchRecoilMultiplier and mcontroller.crouching() then 
				recoilMultiplier = recoilMultiplier * self.config.crouchRecoilMultiplier
			end
			
			angle = angle * recoilMultiplier

			if self.config.velocityRecoil then 
				mcontroller.addMomentum(vec2(self.config.velocityRecoil):rotate(aim:angle()) * vec2(aim.facing,1) * recoilMultiplier)
			end

			aim:recoil(angle)
		end
	)
	animations:addEvent("reloadLoop", function() self.reloadLooping = true end)
	animations:addEvent("reload", function() self:reload() end)
	animations:addEvent("reload1", function() self:reload(1) end)
	animations:addEvent("eject", function() self:eject() end)
	animations:addEvent("load", function() self:load() end)
	animations:addEvent("checkload", function() if self.storage.loaded ~=1 then self:load() end end)
	animations:addEvent("unload", function() self:unload() end)
	animations:addEvent("casing", function() self:casing() end)
end

function main:init()
	self.config = {}

	if type(config.gun) == "string" then
		self.config = root.assetJson(directory(config.gun))
	else
		self.config = config.gun
	end
	if self.config.projectileConfig then
		if type(self.config.projectileConfig) == "string" then
			self.config.projectileConfig = root.assetJson(directory(self.config.projectileConfig))
		end
	else
		self.config.projectileConfig = {}
	end

	if self.config.knockback then
		self.config.projectileConfig.knockback = self.config.knockback
	end

	aim.recoilRecovery = self.config.recoilRecovery or 8
	aim.recoilResponse = self.config.recoilResponse or 1

	sprites:load(config.sprites)
	skin:init()

	self.storage = config.storage or {}
	self.storage.ammo = self.storage.ammo or self.config.magazineCapacity
	self.storage.loaded = self.storage.loaded or 0
	if type(self.storage.dry) == "boolean" and not self.storage.dry then
		self.storage.dry = false
	else
		self.storage.dry = skin
	end

	if config.altscript then
		pcall(function() require(directory(config.altscript, modPath.."altscripts/", ".lua")) end)
	end

	if config.additionnalScripts then
		for i,v in pairs(config.additionnalScripts) do
			pcall(function() require(directory(v, modPath.."scripts/", ".lua")) end)
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

function main:update(...)
	local dt = ({...})[1]


	if alt and alt.update then
		alt:update(...)
	end

	self:updateTimers(...)

	self:updateFireControls(...)
	self:updateFire(...)

	self:updateReloadControls(...)
	self:updateReload(...)

	--gameplay mechanics
	camera.target = self:getAimCamera() + self:getRecoilCamera()
	muzzle.inaccuracy = self:getInaccuracy()
	crosshair.value = self:getCrosshairValue()
	item.setCount(math.max(self:ammoCount(), 1))

	animations:update(dt)
	if animations:isAnyPlaying() then
		transforms:reset()
		transforms:apply(animations:transforms())
	elseif transforms.applied then 
		transforms:reset()
	end
	transforms:update(dt)

	aim:at(self:getTargetAim())
	aim:update(dt)
end

function main:uninit()
	if alt and alt.uninit then
		alt:uninit()
	end

	self:save()
	item.setCount(1)
end

function main:save()
	config.storage = self.storage
end

function main:updateTimers(dt)
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
end

--Aiming Mechanics

function main:getAimCamera()
	if not mpguns:getPreference("cameraAim") then
		return vec2(0,0)
	end
	return world.distance(activeItem.ownerAimPosition(), mcontroller.position()) * vec2(self.config.aimRatio / 2)
end

function main:getRecoilCamera()
	if not mpguns:getPreference("cameraRecoil") then
		return vec2(0,0)
	end
	return vec2(0, (aim:getRecoil() * 0.125))
end

function main:getTargetAim()
	return activeItem.ownerAimPosition()
end

--UI mechanics

function main:getCrosshairValue()
	return ((muzzle.inaccuracy + math.abs(aim:getRecoil())) / math.max(self.config.movingInaccuracy, self.config.standingInaccuracy)) * 25
end

--firing mechanics

function main:updateFireControls(dt, firemode, shift, moves)
	--primary firing
	if firemode == "primary" and muzzle:canFire() and (self.storage.ammo > 0 or self.storage.loaded == 1) and self.queuedFire == 0 and self.fireCooldown == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) then
		if self.config.firemode == "auto" then
			self.queuedFire = 1
		elseif self.config.firemode == "burst" and self.burstCooldown == 0 then
			self.queuedFire = 3
			self.burstCooldown = self.config.burstCooldown or 0.5
		elseif self.config.firemode == "semi" and update_lastInfo[2] ~= "primary" then
			self.queuedFire = 1
		end
	end
end

function main:updateFire(dt)
	if self.queuedFire > 0 and self.fireCooldown == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) and muzzle:canFire() then
		local result = self:fire()
		if result == 1 then
			events:fire("fire")
			self.queuedFire = self.queuedFire - 1
		elseif result == 2 then
			self.queuedFire = 0
		end
	elseif (self.queuedFire > 0 and self.storage.ammo <= 0 and self.storage.loaded ~= 1) or self:isPlaying("load") or self:isPlaying("reload") then
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

		if self.storage.ammo == 0 or self.config.chamberDryIfFire then
			self.storage.dry = true
			self:save()
		end

		self:animate("fire")
		return 1
	elseif self.storage.loaded == 2 then
		return 2
	else
		return 0
	end
end

function main:fireProjectile()
	muzzle.damageMultiplier = (self.config.damageMultiplier or 1) * activeItem.ownerPowerMultiplier()
	for i=1,self.config.projectileCount or 1 do
		muzzle:fireProjectile(self.config.projectileName, self.config.projectileConfig)
	end
end

function main:getInaccuracy()
	local vel = math.max(math.abs(mcontroller.xVelocity()), math.abs(mcontroller.yVelocity() + 1.27))
	local movingRatio = math.min(vel / 14, 1)

	local acc = (self.config.movingInaccuracy * movingRatio) + (self.config.standingInaccuracy * (1 - movingRatio))

	if mcontroller.crouching() and self.config.crouchInaccuracyMultiplier then
		return acc * self.config.crouchInaccuracyMultiplier
	else
		return acc
	end
end

--ammo mechanics

function main:updateReloadControls(dt, firemode, shift, moves)
	if self.reloadLooping and firemode ~= "none" then
		self.interuptReload = true
	end
	if animations:isAnyPlaying() then return end
	if not self.reloadLooping then
		if ((shift and moves.up) or (self.storage.loaded ~= 1 and self.storage.ammo == 0 and mpguns:getPreference("autoreload"))) and (self.storage.ammo < self.config.magazineCapacity or self.config.magazineCapacity == 0) and firemode == "none" then
			events:fire("reload")
			if not animations:isAnyPlaying() then
				self:animate("reload")
			end
		end
		
		if ((not shift and moves.up and not mpguns:getPreference("disableW")) or (self.storage.loaded ~= 1 and self.storage.ammo ~= 0 and mpguns:getPreference("autoload"))) and not self.config.disallowAnimationLoad then
			events:fire("load")
			if not animations:isAnyPlaying() then
				self:animate("load")
			end
		end
	end
end

function main:updateReload(dt)
	if self.reloadLooping and not animations:isAnyPlaying() then
		if self.storage.ammo < self.config.magazineCapacity and not self.interuptReload then
			self:animate("reloadLoop")
		else
			self:animate("reloadLoopEnd")
			self.reloadLooping = false
			self.interuptReload = false
		end
	end
end

function main:reload(amount)
	if amount then
		self.storage.ammo = self.storage.ammo + amount
	else
		self.storage.ammo = self.config.magazineCapacity
	end
	self:save()
end

function main:ammoCount()
	local ammo = self.storage.ammo
	if self.storage.loaded and self.storage.loaded == 1 then
		ammo = ammo + 1
	end
	return ammo
end

function main:eject()
	if self.storage.loaded > 0 and not self.config.noCasingEject then
		self:casing()
	end
	self.storage.loaded = 0
	self:save()
end

function main:casing()
	if mpguns:getPreference("disableCasings") then return end

	if self.config.casingParticle then
		animator.burstParticleEmitter(self.config.casingParticle)
	end
	if self.config.casing and self.config.casing.type and self.config.casing.part then
		local casingConfig = root.assetJson(directory(self.config.casing.type, "/mpguns_core/casingConfigs/", ".config"))
		local pos = activeItem.handPosition(animator.transformPoint(self.config.casing.offset or {0,0},self.config.casing.part)) + mcontroller.position()

		local position = activeItem.handPosition(animator.transformPoint(self.config.casing.offset or {0,0},self.config.casing.part))
		local end_position = activeItem.handPosition(animator.transformPoint((self.config.casing.offset or {0,0}) + vec2(0,1),self.config.casing.part))
		local angle = (end_position - position):angle()

		casingConfig.parameters.ownerId = activeItem.ownerEntityId()

		for i=1,self.config.casing.count or 1 do
			casingConfig.parameters.velocity = vec2(self.config.casing.velocity or casingConfig.parameters.velocity):rotate((-angle * aim.facing) + math.rad((math.random(450,900) - 450) / 10)) * vec2(aim.facing, 1)
			world.spawnMonster(casingConfig.type, pos, casingConfig.parameters)
		end
	end
end

function main:load()
	if self.storage.loaded > 0 then
		main:eject()
	end
	self.storage.dry = false
	if self.storage.ammo <= 0 then return end
	self.storage.loaded = 1
	self.storage.ammo = self.storage.ammo - 1
	self:save()
end

function main:unload()
	if self.storage.ammo <= 0 then return end
	self.storage.ammo = 0
	self:save()
end

--animation mechanics

function main:animate(animationname)
	if self.overridenAnimates[animationname] and (animations:has(self.overridenAnimates[animationname]) or animations:has(self.overridenAnimates[animationname].."_dry")) then
		animationname = self.overridenAnimates[animationname]
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
	self.overridenAnimates[animationname] = newanimationname
end

function main:isPlaying(animationname)
	if self.overridenAnimates[animationname] and (animations:has(self.overridenAnimates[animationname]) or animations:has(self.overridenAnimates[animationname].."_dry")) then
		animationname = self.overridenAnimates[animationname]
	end

	if self.storage.dry and animations:has(animationname.."_dry") then
		return animations:isPlaying(animationname.."_dry")
	else
		return animations:isPlaying(animationname)
	end
end
