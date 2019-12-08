include "directory"

mpguns = {}

-- gets a list of indexes from the items
function mpguns:list()
    return root.assetJson("/mpguns/_index.json", {})
end

-- get item from index
function mpguns:get(index)
    local res, item = pcall(root.assetJson, directory(index, "/mpguns/", "/").."item.json")
    if not res then sb.logWarn("Couldnt load item!") return end

    item.directory = directory(index, "/mpguns/", "/")
    item.index = index
    return item
end

function mpguns:base()
    local res, mpitem = pcall(root.assetJson, "/mpguns_core/mpitembase.json")
    if not res then sb.logWarn("Couldnt load item base!") return end
    return mpitem
end

--builds a updated item to a mpitem
function mpguns:makeMpitem(item)
    local mpitem = self:base()
    if not mpitem then return end
    mpitem.parameters = sb.jsonMerge(mpitem.parameters, item)
    if mpitem.parameters.preloadAnimation and type(mpitem.parameters.animation) == "string" then
        mpitem.parameters.animation = root.assetJson(directory(mpitem.parameters.animation, item.directory))
    end
    return mpitem
end

--gives player the mpitem
function mpguns:giveMpitem(mpitem)
    player.giveItem(mpitem)
end

--gives player the mpitem
function mpguns:removeMpitem(mpitem)
    return player.consumeItem(mpitem, false, true)
end

-- returns numbers if errored
-- error 1: internal error
-- error 2: the item doesnt exist anymore and should be removed
-- returns a mpitem if update is required
-- returns nil if no update is required
function mpguns:updateMpitem(check_mpitem)
    
    local directory = check_mpitem.parameters.directory
    if not directory then return end -- for unlinked mpitems

    local mpitem = self:base()
    if not mpitem then return nil, 1 end

    local item = self:get(directory)
    if not item then return nil, 2 end

    if (item.itemVersion ~= check_mpitem.parameters.itemVersion) or 
        (mpitem.parameters.baseVersion ~= check_mpitem.parameters.baseVersion) then
        return self:makeMpitem(item)
    end
    
end

--User Settings
mpguns.userSettings = {
    cameraAim = true,
    cameraRecoil = true,
    disableW = false,
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

