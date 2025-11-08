local allowed = { { 48, 57 }, { 65, 90 }, { 97, 122 } }
local sw, sh = guiGetScreenSize()
local function generateString ( len )
    
    if tonumber ( len ) then
        math.randomseed ( getTickCount () )

        local str = ""
        for i = 1, len do
            local charlist = allowed[math.random ( 1, 3 )]
            str = str .. string.char ( math.random ( charlist[1], charlist[2] ) )
        end

        return str
    end
    
    return false
    
end

local function tableCount(t)
    local n = 0
    for _,v in pairs(t) do
        n=n+1
    end
    return n
end

local function findTableIndex(t, numberedIndex) -- returns string index
    local n = 1
    for i,v in pairs(t) do
        if (n == numberedIndex) then
            return i
        end
        n=n+1
    end
end


CLife = {
    instances = {},
    statistics = {
        fps = 0,
        time = 0,
        alive = 0,
        died = 0,
        eaten = 0,
        duplicated = 0,
        reproduced = 0,
        mutated = 0,
        collided = 0,
        spawned = 0,
    },
    startTick = getTickCount(),
    deathDisappearTime = 15000,
}
CLife.statistics.fps = getElementData(localPlayer, "p_fps") or 0
CLife.statistics.time = getTickCount() - CLife.startTick

CLife.__index = CLife



