include "updateable"
include "config"

magazine = {}
magazine.inited = false
magazine.config = {}
magazine._ammo = 0
magazine.capacity = 30

function magazine:init()
	if self.inited then return end
	self.inited = true
    self._ammo = config.ammo or self.capacity
	if type(config.magazine) == "string" then
		self.config = root.assetJson(directory(config.magazine))
    else
		self.config = config.magazine
	end

end

function magazine:update()

end

function magazine:uninit()
    self:save()
end

function magazine:save()
    config.ammo = self._ammo
end

function magazine:reload()
    self._ammo = self.capacity
    self:save()
end

function magazine:unload()
    self._ammo = 0
    self:save()
end

function magazine:load(amount)
    self._ammo = self._ammo + amount
    self:save()
end

function magazine:use()
    if self._ammo == 0 then return false end
    self._ammo = self._ammo - 1
    self:save()
    return true
end

function magazine:empty()
    return self._ammo == 0
end

function magazine:count()
    return self._ammo
end

local magconfig = false
local maginited = false

function magazine:initmag()
	if not self.inited then self:init() end
    maginited = true
	magconfig = root.assetJson("/mpguns_core/mag.config")

    if not self.config then
        if main and main.gunConfig and main.gunConfig.mag then
            self.config = main.gunConfig.mag
        else
            self.config = {}
        end
    end
    
	if self.config.scale then
		magconfig.parameters.scale = self.config.scale
	end

	if self.config.image then
		magconfig.parameters.animationCustom.globalTagDefaults.magimage = self.config.image
	end

	if self.config.imagefullbright then
		magconfig.parameters.animationCustom.globalTagDefaults.magimagefullbright = self.config.imagefullbright
	end
end

function magazine:hide()
	if not maginited then
		self:initmag()
    end
    
    if self.config.spriteTags then
        for i,v in parts() do
            animator.setGlobalTag(v, "")
        end
    end
end

function magazine:setDropImage(image, isFullbright)
	if not maginited then
		self:initmag()
	end

	if isFullbright then
		magconfig.parameters.animationCustom.globalTagDefaults.magimagefullbright = image
	else
		magconfig.parameters.animationCustom.globalTagDefaults.magimage = image
	end
end

function magazine:dropEffect()
	if not maginited then
		self:initmag()
    end
    
	if self.config and self.config.part then
		
		if not maginited then
			maginited = true
			self:initmag()
		end

		local pos = activeItem.handPosition(animator.transformPoint(self.config.offset or {0,0},self.config.part)) + mcontroller.position()

		local position = activeItem.handPosition(animator.transformPoint(self.config.offset or {0,0},self.config.part))
		local end_position = activeItem.handPosition(animator.transformPoint((self.config.offset or {0,0}) + vec2(0,1),self.config.part))
		local angle = (end_position - position):angle()

		magconfig.parameters.ownerId = activeItem.ownerEntityId()

		for i=1,self.config.count or 1 do
			magconfig.parameters.velocity = vec2(self.config.velocity or magconfig.parameters.velocity):rotate((-angle * aim.facing) + math.rad((math.random(450,900) - 450) / 10)) * vec2(aim.facing, 1)
			world.spawnMonster(magconfig.type, pos, magconfig.parameters)
		end
	end
end


updateable:add("magazine")