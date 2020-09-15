include "updateable"
include "config"
include "animator"
include "activeItem"
include "directory"
include "sprites"

skin = {}

function skin:init()
    local configskin = config.skin
    if configskin then
        self:applySprites(configskin)
    end

    config.skin = configskin or {}
    
    message.setHandler("skin.apply", function(loc, _, skin) if not loc then return end self:apply(skin) end)
    message.setHandler("skin.getTags", function(loc, _, skin) if not loc then return end return self:getTags() end)
end

function skin:apply(skin)
    config.skin = skin
	main:reloadSprites()
    self:applySprites(skin)
end

function skin:applySprites(skin)
    if skin.inventoryIcon then
        activeItem.setInventoryIcon(skin.inventoryIcon)
        skin.inventoryIcon = nil
    end
    for i,v in pairs(skin) do
        if v ~= "" then
            animator.setGlobalTag(i,v)
            if i == "magImage" then
                main:setMagImage(v, false)
            elseif i == "magImageFullbright" then
                main:setMagImage(v, true)
            end
        end
    end
end

function skin:getTags()
    local sprites = config.sprites
    if type(sprites) == "string" then
        sprites = root.assetJson(directory(sprites))
    end
    local list = {}
    if main.config.mag then
        list["magImage"] = config.skin["magImage"] or ""
        list["magImageFullbright"] = config.skin["magImageFullbright"] or ""
    end
    if sprites then
        for name,sprite in pairs(sprites) do
            list[name] = config.skin[name] or ""
        end
    end
    list["inventoryIcon"] = config.inventoryIcon
    return list
end