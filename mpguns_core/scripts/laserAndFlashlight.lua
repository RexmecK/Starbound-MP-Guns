include "config"
include "animator"
include "updateable"
include "mcontroller"
include "rays"

laserAndFlashlight = {}

laserAndFlashlight.config = {
    lightName = nil,
    laserPart = nil
}

-- 1: laser
-- 2: flashlight
-- 3: laser and flashlight
laserAndFlashlight.mode = 0

function laserAndFlashlight:init()
    local config1 = config.laserAndFlashlight
    if type(config1) == "string" then
        self.config = root.assetJson(directory(config1))
    else
        self.config = config1
    end
    self.mode = config.laserAndFlashlight_mode or 0
    self:updateState()
end

function laserAndFlashlight:update(dt, firemode, shift, moves)
    if moves.down and shift and not update_lastInfo[3] then
        self:switch()
    end

    if self.laserOn then
	    local a = activeItem.handPosition(animator.transformPoint(self.config.laserPart[2], self.config.laserPart[1]))
        local b = activeItem.handPosition(animator.transformPoint(self.config.laserPart[2] + vec2({3,0}), self.config.laserPart[1]))
        local angle = (b-a):angle() + math.rad(-90)

        local line = {
			color						= self.config.laserColor or {255,0,0,128},
			forks						= 0,
			minDisplacement				= 0.0001,
			displacement				= 0.00011,
			width						= 0.5,
			forkAngleRange				= 0,
			worldStartPosition			= mcontroller.position() + a,
			worldEndPosition			= rays.collide(mcontroller.position() + a, -angle, 64),
		}

        lightning:set("lasers", {line})
    else
        lightning:set("lasers", {})
    end
end

function laserAndFlashlight:uninit()
    self:save()
    self.mode = 0
    self:updateState()
end

function laserAndFlashlight:save()
    config.laserAndFlashlight_mode = self.mode
end

function laserAndFlashlight:switch()
    self.mode = self.mode + 1

    if self.mode == 1 and not self.config.laserPart then
        self.mode = self.mode + 1
    end
    if self.mode == 2 and not self.config.lightName then
        self.mode = self.mode + 1
    end
    if self.mode == 3 and (not self.config.lightName or not self.config.laserPart) then
        self.mode = self.mode + 1
    end
    
    if self.mode > 3 then self.mode = 0 end
    self:updateState()
end

function laserAndFlashlight:updateState()
    if (self.mode == 1 or self.mode == 3) and self.config.laserPart and not self.laserOn then
        self.laserOn = true
    elseif not (self.mode == 1 or self.mode == 3) and self.laserOn then
        self.laserOn = false
    end

    if (self.mode == 2 or self.mode == 3) and self.config.lightName and not self.lightOn then
        self.lightOn = true
        animator.setLightActive(self.config.lightName, true)
    elseif not (self.mode == 2 or self.mode == 3) and self.lightOn then
        self.lightOn = false
        animator.setLightActive(self.config.lightName, false)
    end
end

updateable:add("laserAndFlashlight")
include "lightning"