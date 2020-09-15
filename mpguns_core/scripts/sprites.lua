include "animator"
include "events"

sprites = {}

function sprites:load(list)
    if type(list) == "string" then
        list = root.assetJson(directory(list))
    end
    for i,v in pairs(list or {}) do
        animator.setGlobalTag(i,v)
        events:fire("sprite.load."..i, v)
    end
end