include "events"

stats = {}
local raw = {}
local multipliers = {}
local baked = {}

local inited = false
function stats:init()
	inited = true

end

function stats:checkinit()
	if not inited then self:init() end
end

function stats:apply(tab)
	self:checkinit()
	
	for i,v in pairs(tab) do
		local multiplier = multipliers[i]
		local r = raw[i]

		if multiplier and type(multiplier) == type(v) then
			multipliers[i] = multiplier * v
		else
            multipliers[i] = v
		end
		
		self:bake(i)
	end
	
	events:fire("stats_apply")
end

function stats:bake(i)
	self:checkinit()
    
	local multiplier = multipliers[i]
	local r = raw[i]
	if r and type(r) == type(multiplier) and type(r) ~= "boolean" then
		baked[i] = r * multiplier
	else
		baked[i] = r
	end
end

setmetatable(stats,
	{
		__newindex = function(t, key, value)
			t:checkinit()
			raw[key] = value
			t:bake(key)
		end,
		__index = function(t, key)
			t:checkinit()
			return baked[key]
		end
	}
)