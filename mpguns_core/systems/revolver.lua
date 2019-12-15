system "gun" --inherits gun
include "animations"

local holding = false

function main:updateFireControls(dt, firemode, shift, moves)
    --primary firing
    if firemode == "primary" and (self.storage.ammo > 0 or self.storage.loaded == 1) and self.queuedFire == 0 then
        if not holding and update_lastInfo[2] ~= "primary"  and (not animations:isAnyPlaying() or self:isPlaying("fire")) then
            holding = true
            self:animate("ready")
            if self.storage.loaded ~= 1 and not main.config.revolverNoLoad then
                self:load()
            end
        elseif holding and (not animations:isAnyPlaying() or (self:isPlaying("fire") and not self:isPlaying("ready"))) then
            holding = false
            if self.config.firemode == "auto" then
                self.queuedFire = 1
            elseif self.config.firemode == "burst" and self.burstCooldown == 0 then
                self.queuedFire = 3
                self.burstCooldown = self.config.burstCooldown or 0.5
            elseif self.config.firemode == "semi" then
                self.queuedFire = 1
            end
        end
    elseif holding and not animations:isAnyPlaying() then
        holding = false
        self:animate("unready")
    end
end