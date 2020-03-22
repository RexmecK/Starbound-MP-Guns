include "crosshair"
include "events"
include "config"
include "animations"

alt = {}
alt.current = 1

function alt:init()
    self.gunstats = config.gunstats or {}
    self.current = config.altcurrent or 1
    self:applyStats()
end

function alt:update(dt, firemode)
    if firemode == "alt" and update_lastInfo[2] ~= "alt" and not animations:isAnyPlaying() then
        self:switch()
    end
end

function alt:uninit()
    self:save()
end

function alt:save()
    config.altcurrent = self.current
end

function alt:switch()
    if animations:isAnyPlaying() then return end

    if animator.hasSound("switch") then
        animator.playSound("switch")
    end

    self.current = self.current + 1
    if self.current > #self.gunstats then
        self.current = 1
    end

    self:applyStats()
end

function alt:applyStats() -- swaps with the current selected alt mag on the gun

    if self.gunstats[self.current] then
        main.config = root.assetJson(directory(self.gunstats[self.current]))
    end

    self:save()
    main:initData()
end