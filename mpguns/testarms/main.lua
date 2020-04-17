include "altarms"

luaItem = {}

function luaItem:init()
end

function luaItem:update(dt, firemode)


    world.debugPoint(activeItem.handPosition({0,0}) + mcontroller.position(),"green")
    world.debugPoint( altarms.frontTarget + mcontroller.position(),"yellow")
    world.debugPoint( altarms.backTarget + mcontroller.position(),"magenta")

    local relativePos = activeItem.ownerAimPosition() - mcontroller.position()
    if firemode == "primary" then 
        altarms.frontTarget = relativePos
    elseif firemode == "alt" then
        altarms.backTarget = relativePos
    end
end

function luaItem:uninit()

end