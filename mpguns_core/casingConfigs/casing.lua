ownerId = nil
clientsideSounds = {}
timeToLive = 0.5

function init()
    ownerId = config.getParameter("ownerId")
    clientsideSounds = config.getParameter("clientsideSounds") or clientsideSounds
    
    local velocity = config.getParameter("velocity", {0,0})

    mcontroller.setVelocity(velocity)
end

lastGroundState = false

function update(dt)
    local ground = mcontroller.onGround()
    if ground and not lastGroundState then
        lastGroundState = true
        bounce()
    elseif not ground then
        lastGroundState = false
    end

    timeToLive = timeToLive - dt
    if timeToLive < 0 then
        function shouldDie() return true end
    end
    updateRotation(dt)
end

rotationVelocity = 360

function updateRotation(dt)
    animator.rotateTransformationGroup("body", mcontroller.xVelocity()/3)
end

function bounce()
    if ownerId and world.entityExists(ownerId) and #clientsideSounds > 0 then
        world.sendEntityMessage(ownerId, "mpguns.playLocalSound", clientsideSounds[math.random(1,#clientsideSounds)])
    end
end