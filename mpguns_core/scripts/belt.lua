include "directory"
include "animator"

belt = {}
belt.current = 0
belt.config = {}

function belt:init()
    self.config = root.assetJson(directory(config.belt))
end

function belt:update()
    if main and main.storage.ammo then 
        if self.current < main.storage.ammo then
            while self.current < main.storage.ammo and self.config[self.current + 1] do
                animator.setPartTag(self.config[self.current + 1][1], "partImage", self.config[self.current + 1][2])
                self.current = self.current + 1
            end
        else
            while self.current > main.storage.ammo and self.config[self.current] do
                animator.setPartTag(self.config[self.current][1], "partImage", "")
                self.current = self.current - 1
            end
        end
    end
end

updateable:add("belt")