function CLife:new(x, y, parents)
    local life = setmetatable({}, CLife)

    if (parents) then
        life.parents = parents
    end

    life.alive = true
    CLife.statistics.alive = CLife.statistics.alive + 1
    CLife.statistics.spawned = CLife.statistics.spawned + 1
    life.name = generateString(math.random(2, 3)):lower()
    life.x = x
    life.y = y
    life.traits = {}
    life:evolve("name")
    life:evolve("size")
    life:evolve("speed")
    life:evolve("health")
    life:evolve("energy")
    life:evolve("maintenance")
    life:evolve("purity") --inbreeding
    life:evolve("type") -- singular or multicellular organism
    life:evolve("strength")
    life:evolve("color")

    if (math.random(1, 25) == 25) then
        life:mutate()
        CLife.statistics.mutated = CLife.statistics.mutated + 1
    end

    CLife.instances[#CLife.instances + 1] = life
    return life
end

function CLife.attempt(x, y)
    local shouldSpawn = math.random(1, 5) == 5
    if (shouldSpawn) then
        local life = CLife:new(x, y, false)
        life:checkIfCollided()
    end
end

function CLife:evolve(attr)
    if (attr == "size") then
        if (self.parents and #self.parents == 2) then
            self.traits.width = (self.parents[1].traits.width + self.parents[2].traits.width) / 2
            self.traits.height = (self.parents[1].traits.height + self.parents[2].traits.height) / 2
        else
            local size = math.random(2, 4)
            self.traits.width = size
            self.traits.height = size
        end
    elseif (attr == "speed") then
        if (self.parents and #self.parents == 2) then
            self.traits.speed = (self.parents[1].traits.speed + self.parents[2].traits.speed) / 2
        else
            self.traits.speed = math.random(1, 50)
        end
    elseif (attr == "health") then
        if (self.parents and #self.parents == 2) then
            self.traits.health = (self.parents[1].traits.health + self.parents[2].traits.health) / 2
        else
            self.traits.health = math.random(1, 4)
        end
    elseif (attr == "energy") then
        self.traits.energy = math.random(1, 5000)
    elseif (attr == "maintenance") then
        if (self.parents and #self.parents == 2) then
            self.traits.maintenance = (self.parents[1].traits.maintenance + self.parents[2].traits.maintenance) / 2
        else
            self.traits.maintenance = math.random(1, 4)
        end
    elseif (attr == "purity") then
        if (self.parents and #self.parents == 2) then
            self.traits.purity = self.parents[1].traits.type == self.parents[2].traits.type and 1 or ( (self.parents[1].traits.purity + self.parents[2].traits.purity) / 2 - 0.5 )
        else
            self.traits.purity = 1
        end
    elseif (attr == "type") then
        if (self.parents and #self.parents == 2) then
            local type1, type2 = self.parents[1].traits.type, self.parents[2].traits.type
            if (type1 == type2) then
                self.traits.type = type1
            else
                self.traits.type = type1 + type2
            end
        else
            if (self.parents and #self.parents == 1) then
                self.traits.type = self.parents[1].traits.type
            else
                self.traits.type = math.random(1, 2)
            end
        end
    elseif (attr == "strength") then
        if (self.parents and #self.parents == 2) then
            self.traits.strength = (self.parents[1].traits.strength + self.parents[2].traits.strength) / 2
        else
            self.traits.strength = math.random(1, 4 - 1) -- hardcoded 4 cuz health uses up to 4
        end
    elseif (attr == "color") then
        if (self.parents) then
            self.traits.color = {self.parents[1].traits.color[1], self.parents[1].traits.color[2], self.parents[1].traits.color[3], 255}
        else
            self.traits.color = {math.random(0, 255), math.random(0, 255), math.random(0, 255), 255}
        end
    end
end

function CLife:mutate()
    local mutateBetter = math.random(1, 2) == 2
    local mutateWhat = findTableIndex(self.traits, math.random(1, tableCount(self.traits)))
    local mutateBy = mutateBetter and math.random(1, 2) or -math.random(1, 2)
    if (mutateWhat ~= "color") then
        self.traits[mutateWhat] = self.traits[mutateWhat] + mutateBy
        self:checkIfDied()
    end
end

function CLife:checkIfDied()
    if (self.alive) then
        if (self.traits.health <= 0 or self.traits.energy < 0 or self.traits.purity <= 0 or self.traits.width * self.traits.height <= 0) then
            self.alive = false
            self.deathTick = getTickCount()
            self.traits.color[4] = 150
            CLife.statistics.died = CLife.statistics.died + 1
            CLife.statistics.alive = CLife.statistics.alive - 1
        end
    end
end

function CLife:duplicate(with)
    if (CLife.populationControl) then return end
    local newParent = math.random(1, 2) == 2 and self or with
    local life = CLife:new(newParent.x + math.random(-5, 5), newParent.y + math.random(-5, 5), {newParent})
    CLife.statistics.duplicated = CLife.statistics.duplicated + 1
end

function CLife:reproduce(with)
    if (CLife.populationControl) then return end
    --local successRatio = math.random(1, 100)
    --local hasSucceeded = math.random(1, successRatio) == successRatio
    local hasSucceeded = math.random(1, 100) <= 95
    if (hasSucceeded) then
        local newParent = math.random(1, 2) == 2 and self or with
        local life = CLife:new(newParent.x + math.random(-50, 50), newParent.y + math.random(-50, 50), {self, with})
        CLife.statistics.reproduced = CLife.statistics.reproduced + 1
    end
end

function CLife:move()

    local totalMovement = self.traits.speed
    if (totalMovement > 0) then

        local moveOnXFirst = math.random(1, 2) == 2
        local movementPoints = math.random(1, totalMovement)
        local leftMovement = totalMovement - movementPoints
        local moveMinusX = math.random(1, 2) == 2
        local moveMinusY = math.random(1, 2) == 2
        local firstProp = moveOnXFirst and "x" or "y"
        local secondProp = firstProp == "x" and "y" or "x"
        self[firstProp] = self[firstProp] + (firstProp == "x" and (moveMinusX and -movementPoints or movementPoints) or (moveMinusY and -movementPoints or movementPoints))
        if (leftMovement > 0) then
            self[secondProp] = self[secondProp] + (secondProp == "x" and (moveMinusX and -leftMovement or leftMovement) or (moveMinusY and -leftMovement or leftMovement))
        end

        -- make sure theyre not beyond borders --
        if (self.x < 0) then self.x = 0 end
        if (self.x > sw - self.traits.width) then self.x = sw - self.traits.width end
        if (self.y < 0) then self.y = 0 end
        if (self.y > sh - self.traits.height) then self.y = sh - self.traits.height end

        self.traits.energy = self.traits.energy - self.traits.maintenance

        self:checkIfDied()

        if (self.alive) then
            self:checkIfCollided()
        end

    end
end

function CLife:checkIfCollided()
    for i, life in pairs(CLife.instances) do
        if (life ~= self) then
            if (self.x >= life.x and self.x <= life.x + life.traits.width and self.y >= life.y and self.y <= life.y + life.traits.height) then
                self:onCollide(life)
                return
            end
        end
    end
end

function CLife:onCollide(life)
    -- self is definitely alive here
    CLife.statistics.collided = CLife.statistics.collided + 1
    if (life.alive) then
        local areRelated = self.parents and life.parents and (self.parents[1] == life.parents[1] or self.parents[1] == life.parents[2] or self.parents[2] == life.parents[1] or self.parents[2] == life.parents[2])
        local totalMateChance = 2
        local mateChance = totalMateChance
        local willingToMate = math.random(1, 5) == 5

        if (areRelated) then mateChance = mateChance - math.random(1, 2) end
        if (not willingToMate) then mateChance = mateChance - 1 end

        if (mateChance <= 0) then
            --local peaceful = math.random(1, 3) == 3 -- 33% chance of peaceful
            local peaceful = false
            if (not peaceful) then

                -- Related life forms in 66% of cases dont wanna fight each other --
                --if (areRelated and math.random(1, 3) ~= 3) then
                    --outputDebugString("returned because related: " .. tostring(inspect(self.parents)))
                    --outputDebugString("life parents: " .. tostring(inspect(life.parents)))
                    --return
                --end

                -- they attack each other if they got energy to do so --
                if (life.traits.energy > 0) then
                    self.traits.health = self.traits.health - life.traits.strength
                    life.traits.energy = life.traits.energy - life.traits.maintenance
                    --outputDebugString("life attacked " .. self.name)
                end
                if (self.traits.energy > 0) then
                    life.traits.health = life.traits.health - self.traits.strength
                    self.traits.energy = self.traits.energy - self.traits.maintenance
                end

                -- check if they died --
                self:checkIfDied()
                life:checkIfDied()

                local someoneDied = self.alive == false or life.alive == false

                if (someoneDied) then
                    local whoLost = self.alive == false and self or life
                    local whoWon = self.alive == true and self or life
                    --local willEat = whoWon.traits.energy == 0 or math.random(1, 5) ~= 5 -- might have to make 100% chance to prevent lag from huge reproduce zones, now 80% chance to eat
                    local willEat = true
                    if (willEat) then
                        whoWon.traits.energy = whoWon.traits.energy + math.random(1, 2500)
                        whoWon.traits.health = whoWon.traits.health + math.random(1, 2)
                        whoWon.traits.maintenance = whoWon.traits.maintenance + math.random(0, 2)
                        local sizeIncrease = math.random(1, 2)
                        whoWon.traits.width = whoWon.traits.width + sizeIncrease
                        whoWon.traits.height = whoWon.traits.height + sizeIncrease
                        whoLost:onEaten()
                    end
                    
                end
                
            end
        else
            local type1, type2 = self.type, life.type

            if (type1 ~= type2) then
                self:reproduce(life)
            else
                if (type1 == 1) then
                    self:duplicate(life)
                else
                    self:reproduce(life)
                end
            end
        end
    else
        -- life is dead, self is alive
        --local willEat = self.traits.energy == 0 or math.random(1, 2) == 2
        local willEat = true -- should always eat when randomly coming to dead life food
        if (willEat) then
            self.traits.energy = self.traits.energy + math.random(1, 50)
            self.traits.health = self.traits.health + math.random(1, 2)
            self.traits.maintenance = self.traits.maintenance + math.random(0, 2)
            local sizeIncrease = math.random(1, 2)
            self.traits.width = self.traits.width + sizeIncrease
            self.traits.height = self.traits.height + sizeIncrease
            life:onEaten()
        end
    end


end

function CLife:onEaten()
    CLife.statistics.eaten = CLife.statistics.eaten + 1
    for i, life in pairs(CLife.instances) do
        if (life == self) then
            table.remove(CLife.instances, i)
            break
        end
    end
end

function CLife.expireDead()
    for i, life in pairs(CLife.instances) do
        if (life.alive == false) then
            if (not life.deathTick) then
                life.deathTick = getTickCount()
            end
            if (getTickCount() - life.deathTick >= CLife.deathDisappearTime) then
                table.remove(CLife.instances, i)
            end
        end
    end
end