local grid = require("grid")

-- this is the currently falling block
local block = {}

local letters = {"I", "O", "T", "S", "Z", "J", "L"}
local nextLetterIndex = 1

local colors = {
    I = {0.0, 1.0, 1.0},
    O = {1.0, 1.0, 0.0},
    T = {1.0, 0.0, 1.0},
    S = {0.0, 1.0, 0.0},
    Z = {1.0, 0.0, 0.0},
    J = {0.0, 0.0, 1.0},
    L = {1.0, 0.5, 0.25},
}

-- the center of these squares is the rotation pivot point
-- in the game y = 0 is at the bottom and y grows to the top, here the y index grows to the bottom
-- so all these shapes are flipped along the y axis
local layouts = {
    I = {{0, 0, 0, 0},
         {0, 0, 0, 0},
         {1, 1, 1, 1},
         {0, 0, 0, 0}},

    O = {{1, 1},
         {1, 1}},

    T = {{0, 0, 0},
         {1, 1, 1},
         {0, 1, 0}},

    S = {{0, 0, 0},
         {1, 1, 0},
         {0, 1, 1}},

    Z = {{0, 0, 0},
         {0, 1, 1},
         {1, 1, 0}},

    J = {{0, 0, 0},
         {1, 1, 1},
         {1, 0, 0}},

    L = {{0, 0, 0},
         {1, 1, 1},
         {0, 0, 1}},
}

local dropSpeeds = {1.0, 0.7, 0.5, 0.35, 0.2}
block.dropSpeed = 3
block.maxDropSpeed = #dropSpeeds

-- convert integers to bools (I use 0/1 up there because it fits better and looks nicer)
for letter, blockGrid in pairs(layouts) do
    for y = 1, #blockGrid do
        for x = 1, #blockGrid[y] do
            blockGrid[y][x] = blockGrid[y][x] > 0
        end
    end
end

local function randomizeList(list, start)
    for i = 1, #list - 1 do
        local j = love.math.random(i + 1, #list)
        list[i], list[j] = list[j], list[i]
    end
end

function block.spawn(letter, posY)
    posY = posY or grid.top + 8
    if not letter then
        if nextLetterIndex == 1 then
            randomizeList(letters)
        end
        letter = letters[nextLetterIndex]
        nextLetterIndex = nextLetterIndex + 1
        if nextLetterIndex > #letters then
            nextLetterIndex = 1
        end
    end

    block.letter = letter
    block.grid = layouts[letter]
    local letterWidth = #block.grid[1]
    block.position = {math.floor(grid.width/2 - letterWidth/2), posY}
    block.color = colors[letter]
    block.nextStep = 0
    block.updateDropPos()
end

function block.updateDropPos()
    local dropPos = block.position[2]
    for y = dropPos, 0, -1 do
        if grid.checkBlock(block, {block.position[1], dropPos - 1}) then
            dropPos = dropPos - 1
        else
            break
        end
    end
    block.dropPos = dropPos
end

local function rotatedGrid(grid, dir)
    local w, h = #grid[1], #grid
    local cx, cy = (w - 1) / 2 + 1, (h - 1) / 2 + 1 -- rotation center
    local rotated = {}
    for y = 1, h do
        rotated[y] = {}
        for x = 1, w do
            -- counterclockwise rotation is negative of clockwise rotation
            local rotX, rotY = dir * -(y - cy), dir * (x - cx) -- rotation matrix for 90°
            rotX, rotY = math.floor(rotX + cx + 0.5), math.floor(rotY + cy + 0.5) -- reverse center translation
            rotated[y][x] = grid[rotY][rotX]
        end
    end
    return rotated
end

function block.rotate()
    local oldGrid = block.grid
    block.grid = rotatedGrid(block.grid, 1)
    -- check if it fits, if not, wiggle left and right to see if it fits
    local prePosX = block.position[1]
    for dx = 0, 2 do -- how much we wiggle (I know this checks dx = 0 twice, but I don't mind)
        for dir = -1, 1, 2 do -- wiggle direction
            block.position[1] = prePosX + dir * dx
            if grid.checkBlock(block) then
                block.resetStepClock()
                block.updateDropPos()
                return true
            end
        end
    end
    -- nothing fits => undo everything (just don't do any rotation)
    block.position[1] = prePosX
    block.grid = oldGrid
    return false
end

function block.move(dx, dy)
    local oldPos = block.position
    block.position = {oldPos[1] + dx, oldPos[2] + dy}
    if not grid.checkBlock(block) then
        block.position = oldPos
        if dx == 0 and dy == -1 then
            grid.addBlock(block)
            block.spawn()
        end
        return false
    end
    block.updateDropPos()
    return true
end

function block.drop()
    block.position[2] = block.dropPos
    block.move(0, -1)
end

function block.resetStepClock()
    block.nextStep = dropSpeeds[block.dropSpeed]
end

function block.update(dt)
    local fastFall = love.keyboard.isDown("down")
    block.nextStep = block.nextStep - (fastFall and 5.0 or 1.0) * dt
    if block.nextStep < 0.0 then
        block.resetStepClock()
        block.move(0, -1)
    end
end

return block
