local oldInit = init or function() end
local oldUpdate = update or function() end

require "/scripts/vec2.lua"

function init()
	local result, ret = pcall(oldInit)

	message.setHandler("mpguns.playLocalSound", 
        function(_, loc, sound) if not loc then return end
            localAnimator.playAudio(sound, 0, 1.0)
        end
    )

	if not result then
		sb.logError(tostring(ret))
		oldInit = function() end
	end
end
