include "updateable"
include "localAnimator"
include "activeItem"
include "vec2"

crosshair = {}
crosshair.value = 1
crosshair.override = false

function crosshair:init()
	activeItem.setCursor("/mpguns_core/cursor/crosshair_0.cursor")
end

function crosshair:update(dt)
	if self.override then
		activeItem.setCursor(self.override)
	else
		activeItem.setCursor("/mpguns_core/cursor/crosshair_"..math.max(math.min(math.floor(crosshair.value), 9), 0)..".cursor")
	end
end

updateable:add("crosshair")