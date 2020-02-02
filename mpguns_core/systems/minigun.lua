system "gun" --inherits gun
include "animations"
include "updateable"
include "config"

local ready = false

function main:updateFireControls(dt, firemode, shift, moves)
    if not ready then return end
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

local function lerp(a,b,r)
    return a+(b-a)*r
end

minigun = {}
minigun.config = {}
minigun.soundPitch = 0.0

function minigun:init()
    self.config = config.minigun or {}
end

function minigun:update(dt, firemode, shift, moves)
    if ready then
        if self.config.forceWalk then
            mcontroller.controlModifiers({runningSuppressed = true})
        end
        if self.config.sound and self.soundPitch then
            self.soundPitch = lerp(self.soundPitch, self.config.readyPitch or 1.0, 0.125)
            animator.setSoundPitch(self.config.sound, self.soundPitch, 0.01)
        end
    end
    if firemode ~= "none" and not ready and (not animations:isAnyPlaying() or main:isPlaying("fire")) and main.fireCooldown == 0 then
        main.fireCooldown = 0.3
        self:setState(true)
        ready = true
        self.soundPitch = 0.0
    elseif firemode == "none" and ready and main.fireCooldown == 0 then
        self:setState(false)
        ready = false
    end
end

function minigun:setState(a)
    if self.config.barrelStates then
        if a then 
            if self.config.barrelState and self.config.barrelStates.ready then
                animator.setAnimationState(self.config.barrelState, self.config.barrelStates.ready)
            end
            if self.config.sound then
                animator.playSound(self.config.sound, -1)
            end
        elseif not a then
            if self.config.barrelState and self.config.barrelStates.unready then
                animator.setAnimationState(self.config.barrelState, self.config.barrelStates.unready)
            end
            if self.config.sound then
                animator.stopAllSounds(self.config.sound)
            end
        end
    end
end

updateable:add("minigun")