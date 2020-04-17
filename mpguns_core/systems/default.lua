main = {}

function main:init()
	if config.additionnalScripts then
		for i,v in pairs(config.additionnalScripts) do
			pcall(function() require(directory(v, modPath.."scripts/", ".lua")) end)
		end
	end
end

function main:update()

end

function main:uninit()

end