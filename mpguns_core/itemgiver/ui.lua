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

function buttons.fiveseven()
    widget.setText("itemid", "fiveseven")
end

function buttons.mp5sd()
    widget.setText("itemid", "mp5-sd")
end

function buttons.m1garand()
    widget.setText("itemid", "m1garand")
end

function buttons.deagle()
    widget.setText("itemid", "deagle")
end

function buttons.ak47()
    widget.setText("itemid", "ak47")
end

function buttons.mossberg590()
    widget.setText("itemid", "mossberg590")
end