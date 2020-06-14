include "updateable"
include "vec2"
include "activeItem"
include "mcontroller"
include "config"

local backarms = {
	["idle.1"] =		{		3,		1.375},
	["idle.2"] =		{		3,		1.75},
	["idle.3"] =		{		3.125,	1.75},
	["idle.4"] =		{		3.25,	1.625},
	["idle.5"] =		{		3.5,	1.375},
	["duck.1"] =		{		3.5,	1},
	["walk.4"] =		{		3.125,	1.25},
	["walk.5"] =		{		3.25,	1.375},
	["rotation"] =		{		4,		2.25},
	["run.3"] =			{		3.375,	1.375},
	["run.4"] =			{		3.625,		2.25},
	["run.5"] =			{		3.875,		2.625},
	["jump.1"] =		{		3.125,		1.5},
	["jump.2"] =		{		3.5,		2.25},
	["jump.3"] =		{		3.75,		2.5},
	["jump.4"] =		{		3.75,		2.625},
	["fall.1"] =		{		3.625,		1.75},
	["fall.2"] =		{		3.75,		3.25},
	["fall.3"] =		{		3.625,		3.5},
	["fall.4"] =		{		3.5,		3.625},
	["swimIdle.1"] =	{		3.75,		2.375},
	["swimIdle.2"] =	{		3.75,		2.125},
	["swim.1"] =		{		3.625,		2.5},
	["swim.2"] =		{		3.25,		2.125},
	["swim.3"] =		{		4.125,		2.75},
	["swim.4"] =		{		3.875,		2.625},
	["swim.5"] =		{		3.75,		2.625},
	["idleMelee"] =		{		3.125,		1.25},
	["duckMelee"] =		{		3.375,		0.875}
}

local frontarms = {
	["idle.1"] =		{		2.125,	    1.375},
	["idle.2"] =		{		2.125,	    1.75},
	["idle.3"] =		{		1.625,	    1.625},
	["idle.4"] =		{		1.875,	    1.5},
	["idle.5"] =		{		1.75,	    1.625},
	["duck.1"] =		{		1.5,	    1.125},
	["walk.1"] =		{		3,		    1.375},
	["walk.2"] =		{		2.625,	    1.375},
	["walk.3"] =		{		2.375,	    1.375},
	["walk.4"] =		{		2.125,	    1.375},
	["walk.5"] =		{		1.875,	    1.375},
	["rotation"] =		{		3.5,	    2.25},
	["run.1"] =			{		3.25,	    2.25},
	["run.2"] =			{		3.125,	    2.25},
	["run.3"] =			{		2.75,	    1.625},
	["run.4"] =			{		2.125,	    1.5},
	["run.5"] =			{		2,		    1.875},
	["jump.1"] =		{		2.625,	    1.875},
	["jump.2"] =		{		2,		    1.625},
	["jump.3"] =		{		1.875,	    1.875},
	["jump.4"] =		{		1.875,	    2},
	["fall.1"] =		{		1.375,	    2.25},
	["fall.2"] =		{		1.5,	    3.25},
	["fall.3"] =		{		1.75,	    3.375},
	["fall.4"] =		{		1.875,	    3.5},
	["swimIdle.1"] =	{		2.5,	    2.375},
	["swimIdle.2"] =	{		2.5,	    2.125},
	["swim.1"] =		{		2.25,	    2.5},
	["swim.2"] =		{		3,		    2.375},
	["swim.3"] =		{		3.625,	    2.75},
	["swim.4"] =		{		3.125,	    2.625},
	["swim.5"] =		{		2.75,	    2.625},
	["idleMelee"] =		{		2.125,	    1.375},
	["duckMelee"] =		{		1.875,	    1}
}

local center = vec2({2.6875, 2.6875})
local frontArmOffset = vec2({1, -0.375})
local backArmOffset = vec2({1, -0.375})

altarms = {}
altarms.frontTarget = vec2(0,0)
altarms.backTarget = vec2(0,0)
altarms.frontOffset = vec2(0,0)
altarms.backOffset = vec2(0,0)

