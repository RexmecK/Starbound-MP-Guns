include "mpguns"

main = {}

function main:init()

end

function main:update()

end

function main:uninit()

end

function main:callback(widgetname)
    if buttons[widgetname] then
        buttons[widgetname]()
    end
end

buttons = {}

function buttons.give()
    local item = mpguns:get(widget.getText("itemid"))
    if item then
        local mpitem = mpguns:makeMpitem(item)
        if mpitem then
            mpguns:giveMpitem(mpitem)
        end
    end
end

function buttons.scarh()
    widget.setText("itemid", "scar-h")
end