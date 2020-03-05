include "directory"

mpguns = {}

-- get item from index
-- index is a string that indexes /mpguns/<index>
-- if index has beginning '/' it means it is a custom folder directory
-- index can mean "id" from the spawnlist
function mpguns:get(index)
    local res, item = pcall(root.assetJson, directory(index, "/mpguns/", "/").."item.json")
    if not res then sb.logWarn("Couldnt load item!") return end

    item.directory = directory(index, "/mpguns/", "/")
    item.index = index
    return item
end

-- main api item
function mpguns:base()
    local res, mpitem = pcall(root.assetJson, "/mpguns_core/mpitembase.json")
    if not res then sb.logWarn("Couldnt load item base!") return end
    return mpitem
end

-- builds a updated item to a mpitem
function mpguns:makeMpitem(item)
    local mpitem = self:base()
    if not mpitem then return end

    -- takes item config and merge it with base mpitem
    mpitem.parameters = sb.jsonMerge(mpitem.parameters, item)

    -- loads animation path file into a object for vanilla mp purposes
    if mpitem.parameters.preloadAnimation and type(mpitem.parameters.animation) == "string" then
        mpitem.parameters.animation = root.assetJson(directory(mpitem.parameters.animation, item.directory))
    end

    if item.patches then
        mpitem.parameters.patches = {}
        for i,v in pairs(item.patches) do
            res, e = pcall(sb.mergeJson, mpitem.parameters, v)
            if res then
                mpitem.parameters = res
                mpitem.parameters.patches[i] = v
            end
        end
    end

    mpitem.skin = item.skin

    return mpitem
end

--gives player the mpitem
function mpguns:giveMpitem(mpitem)
    player.giveItem(mpitem)
end

--removes player the mpitem
function mpguns:removeMpitem(mpitem)
    return player.consumeItem(mpitem, false, true)
end

-- returns numbers if errored
-- error 1: internal error
-- error 2: the item doesnt exist anymore and should be removed
-- returns a mpitem if update is required
-- returns nil if no update is required
function mpguns:updateMpitem(check_item)
    
    local directory = check_item.parameters.directory
    if not directory then return end -- for unlinked mpitems

    local mpitem = self:base()
    if not mpitem then return nil, 1 end

    local item = self:get(directory)
    if not item then return nil, 2 end

    if (item.itemVersion ~= check_item.parameters.itemVersion) or (mpitem.parameters.baseVersion ~= check_item.parameters.baseVersion) then
        if check_item.parameters.patches then
            item.patches = check_item.parameters.patches
        end
        if check_item.parameters.skin then
            item.skin = check_item.parameters.skin
        end
        return self:makeMpitem(item)
    end
    
end

-- User Settings --
mpguns.userSettings = {
    cameraAim = true,
    cameraRecoil = true,
    disableW = false,
    autoreload = true,
    autoload = true,
    disableCasings = false,
}

local initeduserpref = false
function mpguns:initUserPref()
    initeduserpref = true
    self.userSettings = sb.jsonMerge(self.userSettings, status.statusProperty("mpguns", self.userSettings))
end

function mpguns:getPreference(name)
    if not initeduserpref then self:initUserPref() end
    return self.userSettings[name] 
end

function mpguns:setPreference(name, value)
    if not initeduserpref then self:initUserPref() end
    self.userSettings[name] = value
    status.setStatusProperty("mpguns", self.userSettings)
end

