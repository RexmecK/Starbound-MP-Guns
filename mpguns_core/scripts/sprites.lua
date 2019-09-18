include "animator"

sprites = {}

function sprites:load(list)
    if type(list) == "string" then
        list = root.assetJson(directory(list))
    end
    for i,v in pairs(list or {}) do
        animator.setGlobalTag(i,v)
    end
end