include "animations"
include "vec2"
include "tableutil"
include "magazine"

attachment_suppressor = {}
attachment_suppressor.config = {}
attachment_suppressor.modules = {}
attachment_suppressor.hasActivation = false
attachment_suppressor.rail = {} -- instanced api going to be set by the rails system look for rail.lua
attachment_suppressor.hideMagazine = false
attachment_suppressor.overridingMagazineDrop = false

function attachment_suppressor:new(c)
	local n = table.copy(self)
	n.config = c
	return n
end

function attachment_suppressor:init()
	self.rail:init()

	--sb.logInfo(sb.printJson(self.config))
	if self.config.image then
		self.rail:setImage(self.config.image)
	end
	if self.config.imageFullbright then
		self.rail:setImage(self.config.imageFullbright)
	end
	if self.config.magazineDropImage then
		self.overridingMagazineDrop = self.config.magazineDropImage 
	end
	if self.config.scale then
		self.rail:setScale(self.config.scale)
	end
	if self.config.soundPatches then
		for name,value in pairs(self.config.soundPatches) do
			if animator.hasSound(name) then
				if value.pool then
					animator.setSoundPool(name, value.pool)
					animator.setSoundVolume(name, value.volume or 1)
					animator.setSoundPitch(name, value.pitchMultiplier or 1)
				elseif #v > 0 then
					animator.setSoundPool(name, value)
				end
			end
		end
	end
	if self.config.multiplierStats then
		self.rail:applyStats(self.config.multiplierStats)
	end
	self:_refreshMagazineImage()

    animations:disableAnimationState("muzzleFlash")

	events:add("applySkins", function() self:_refreshMagazineImage() end)
	events:add("refreshSprites", function() self:_refreshMagazineImage() end)
end

function attachment_suppressor:update(dt, firemode, shift)
	self.rail:update(dt)
	
end

function attachment_suppressor:uninit()
	self.rail:uninit()

end

function attachment_suppressor:activate()
	
end

function attachment_suppressor:_refreshMagazineImage()
	local hide = false
	if self.overridingMagazineDrop then
		magazine:setDropImage(self.overridingMagazineDrop[1] or "/assetmissing.png", false)
		magazine:setDropImage(self.overridingMagazineDrop[2] or "/assetmissing.png", true)
	end
	if self.config.hideMagazine then
		magazine:hide()
	end
end
