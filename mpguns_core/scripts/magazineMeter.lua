include "directory"
include "animator"

magazineMeter = {}
magazineMeter.current = 0
magazineMeter.config = {}

function magazineMeter:init()
    self.config = root.assetJson(directory(config.magazineMeter))
end

function magazineMeter:update()
    if main and main.storage.ammo then 
        if self.current < main.storage.ammo then
            while self.current < main.storage.ammo do
                self.current = self.current + 1
                self:updateState()
            end
        else
            while self.current > main.storage.ammo do
                self.current = self.current - 1
                self:updateState()
            end
        end
    end
end

function magazineMeter:updateState()
    if self.config[self.current + 1] and self.config[self.current + 1][1] then
        animator.setPartTag(self.config[self.current + 1][1], "partImage", self.config[self.current + 1][2])
    end
end

updateable:add("magazineMeter")