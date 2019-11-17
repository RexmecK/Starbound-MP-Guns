include "crosshair"
include "events"
include "config"
include "animations"
include "mcontroller"

alt = {}
alt.config = {}
alt.ammo = 0
alt.fireCooldown = 0

function alt:setupEvents()
	animations:addEvent("recoilalt", function() 
			local angle = self.config.recoil
			if self.config.crouchRecoilMultiplier and mcontroller.crouching() then 
				angle = angle * self.config.crouchRecoilMultiplier
			end
			aim:recoil(angle)
		end
	)
	animations:addEvent("reloadalt", function() self:reload() end)
	animations:addEvent("reload1alt", function() self:reload(1) end)
	animations:addEvent("unloadalt", function() self:unload() end)
end

function alt:init()
	if type(config.altfire) == "string" then
		self.config = root.assetJson(directory(config.altfire))
	else
		self.config = config.altfire
    end
    self.ammo = config.altammo or self.config.magazineCapacity
    self:setupEvents()
end

function alt:update(dt, firemode, shift)
    if self.fireCooldown > 0 then
        self.fireCooldown = math.max(self.fireCooldown - dt, 0)
    end

    -- auto/burst fire not supported yet
    if firemode == "alt" and not shift and update_lastInfo[2] ~= "alt" and self.ammo > 0 and self.fireCooldown == 0 and not animations:isAnyPlaying() then
		self.fireCooldown = 60 / self.config.rpm
        self:fireProjectile()
        self.ammo = self.ammo - 1
        animations:play("altfire")
    end

    if (self.ammo == 0 or (firemode == "alt" and shift and update_lastInfo[2] ~= "alt")) and not animations:isAnyPlaying() then
        animations:play("altreload")
    end
end

function alt:uninit()
	self:save()
end

function alt:save()
	config.altammo = self.ammo
end

function alt:getInaccuracy()
	local vel = math.max(math.abs(mcontroller.xVelocity()), math.abs(mcontroller.yVelocity() + 1.27))
	local movingRatio = math.min(vel / 14, 1)

	local acc = (self.config.movingInaccuracy * movingRatio) + (self.config.standingInaccuracy * (1 - movingRatio))

	if mcontroller.crouching() and self.config.crouchInaccuracyMultiplier then
		return acc * self.config.crouchInaccuracyMultiplier
	else
		return acc
	end
end

function alt:fireProjectile()
    muzzle.inaccuracy = self:getInaccuracy()
	for i=1,self.config.projectileCount or 1 do
		muzzle:fireProjectile(self.config.projectileName, self.config.projectileConfig)
	end
end

function alt:reload(amount)
	if amount then
		self.ammo = self.ammo + amount
	else
		self.ammo = self.config.magazineCapacity
	end
	self:save()
end

function alt:unload()
	if self.ammo <= 0 then return end
	self.ammo = 0
	self:save()
end
