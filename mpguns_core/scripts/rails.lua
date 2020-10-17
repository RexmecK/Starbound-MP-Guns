include "config"
include "animator"
include "attachment"
include "updateable"
include "events"
include "magazine"
include "rail"

rails = {}
rails.list = {}
rails.overridingMagazine = false
rails.activations = {}
rails.activateIndex = 1

function rails:init()
    local attachments = config.attachments or {}
    local default_attachments = config.default_attachments or {}

    for name,rail in pairs(config.rails or {}) do
        local a = attachments[name] or default_attachments[name]
        if a then
            --sb.logInfo(sb.printJson(a))
            self.list[name] = self:newAttachment(rail, a)
            self.list[name]:init()
            if self.list[name].hasActivation then
                self.activations[#self.activations] = name
            end
        end
    end

    events:fire("rails_init")
end

function rails:newAttachment(railconfig, config)
    local newAttachment
    if config.module then
        include(config.module)
        if config.module then
            newAttachment = _ENV[config.module]:new(config)
        end
    else
        newAttachment = attachment:new(config)
    end
    newAttachment.rail = rail:new(railconfig)
    return newAttachment
end


function rails:update(dt,firemode,shift,move)
    for name,attachment in pairs(self.list) do
        if self.list[name].update then
            self.list[name]:update(dt,firemode,shift,move)
        end
    end
    if #self.activations > 0 then
        if shift and firemode == "alt" and not update_lastInfo[2] ~= "alt" then
            self.activateIndex = self.activateIndex + 1
            if self.activateIndex > #self.activations then
                self.activateIndex = 1
            end
        elseif not shift and firemode == "alt" and not update_lastInfo[2] ~= "alt" then
            local act = self.list[self.activations[self.activateIndex]]
            if act.activate then
                self.list[self.activations[self.activateIndex]]:activate(dt,firemode,shift,move)
            end
        end
    end
end

function rails:uninit()
    for name,attachment in pairs(self.list) do
        if self.list[name].uninit then
            self.list[name]:uninit()
        end
    end
end

function rails:applyStats(st)
    stats:apply(st)
    events:fire("rails_applyStats")
end

updateable:add("rails")