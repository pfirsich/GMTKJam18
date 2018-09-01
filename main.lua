inspect = require("inspect")

local grid = require("grid")
local block = require("block")

local backgroundImageData = require("gradient")
local backgroundImage = love.graphics.newImage(backgroundImageData)

local markerFont = love.graphics.newFont(24)
local scoreFont = love.graphics.newFont(40)

grid.init()
block.spawn()
local gridSize = 48
local camY = gridSize * 10
local halted = false

local function isHalted()
    return halted or love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function love.keypressed(key)
    if key == "up" then
        block.rotate()
    elseif key == "down" then
        block.move(0, -1)
    elseif key == "left" then
        block.move(-1, 0)
    elseif key == "right" then
        block.move(1, 0)
    elseif key == "space" then
        halted = not halted
    elseif key == "lctrl" or key == "rctrl" then
        block.drop()
    elseif key == "pageup" then
        block.dropSpeed = math.min(block.maxDropSpeed, block.dropSpeed + 1)
    elseif key == "pagedown" then
        block.dropSpeed = math.max(1, block.dropSpeed - 1)
    end
end

function love.update(dt)
    grid.update(dt)
    if not isHalted() then
        block.update(dt)
        local targetCamY = math.min(block.position[2] * gridSize - 4 * gridSize, (grid.top + 5) * gridSize)
        camY = camY + (targetCamY - camY) * 1.0 * dt
    else
        local camMove = (love.keyboard.isDown("w") and 1 or 0) - (love.keyboard.isDown("s") and 1 or 0)
        camY = camY + camMove * gridSize * 10 * dt
    end
end

local function drawBlock(x, y, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -grid.width/2 * gridSize + (x-1) * gridSize,
                                    -y*gridSize,
                                    gridSize, gridSize)
end

local function clamp(x, lo, hi)
    return math.max(lo or 0, math.min(hi or 1, x))
end

local function lerp(a, b, t)
    return a * (1 - t) + b * t
end

local function lerpColor(a, b, t)
    t = clamp(t)
    local ret = {}
    for i = 1, 3 do
        ret[i] = lerp(a[i], b[i], t)
    end
    ret[4] = (a[4] and b[4]) and lerp(a[4], b[4], t) or (a[4] or b[4] or 1.0)
    return ret
end

local stars = {}
for i = 1, 200 do
    table.insert(stars, {
        x = love.math.random(),
        y = love.math.random(),
        size = love.math.random(2, 7),
    })
end
local starRng = love.math.newRandomGenerator()

function love.draw()
    local lg = love.graphics
    local winW, winH = lg.getDimensions()
    local markerFontH = markerFont:getHeight()

    local drawCamY = math.floor(math.max(winH/2 + camY, winH - gridSize) + 0.5)
    local backgroundSize = 100 * gridSize

    local atmosphereTop = drawCamY - backgroundSize
    starRng:setSeed(42 + drawCamY)
    for i = 1, #stars do
        local star = stars[i]
        local x, y = math.floor(star.x * winW - star.size/2), math.floor(star.y * winH - star.size/2)
        local twinkle = starRng:random()
        if y < atmosphereTop then
            twinkle = 1.0
        else
            local bgH = backgroundImageData:getHeight()
            local bgY = math.floor(clamp((y - atmosphereTop) / backgroundSize) * (bgH - 1))
            local twinkleAmount = select(4, backgroundImageData:getPixel(0, bgY))
            twinkle = twinkleAmount * twinkle + (1.0 - twinkleAmount)
        end
        lg.setColor(twinkle, twinkle, twinkle)
        lg.rectangle("fill", x, y, star.size, star.size)
    end

    lg.push()
        local leftEdge = -grid.width/2 * gridSize
        lg.translate(winW/2, drawCamY)

        lg.push()
            local imgW, imgH = backgroundImage:getDimensions()
            lg.translate(-winW/2, gridSize)
            lg.scale(winW / imgW, backgroundSize / imgH)
            lg.setColor(1, 1, 1)
            lg.draw(backgroundImage, 0, -imgH)
        lg.pop()

        -- draw borders
        lg.setColor(0.2, 0.2, 0.2, 1.0)
        lg.rectangle("fill", leftEdge - gridSize, 0, (grid.width + 2) * gridSize, gridSize)
        local wallHeight = grid.top * gridSize
        lg.rectangle("fill", leftEdge - gridSize, -wallHeight, gridSize, wallHeight)
        lg.rectangle("fill", -leftEdge, -wallHeight, gridSize, wallHeight)

        -- draw grid
        lg.setFont(markerFont)
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
                local textAreaW = gridSize * 4
                local textX = math.floor(leftEdge - textAreaW - gridSize)
                local textY = math.floor(-y*gridSize + gridSize/2 - markerFontH/2)
                lg.printf(grid.lineMarker[y], textX, textY, textAreaW - 10, "right")
            end
        end

        -- draw shadow
        -- local shadowLerp = clamp((camY - backgroundSize * 0.6) / (backgroundSize * 0.1))
        -- local shadowColor = lerpColor({0, 0, 0, 0.15}, {1, 1, 1, 0.2}, shadowLerp)
        local shadowColor = {1, 1, 1, 0.2}
        for y = 1, #block.grid do
            for x = 1, #block.grid[y] do
                if block.grid[y][x] then
                    drawBlock(x + block.position[1], y + block.dropPos, shadowColor)
                end
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
    lg.setFont(scoreFont)
    lg.printf("SCORE\n" .. grid.score, 0, 10, winW/2 - (grid.width/2 + 1) * gridSize - 10, "right")

    lg.print("SPEED\n" .. block.dropSpeed, winW/2 + (grid.width/2 + 1) * gridSize + 10, 10)
end
