include "activeItem"
include "updateable"

lightning = {}
lightning.list = {}

function lightning:update()
    local lines = {}
    for i,v in pairs(self.list) do
        for _,l in pairs(v) do
            table.insert(lines, l)
        end
    end
    activeItem.setScriptedAnimationParameter("lightning", lines)
end

function lightning:set(name, list)
    self.list[name] = list
end

function lightning:get(name, list)
    return self.list[name]
end

function lightning:uninit()
    activeItem.setScriptedAnimationParameter("lightning",{})
end

updateable:add("lightning")