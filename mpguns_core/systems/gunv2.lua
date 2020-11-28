include "config"
include "activeItem"
include "aim"
include "muzzle"
include "transforms"
include "animations"
include "animator"
include "sprites"
include "directory"
include "crosshair"
include "events"
include "mpguns"
include "skin"
include "vec2"
include "globalRecoil"
include "altarms"
include "magazine"
include "timers"
include "rails"
include "shooterCamera"
include "stats"

main = {}
main.config = {}
main.storage = {}
main.fireCooldown = 0
main.burstCooldown = 0
main.queuedFire = 0
main.reloadLooping = false
main.overridenAnimates = {}
main.damageMultiplier = 1
main.appliedStats = false

function main:setupEvents()
	animations:addEvent("recoil", 
		function() 
			self:recoil()
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
	animations:addEvent("dropmag", function() magazine:dropEffect() end)
end

function main:init()
	globalRecoil.vanillaRecoil = true
	self.noFlexArms = true
	altarms:init()

	self.config = {}
	setmetatable(self.config,
		{
			__newindex = function(t, key, value)
				stats[key] = value
			end,
			__index = function(t, key)
				return stats[key]
			end
		}
	)
	self:initData()
	self:refreshData()

	self.storage = config.storage or {}
	self.storage.loaded = self.storage.loaded or 0

	if type(self.storage.dry) == "boolean" and not self.storage.dry then
		self.storage.dry = false
	else
		self.storage.dry = true
	end

	self:loadOtherScripts()

	local confanimation = config:getAnimation()
    transforms:addCustom(
        "armRotation", 
            (confanimation.transformationGroups.armRotation or {}).transform or {rotation = 0}, 
        function(tr)
	        aim.offset = tr.rotation or 0
        end
	)
	
	transforms:init()
	animations:init()
	globalRecoil:init()
	self:animate("draw")
	self:setupEvents()
end

function main:loadOtherScripts()
	events:fire("loadOtherScripts")

	if config.altscript then
		pcall(function() require(directory(config.altscript, modPath.."altscripts/", ".lua")) end)
	end

	local additionalScripts = config.additionalScripts or config.additionnalScripts
	if additionalScripts then
		for i,v in pairs(additionalScripts) do
			--sb.logInfo(v)
			local s, e = pcall(function() require(directory(v, modPath.."scripts/", ".lua")) end)
			if not s then
				sb.logError(e)
			end
		end
	end

	if alt and alt.init then
		alt:init()
	end
end

local defaultStats = {
	damageMultiplier = 1,
	knockback = 0,
	magazineCapacity = 30,
	recoil = 4,
	recoilRecovery = 2,
	recoilResponse = 2,
	burstCooldown = 0.5,
	armRecoil = 0.2,
	armRecoilRecovery = 4,
	movingInaccuracy = 5,
	standingInaccuracy = 0.5,
	crouchInaccuracyMultiplier = 0.5,
	aimRatio = 0.05,
	rpm = 0.05,
	velocityRecoil = vec2(0,0)
}

function main:initData()
	if type(config.gun) == "string" then
		self.gunConfig = root.assetJson(directory(config.gun))
	else
		self.gunConfig = config.gun
	end

	local statConfig = config.stats or defaultStats
	for i,v in pairs(defaultStats) do
		local t = type(self.gunConfig[i])
		local t2 = type(v)
		if t == t2 then
			if t2 == "table" then
				stats[i] = vec2(statConfig[i])
			else
				stats[i] = self.gunConfig[i]
			end
		else
			stats[i] = v
		end
	end

	timers:create("fireCooldown", 60 / (stats.rpm - 1))
	timers:create("burstCooldown", stats.burstCooldown or 0.5)


	if self.gunConfig.projectileConfig then
		if type(self.gunConfig.projectileConfig) == "string" then
			self.gunConfig.projectileConfig = root.assetJson(directory(self.gunConfig.projectileConfig))
		end
	else
		self.gunConfig.projectileConfig = {}
	end

	events:fire("initData")
end

function main:refreshData()
	magazine.capacity = stats.magazineCapacity
	timers:setReset("fireCooldown", 60 / (stats.rpm))
	timers:setReset("burstCooldown", stats.burstCooldown or 0.5)

	if not mpguns:getPreference("cameraAim") then
		shooterCamera.aimRatio = 0
	else
		shooterCamera.aimRatio = stats.aimRatio
	end

	if stats.knockback then
		self.gunConfig.projectileConfig.knockback = stats.knockback
	end

	self.damageMultiplier = (stats.damageMultiplier or 1)
	aim.recoilRecovery = stats.recoilRecovery or 8
	aim.recoilResponse = stats.recoilResponse or 1
	globalRecoil.recoveryLerp = 1 / (stats.armRecoilRecovery or stats.recoilRecovery or 4)
end

local transformUpdateTick = 0

function main:update(...)
	local dt = ({...})[1]

	if alt and alt.update then
		alt:update(...)
	end

	self:refreshData()

	if timers:get("fireCooldown") == 0 and self.storage.canLoad and self.storage.loaded ~= 1 then
		self:load()
		self.storage.canLoad = false
		self:save()
	end

	self:updateFireControls(...)
	self:updateFire(...)

	self:updateReloadControls(...)
	self:updateReload(...)

	--gameplay mechanics

	if mpguns:getPreference("cameraRecoil") then
		shooterCamera.targetCameraRecoil = vec2(0, (aim:getRecoil() * 0.25))
		shooterCamera.shake = aim:getRecoil()
	end
	
	muzzle.inaccuracy = self:getInaccuracy()
	crosshair.value = self:getCrosshairValue()
	item.setCount(math.max(self:ammoCount(), 1))

	if mpguns:getPreference("smoothAnimations") then
		animations:update(dt)
		if animations:isAnyPlaying() then
			transforms:reset()
			transforms:apply(animations:transforms())
		end
		transforms:update(dt)
	else
		animations:update(dt)
		if animations:isAnyPlaying() and transformUpdateTick <= 0 then
			transforms:reset()
			transforms:apply(animations:transforms())
			transformUpdateTick = 2
		elseif transformUpdateTick > 0 then
			transformUpdateTick = transformUpdateTick - 1
		elseif not animations:isAnyPlaying() and transformUpdateTick == 0 then
			transforms:reset()
			transforms:apply(animations:transforms())
			transformUpdateTick = -1
		end
		transforms:update(dt)
	end

	aim:at(self:getTargetAim())
	aim:update(dt)

	if self.noFlexArms then
		altarms:update(...)
	end
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

--Aiming Mechanics

function main:getTargetAim()
	return activeItem.ownerAimPosition()
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

function main:recoil()
	local angle = self.config.recoil
	local armRecoil = self.config.armRecoil or 0
	local recoilMultiplier = 1
	
	if self.config.crouchRecoilMultiplier and mcontroller.crouching() then 
		recoilMultiplier = recoilMultiplier * self.config.crouchRecoilMultiplier
	end
	
	angle = angle * recoilMultiplier

	if self.config.velocityRecoil then 
		mcontroller.addMomentum(vec2(self.config.velocityRecoil):rotate(aim:angle()) * vec2(aim.facing,1) * recoilMultiplier)
	end

	globalRecoil.offset = globalRecoil.offset + vec2(-armRecoil, 0)

	aim:recoil(angle)
end

--UI mechanics

function main:getCrosshairValue()
	return ((muzzle.inaccuracy + math.abs(aim:getRecoil())) / math.max(self.config.movingInaccuracy, self.config.standingInaccuracy, 0.000001)) * 25
end

--firing mechanics

local semidebounce = false
function main:updateFireControls(dt, firemode, shift, moves)
	--primary firing
	if firemode == "primary" and muzzle:canFire() and (not magazine:empty() or self.storage.loaded == 1) and self.queuedFire == 0 and timers:get("fireCooldown") == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) then
		if self.gunConfig.firemode == "auto" then
			self.queuedFire = 1
		elseif self.gunConfig.firemode == "burst" and timers:get("burstCooldown") == 0 then
			self.queuedFire = 3
			timers:reset("burstCooldown")
		elseif self.gunConfig.firemode == "semi" and not semidebounce then
			semidebounce = true
			self.queuedFire = 1
		end
	elseif firemode ~= "primary" then
		semidebounce = false
	end