function altarms:init()
    local calcbackarms = {}
    for i,v in pairs(backarms) do
        calcbackarms[i] = v - center - (backArmOffset)
    end
    backarms = calcbackarms

    local calcfrontarms = {}
    for i,v in pairs(frontarms) do
        calcfrontarms[i] = v - center - frontArmOffset
    end
	frontarms = calcfrontarms
	
	
	local confanimation = config:getAnimation()
    transforms:addCustom(
        "frontOffset", 
            (confanimation.transformationGroups.frontOffset or {}).transform or {position = vec2(0,0)}, 
        function(tr)
	        self.frontOffset = tr.position or vec2(0,0)
        end
	)
    transforms:addCustom(
        "backOffset", 
            (confanimation.transformationGroups.backOffset or {}).transform or {position = vec2(0,0)}, 
        function(tr)
	        self.backOffset = tr.position or vec2(0,0)
        end
	)
end

local function createOffsetsDirectives(offset, frameSize)
	if not frameSize then frameSize = vec2(43,43) end
	local directives = ""
	local max = math.ceil(math.max(math.abs(offset[1]*8), math.abs(offset[2]*8)))
	if max == 0 then
		return ""
	end
	--create padding
	directives = directives.."?border="..max..";0000;0000"
	local crop = {0,0,frameSize[1] + max*2, frameSize[2] + max*2}

	if offset[1] > 0 then
		crop[3] = crop[3] - math.ceil(offset[1]*8)*2
	elseif offset[1] < 0 then
		crop[1] = crop[1] - math.ceil(offset[1]*8)*2
	end

	if offset[2] > 0 then
		crop[4] = crop[4] - math.ceil(offset[2]*8)*2
	elseif offset[2] < 0 then
		crop[2] = crop[2] - math.ceil(offset[2]*8)*2
	end

	directives = directives.."?crop="..table.concat(crop,";")

	return directives
end

function altarms:update(dt,firemode, shift)
    local facing = vec2({mcontroller.facingDirection(), 1})

    local frontClosest = false
    for i,v in pairs(frontarms) do
        local pos = activeItem.handPosition(v)
        local pos2 = self.frontTarget
        local distance = math.sqrt((pos2.x - pos.x)^2 + (pos2.y - pos.y)^2)
        if not frontClosest then
            frontClosest = {i, distance}
        elseif frontClosest[2] > distance then
            frontClosest = {i, distance}
        end
        --world.debugPoint(mcontroller.position() + pos, {0,0,0, math.max(math.min(255 * (0.003 ^ distance), 255), 0) })
    end

    local backClosest = false
    for i,v in pairs(backarms) do
        local pos = activeItem.handPosition(v)
        local pos2 = self.backTarget
        local distance = math.sqrt((pos2.x - pos.x)^2 + (pos2.y - pos.y)^2)
        if not backClosest then
            backClosest = {i, distance}
        elseif backClosest[2] > distance then
            backClosest = {i, distance}
        end
        --world.debugPoint(mcontroller.position() + pos, {0,0,0, math.max(math.min(255 * (0.003 ^ distance), 255), 0) })
    
    end
	local twohanded = activeItem.twoHanded()	
	local frontOffset = createOffsetsDirectives(self.frontOffset)
	local backOffset = createOffsetsDirectives(self.backOffset)
	if twohanded then
	    if frontClosest then
	        activeItem.setFrontArmFrame(frontClosest[1]..frontOffset)
	    end
	    if backClosest then
	        activeItem.setBackArmFrame(backClosest[1]..backOffset)
		end
	else
	    if frontClosest then
	        activeItem.setFrontArmFrame(frontClosest[1]..frontOffset)
	        activeItem.setBackArmFrame(frontClosest[1]..frontOffset)
		end
	end

	altarms.frontTarget = activeItem.handPosition(animator.transformPoint({0,0},"R_handPoint"))
	altarms.backTarget = activeItem.handPosition(animator.transformPoint({0,0},"L_handPoint"))
	world.debugPoint(activeItem.handPosition(animator.transformPoint(self.frontOffset,"R_handPoint")) + mcontroller.position(),"green")
	world.debugPoint(activeItem.handPosition(animator.transformPoint(self.backOffset,"L_handPoint")) + mcontroller.position(),"green")
end

function altarms:uninit()

end