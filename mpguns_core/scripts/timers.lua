include "updateable"

--timer manager

timers = {}
timers.list = {}

local lastdt = 0


function timers:init()
    lastdt = os.clock()
end


function timers:update(dt)
    local currentdt = os.clock()
    local betweendt = currentdt - lastdt + 0.00066666666666
    local fixdt = dt + math.max(betweendt - dt, -0.2)
    world.debugText("dt : "..dt, mcontroller.position() + vec2(0, 2), "black")
    world.debugText("betweenddt : "..betweendt, mcontroller.position() + vec2(0, 3), "black")
    world.debugText("fixdt : "..fixdt, mcontroller.position() + vec2(0, 4), "black")
    for i,v in pairs(self.list) do
        if v.current > 0 then
            self.list[i].current = math.max(v.current - fixdt, 0)
        end
    end
    lastdt = os.clock()
end

function timers:create(name, resetTime)
    timers.list[name] = {
        current = 0,
        resetTime = resetTime
    }
end

function timers:reset(name)
    if self.list[name] then
        self.list[name].current = self.list[name].resetTime
    end
end

function timers:setReset(name, time)
    if not self.list[name] then return end
    self.list[name].resetTime = time
end

function timers:get(name)
    return self.list[name].current
end

function timers:set(name, time)
    if not self.list[name] then return end
    self.list[name].current = time
end

updateable:add("timers")