end

function main:updateFire(dt)
	if self.queuedFire > 0 and timers:get("fireCooldown") == 0 and (not animations:isAnyPlaying() or self:isPlaying("fire")) and muzzle:canFire() then
		local result = self:fire()
		if result == 1 then
			events:fire("fire")
			self.queuedFire = self.queuedFire - 1
		elseif result == 2 then
			self.queuedFire = 0
		end
	elseif (self.queuedFire > 0 and magazine:empty() and self.storage.loaded ~= 1) or self:isPlaying("load") or self:isPlaying("reload") then
		self.queuedFire = 0
	end
end

function main:fire()
	if self.storage.loaded == 1 then
		events:fire("fire_true")
		if self.gunConfig.chamberEject then
			self:eject()
		else
			self.storage.loaded = 2
			self:save()
		end

		if self.gunConfig.chamberAutoLoad and not magazine:empty() then
			self.storage.canLoad = true
			self:save()
		end

		self:fireProjectile()
		timers:reset("fireCooldown")

		if magazine:empty() or self.gunConfig.chamberDryIfFire then
			self.storage.dry = true
			self:save()
		end

		self:animate("fire")
		return 1
	elseif self.storage.loaded == 2 then
		events:fire("fire_dry")
		return 2
	else
		events:fire("fire_noammo")
		return 0
	end
