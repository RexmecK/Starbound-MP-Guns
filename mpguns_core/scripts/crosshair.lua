include "updateable"
include "localAnimator"
include "activeItem"
include "vec2"

crosshair = {}
crosshair.value = 1

function crosshair:init()
	activeItem.setCursor("/mpguns_core/cursor/crosshair_0.cursor")
end

function crosshair:update(dt)
	activeItem.setCursor("/mpguns_core/cursor/crosshair_"..math.max(math.min(math.floor(crosshair.value), 9), 0)..".cursor")
end

updateable:add("crosshair")