include "crosshair"

alt = {}
alt.scoping = false
alt.originalAimRatio = 0.5

function alt:init()
    self.originalAimRatio = main.config.aimRatio or 0.5
end

function alt:update(dt, firemode)
    if firemode == "alt" and update_lastInfo[2] ~= "alt" then
        self:scope()
    end
end

function alt:uninit()

end

function alt:scope()
    self.scoping = not self.scoping
    if self.scoping then
        crosshair.override = main.config.scopeCursor or "/mpguns_core/cursor/scope.cursor"
        main.config.aimRatio = main.config.scopeAimRatio or 0.5
    else
        crosshair.override = false
        main.config.aimRatio = self.originalAimRatio
    end
end