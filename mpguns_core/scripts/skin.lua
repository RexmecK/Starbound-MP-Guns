include "updateable"
include "config"
include "animator"
include "activeItem"
include "directory"
include "sprites"
include "events"

skin = {}

function skin:init()
	self:refreshSprites()

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
	self:refreshSprites()
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
				magazine:setDropImage(v, false)
			elseif i == "magImageFullbright" then
				magazine:setDropImage(v, true)
			end
		end
	end
	events:fire("applySkins")
end

function skin:getTags()
	local sprites = config.sprites
	if type(sprites) == "string" then
		sprites = root.assetJson(directory(sprites))
	end
	local list = {}
	if (main.config and main.config.mag) or config.magazine then
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

--turns every sprite to default
function skin:refreshSprites()
	local spritestoload = config.sprites
	if type(spritestoload) == "string" then
		spritestoload = root.assetJson(directory(spritestoload))
	end
	if mpguns:getPreference("lowQuality") then
		for i,v in pairs(spritestoload) do
			spritestoload[i] = v.."?scale=0.525?scalenearest=1.90476190476190"
		end
	end
	for i,v in pairs(spritestoload) do
		if i == "magImage" then
			magazine:setDropImage(v, false)
		elseif i == "magImageFullbright" then
			magazine:setDropImage(v, true)
		end
	end
	sprites:load(spritestoload)
	
	events:fire("refreshSprites")
end

updateable:add("skin")