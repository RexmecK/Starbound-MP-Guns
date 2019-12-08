include "mpguns"

main = {}
main.searchCooldown = -1

function main:init()
    self:loadlist()
end

function main:itemIdSearch()
    self:loadlist(widget.getText("itemid"))
end

function main:update(dt)
    if self.searchCooldown > 0 then
        self.searchCooldown = math.max(self.searchCooldown - dt, 0)
    elseif self.searchCooldown == 0 then
        self.searchCooldown = -1
        self:itemIdSearch()
    end
end

function main:uninit()

end

function main:callback(widgetname)
    if buttons[widgetname] then
        buttons[widgetname]()
    end
end

function main:loadlist(keywords)
    local spawnlist = root.assetJson("/mpgunsspawner/spawnlist.json")
    local keywords = removePatterns((keywords or "")):lower()

    grid:clear()
    scrollbarcallbacks = {}
    for i,v in pairs(spawnlist or {}) do
        if (not keywords) or (v.name:lower():match(keywords) or v.id:lower():match(keywords)) then
            local elementConfig = root.assetJson("/mpgunsspawner/element1.json")
            elementConfig.children.name.value = v.name
            elementConfig.children.content.file = v.image or "/assetmissing.png"
            elementConfig.children[v.id] = elementConfig.children.top
            elementConfig.children.top = nil
            
            local widname = grid:insert(elementConfig)
        end
    end
end

-- loose implementation here

scrollbarcallbacks = {}

function scrollbarcallback(widgetName)
    givegun(widgetName)
end

function itemidenter(widgetname)
    givegun(widget.getText(widgetname))
end

function givegun(itemid)
    local item = mpguns:get(itemid)
    if item then
        local mpitem = mpguns:makeMpitem(item)
        if mpitem then
            mpguns:giveMpitem(mpitem)
        end
    end
end

function removePatterns(s)
	s = s:gsub("%%", "%%%%")
	for i,v in pairs({
		"%.",
		"%(",
		"%)",
		"%+",
		"%-",
		"%*",
		"%?",
		"%[",
		"%]",
		"%^",
		"%$",
	}) do
		s = s:gsub(v,"%"..v)
	end

	return s
end

buttons = {}

function buttons.itemid()
    main.searchCooldown = 1
end

include "vec2"

grid = {}
grid.widgetName = "scroll"

--size settings
grid.elementSize = vec2(69,32)
grid.size = vec2(283,185)
grid.spacing = vec2(2,2)

grid.index = vec2(1,1)
grid.count = 1

function grid:clear()
    self.index = vec2(1,1)
    self.count = 1
    widget.removeAllChildren(self.widgetName)
end

function grid:indexPosition()
    local indexMult = self.index - vec2(1,1)
    return (self.elementSize + self.spacing) * indexMult * vec2(1,-1)
end

function grid:insert(widgetconfig)
    local widgetNewName = tostring(self.count)

    widget.addChild(self.widgetName, widgetconfig, widgetNewName)
    widget.setPosition(self.widgetName.."."..widgetNewName, self:indexPosition())

    self.count = self.count + 1
    self.index[1] = self.index[1] + 1
    if self:indexPosition().x > self.size.x then
        self.index[1] = 1
        self.index[2] = self.index[2] + 1
    end

    return widgetNewName
end






