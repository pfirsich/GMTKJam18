inspect = require("inspect")

local grid = require("grid")
local block = require("block")

grid.init()
block.spawn()
local gridSize = 48
local camY = gridSize * 10

local function isHalted()
    return love.keyboard.isDown("space") or love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
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
        paused = not paused
    end
end

function love.update(dt)
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

function love.draw()
    local lg = love.graphics
    local winW, winH = lg.getDimensions()

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
                    drawBlock(x, y, grid.cells[y][x])
                end
            end
            if grid.lineDirty[y] then
                lg.setColor(0, 0, 0, 0.3)
                lg.rectangle("fill", leftEdge, -y*gridSize, grid.width * gridSize, gridSize)
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