end

function main:fireProjectile()
	for i=1,self.gunConfig.projectileCount or 1 do
		muzzle:fireProjectile(self.gunConfig.projectileName, self.gunConfig.projectileConfig, self.damageMultiplier)
	end
end

--ammo mechanics

function main:updateReloadControls(dt, firemode, shift, moves)
	if self.reloadLooping and firemode ~= "none" then
		self.interuptReload = true
	end
	if animations:isAnyPlaying() then return end
	if not self.reloadLooping then
		if ((shift and moves.up) or (self.storage.loaded ~= 1 and magazine:empty() and mpguns:getPreference("autoreload"))) and timers:get("fireCooldown") <= 0 and (magazine:count() < self.config.magazineCapacity or self.config.magazineCapacity == 0) and firemode == "none" then
			events:fire("reload")
			if not animations:isAnyPlaying() then
				self:animate("reload")
			end
		end
		
		if ((not shift and moves.up and not mpguns:getPreference("disableW")) or (self.storage.loaded ~= 1 and not magazine:empty() and mpguns:getPreference("autoload"))) and timers:get("fireCooldown") <= 0 and not self.config.disallowAnimationLoad then
			events:fire("load")
			if not animations:isAnyPlaying() then
				self:animate("load")
			end
		end
	end
end

function main:updateReload(dt)
	if self.reloadLooping and not animations:isAnyPlaying() then
		if magazine:count() < self.config.magazineCapacity and not self.interuptReload then
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
		magazine:load(amount)
	else
		magazine:reload()
	end
	
	self:save()
end

function main:ammoCount() --mag + chamber
	local ammo = magazine:count()
	if self.storage.loaded and self.storage.loaded == 1 then
		ammo = ammo + 1
	end
	return ammo
end

function main:eject()
	if self.storage.loaded > 0 and not self.gunConfig.noCasingEject then
		self:casing()
	end
	self.storage.loaded = 0
	self:save()
end

function main:casing()
	if mpguns:getPreference("disableCasings") then return end

	if self.gunConfig.casingParticle then
		animator.burstParticleEmitter(self.gunConfig.casingParticle)
	end
	if self.gunConfig.casing and self.gunConfig.casing.type and self.gunConfig.casing.part then
		local casingConfig = root.assetJson(directory(self.gunConfig.casing.type, "/mpguns_core/casingConfigs/", ".config"))
		local pos = activeItem.handPosition(animator.transformPoint(self.gunConfig.casing.offset or {0,0},self.gunConfig.casing.part)) + mcontroller.position()

		local position = activeItem.handPosition(animator.transformPoint(self.gunConfig.casing.offset or {0,0},self.gunConfig.casing.part))
		local end_position = activeItem.handPosition(animator.transformPoint((self.gunConfig.casing.offset or {0,0}) + vec2(0,1),self.gunConfig.casing.part))
		local angle = (end_position - position):angle()

		casingConfig.parameters.ownerId = activeItem.ownerEntityId()

		for i=1,self.gunConfig.casing.count or 1 do
			local random = 0
			if self.gunConfig.casing.randomAngle and self.gunConfig.casing.randomAngle > 0 then
				random = (math.random((math.abs(self.gunConfig.casing.randomAngle) * 2) * 1000) / 1000) - (self.gunConfig.casing.randomAngle)
			end
			casingConfig.parameters.velocity = vec2(self.gunConfig.casing.velocity or casingConfig.parameters.velocity):rotate(((-angle + math.rad(random)) * aim.facing) + math.rad((math.random(450,900) - 450) / 10)) * vec2(aim.facing, 1)
			world.spawnMonster(casingConfig.type, pos, casingConfig.parameters)
		end
	end
end

function main:load()
	if self.storage.loaded > 0 then
		main:eject()
	end
	self.storage.dry = false
	if not magazine:use() then return end
	self.storage.loaded = 1
	self:save()
end

function main:unload()
	if magazine:empty() then return end
	magazine:unload()
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
