include "mpguns"

main = {}

function main:init()
    local checkboxes = config.getParameter("checkboxes", {})
    for i,v in pairs(checkboxes) do
        if type(mpguns:getPreference(v)) ~= "nil" then
            widget.setChecked(v, mpguns:getPreference(v))
            buttons[v] = function() mpguns:setPreference(v, widget.getChecked(v)) end
        end
    end
end

function main:update(dt)

end

function main:uninit()

end

buttons = {}

function main:callback(widgetname)
    if buttons[widgetname] then
        buttons[widgetname]()
    end
end