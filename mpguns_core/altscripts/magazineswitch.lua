include "crosshair"
include "events"
include "config"
include "animations"

alt = {}
alt.magazines = {}
alt.maxmagazines = 1
alt.current = 1

function alt:init()
    self.magazines = config.altmagazines or self.magazines
    self.maxmagazines = config.altmaxmagazines or self.maxmagazines
    self.current = config.altcurrent or 1
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
    config.altmagazines = self.magazines
    config.altmaxmagazines = self.maxmagazines
end

function alt:switch()
    if animations:isAnyPlaying() then return end

    if animator.hasSound("switch") then
        animator.playSound("switch")
    end

    self:swapMagazine()
end

function alt:swapMagazine() -- swaps with the current selected alt mag on the gun
    if self.current == self.maxmagazines then
        self.current = 1
    end

    if not self.magazines[self.current] then
        self.magazines[self.current] = main.config.magazineCapacity 
    end

    local switched = main.storage.ammo
    main.storage.ammo = self.magazines[self.current]
    self.magazines[self.current] = switched
    self:save()
    main:save()
end