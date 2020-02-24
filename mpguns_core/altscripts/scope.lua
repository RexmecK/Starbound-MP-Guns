include "crosshair"
include "events"
include "config"
include "animations"

alt = {}
alt.scoping = false
alt.originalAimRatio = 0.5

function alt:init()
    self.originalAimRatio = main.config.aimRatio or 0.5
    self:setupEvents()
end

function alt:update(dt, firemode)
    if firemode == "alt" and update_lastInfo[2] ~= "alt" then
        self:scope()
    end
end

function alt:uninit()

end

function alt:scope()
    if animations:isAnyPlaying() then return end
    self.scoping = not self.scoping
    if self.scoping then
        main:overrideAnimate("fire", "fire_scoped")
        main:animate("scope")
        crosshair.override = config.scopeCursor or "/mpguns_core/cursor/scope.cursor"
        main.config.aimRatio = config.scopeAimRatio or 0.5
    else
        main:overrideAnimate("fire", nil)
        main:animate("unscope")
        crosshair.override = false
        main.config.aimRatio = self.originalAimRatio
    end
end

local function unscopehandler()
    if alt.scoping then
        alt:scope()
    end
end

function alt:setupEvents()
    events:add("reload", unscopehandler)
    events:add("load", unscopehandler)
end
