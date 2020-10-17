include "attachment"
include "flashlight"

attachment_flashlight = attachment:new() --inherits attachment.lua
attachment_flashlight._overrideInit = attachment_flashlight.init
attachment_flashlight.hasActivation = true

function attachment_flashlight:init()
    attachment_flashlight:_overrideInit()
    flashlight:anchor(self.rail.config.part, self.config.flashlightOffset or {0,0})
end

function attachment_flashlight:activate()
    flashlight:toggle()
end
