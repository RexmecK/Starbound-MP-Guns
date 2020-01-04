modPath = "/mpguns_core/"
includePath = modPath.."scripts/"

_included = {}
function include(util)
	require(includePath..util..".lua")
	_included[includePath..util..".lua"] = true
end

function system(name)
	require(directory(name, modPath.."systems/", ".lua"))
end

function init()
	include "config" --needed to load certain configs
	include "directory" 

	if checkUpdates() then return end

	init = function()
		if main and main.init then
			main:init()
		end
	end

	system(config.system or "default")

	init()
end

-- activeitem only
local checked = false
function checkUpdates()
	checked = true
	if not item then return end
	
	include "mpguns" 
	local thisitem = item.descriptor()
	local updates, err = mpguns:updateMpitem(thisitem)
	if type(updates) == "table" then
		item.setCount(0)
		mpguns:giveMpitem(updates)
		return true
	elseif err and err == 2 then
		item.setCount(0)
		return true
	end
	return false
end

update_lastInfo = {}
update_info = {}
update_lateInited = false

function update(...)
	if not checked then
		if checkUpdates() then return end
	end
	
	update_lastInfo = update_info
	update_info = {...}
	if not update_lateInited and main and main.lateInit then
		update_lateInited = true
		main:lateInit(...)
	end
	if main and main.update then
		main:update(...)
	end
end

function activate(...)
	if main and main.activate then
		main:activate(...)
	end
end

function uninit()
	if main and main.uninit then
		main:uninit()
	end
end

function createTooltip(...)
	if main and main.createTooltip then
		main:createTooltip(...)
	end
end

function callback(...)
	if main and main.callback then
		main:callback(...)
	end
end