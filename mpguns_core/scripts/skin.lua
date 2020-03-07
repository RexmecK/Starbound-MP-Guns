include "updateable"
include "config"
include "animator"
include "directory"

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
	sprites:load(config.sprites)
    self:applySprites(skin)
end

function skin:applySprites(skin)
    for i,v in pairs(skin) do
        animator.setGlobalTag(i,v)
    end
end

function skin:getTags()
    local sprites = config.sprites
    if type(sprites) == "string" then
        sprites = root.assetJson(directory(sprites))
    end
    local list = {}
    if sprites then
        for name,sprite in pairs(sprites) do
            list[name] = config.skin[name] or ""
        end
    end
    return list
end