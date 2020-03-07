include "mpguns"

main = {}

function main:init()
    widget.clearListItems("tags.list")
    closeInputText()
end

function main:update(dt)
    checklistselected()
end

function main:uninit()

end

function main:callback(widgetname)
    if buttons[widgetname] then
        buttons[widgetname]()
    end
end

function checklistselected()
    local sel = widget.getListSelected("tags.list")
    if sel then
        local newelement = widget.addListItem("tags.list")
        widget.setListSelected("tags.list", newelement)
        widget.removeListItem("tags.list", listcount)
        if not currentlyEditing then
            currentlyEditing = widget.getData("tags.list."..sel).name
            promptInputText()
        end
    end
end

spritesTags = {}
currentlyEditing = false
listcount = 0

function listTags()
    spritesTags = {}
    widget.clearListItems("tags.list")
    listcount = 0
    local rpc = world.sendEntityMessage(player.id(), "skin.getTags")
    if rpc:finished() and rpc:result() then
        for i,v in pairs(rpc:result()) do
            local newelement = widget.addListItem("tags.list")
            listcount = listcount + 1
            spritesTags[i] = v
            widget.setData("tags.list."..newelement, {name = i})
            widget.setText("tags.list."..newelement..".name", i)
        end
    end
end

function promptInputText()
    widget.setVisible("inputbg", true)
    widget.setText("spriteinput", spritesTags[currentlyEditing] or "")    
    widget.setVisible("spriteinput", true)    
    widget.setVisible("spriteapply", true)    
    widget.setVisible("spritecancel", true)     
    widget.setVisible("spriteclear", true)   
end

function closeInputText()
    widget.setVisible("inputbg", false)
    widget.setVisible("spriteinput", false)    
    widget.setText("spriteinput", "")    
    widget.setVisible("spriteapply", false)    
    widget.setVisible("spritecancel", false)    
    widget.setVisible("spriteclear", false)    
    currentlyEditing = false
end

buttons = {}

function buttons.edit()
    listTags()
end

function buttons.apply()
    local skin = {}
    for i,v in pairs(spritesTags) do
        if v ~= "" then
            skin[i] = v
        end
    end
    world.sendEntityMessage(player.id(), "skin.apply", skin)
end

function buttons.spritecancel()
    closeInputText()
end
function buttons.spriteapply()
    if currentlyEditing then
        spritesTags[currentlyEditing] = widget.getText("spriteinput")
    end
    closeInputText()
end
function buttons.spriteclear()
    widget.setText("spriteinput", "")     
end