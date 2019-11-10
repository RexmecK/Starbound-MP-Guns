include "crosshair"
include "events"
include "config"
include "animations"

alt = {}
alt.currentFiremode = 1
alt.fireModes = {"auto"}

function alt:init()
    self.currentFiremode = config.currentFiremode or 1
    self.firemodes = config.firemodes or {"auto"}
    self:applyFiremode()
end

function alt:update(dt, firemode)
    if firemode == "alt" and update_lastInfo[2] ~= "alt" then
        self:switch()
    end
end

function alt:uninit()
    config.currentFiremode = self.currentFiremode
end

function alt:switch()
    if animations:isAnyPlaying() then return end
    self.currentFiremode = self.currentFiremode + 1
    if #self.firemodes < self.currentFiremode then
        self.currentFiremode = 1
    end
    if animator.hasSound("switch") then
        animator.playSound("switch")
    end
    self:applyFiremode()
end

function alt:applyFiremode()
    if self.firemodes[self.currentFiremode] then
        main.config.firemode = self.firemodes[self.currentFiremode] 
    end
end
