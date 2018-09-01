inspect = require("inspect")

local grid = require("grid")
local block = require("block")

grid.init()
block.spawn()
local gridSize = 48
local camY = gridSize * 10
local halted = false

local function isHalted()
    return halted or love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function love.keypressed(key)
    if not isHalted() then
        if key == "up" then
            block.rotate()
        elseif key == "down" then
            block.move(0, -1)
        end
    end

    if key == "left" then
        block.move(-1, 0)
    elseif key == "right" then
        block.move(1, 0)
    elseif key == "space" then
        halted = not halted
    end
end

function love.update(dt)
    grid.update(dt)
    if not isHalted() then
        block.update(dt)
        local targetCamY = math.min(block.position[2] * gridSize - 4 * gridSize, (grid.top + 5) * gridSize)
        camY = camY + (targetCamY - camY) * 1.0 * dt
    else
        local camMove = (love.keyboard.isDown("up") and 1 or 0) - (love.keyboard.isDown("down") and 1 or 0)
        camY = camY + camMove * gridSize * 10 * dt
    end
end

local function drawBlock(x, y, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -grid.width/2 * gridSize + (x-1) * gridSize,
                                    -y*gridSize,
                                    gridSize, gridSize)
end

local function lerp(a, b, t)
    return a * (1 - t) + b * t
end

local function lerpColor(a, b, t)
    local ret = {}
    for i = 1, 3 do ret[i] = lerp(a[i], b[i], t) end
    return ret
end

function love.draw()
    local lg = love.graphics
    local winW, winH = lg.getDimensions()
    local fontH = lg.getFont():getHeight()

    lg.push()
        local leftEdge = -grid.width/2 * gridSize
        local y = math.max(winH/2 + camY, winH - gridSize)
        lg.translate(winW/2, y)

        -- draw borders
        lg.setColor(0.2, 0.2, 0.2, 1.0)
        lg.rectangle("fill", leftEdge - gridSize, 0, (grid.width + 2) * gridSize, gridSize)
        local wallHeight = grid.top * gridSize
        lg.rectangle("fill", leftEdge - gridSize, -wallHeight, gridSize, wallHeight)
        lg.rectangle("fill", -leftEdge, -wallHeight, gridSize, wallHeight)

        -- draw grid
        for y = 1, grid.top do
            for x = 1, grid.width do
                if grid.cells[y][x] then
                    local color = grid.cells[y][x]
                    if grid.lineGlow[y] > 0 then
                        color = lerpColor(color, {1, 1, 1}, grid.lineGlow[y])
                    end
                    drawBlock(x, y, color)
                end
            end
            if grid.lineDirty[y] then
                lg.setColor(0, 0, 0, 0.3)
                lg.rectangle("fill", leftEdge, -y*gridSize, grid.width * gridSize, gridSize)
            end
            if grid.lineMarker[y] then
                lg.setColor(1, 1, 1)
                lg.print(grid.lineMarker[y], leftEdge - gridSize * 2, -y*gridSize + gridSize/2 - fontH/2)
            end
        end

        -- draw block
        for y = 1, #block.grid do
            for x = 1, #block.grid[y] do
                if block.grid[y][x] then
                    drawBlock(x + block.position[1], y + block.position[2], block.color)
                end
            end
        end
    lg.pop()

    lg.setColor(1, 1, 1)
    lg.print(grid.score, 5, 5)
end
