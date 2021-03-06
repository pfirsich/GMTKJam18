local grid = require("grid")
local block = require("block")
local sounds = require("sounds")
local scenes = require("scenes")

local game = {name = "game"}

local camY = 0
local halted = false

local backgroundImageData = require("gradient")
local backgroundImage = love.graphics.newImage(backgroundImageData)

local tetrisRocket = love.graphics.newImage("media/tetris_rocket.png")
tetrisRocket:setFilter("nearest", "nearest")
local fireFrames = {}
for i = 1, 2 do
    fireFrames[i] = love.graphics.newImage(("media/tetris_rocket_fire_%d.png"):format(i))
    fireFrames[i]:setFilter("nearest", "nearest")
end
local rocketHeightFactor = 1.5
local rocketHeight = backgroundSize * rocketHeightFactor
local rocketPosition = nil
local rocketAngle = 0.1 * math.pi

local ufoHeightFactor = 1.25
local ufoHeight = backgroundSize * ufoHeightFactor
local ufoPosition = nil

local markerFontSize = 24
local markerFont = font(markerFontSize)
local scoreFontSize = 52
local scoreFont = font(scoreFontSize)

local scoreMarkerText = love.graphics.newText(markerFont)
local heightMarkerText = love.graphics.newText(markerFont)
local heightMarkerInText = {}

local randf = function(lo, hi)
    lo = lo or 0
    hi = hi or 1
    return lo + love.math.random() * (hi - lo)
end
local jitter = function(minMag, maxMag)
    return (randf() > 0.5 and 1 or -1) * randf(minMag, maxMag)
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

local cloudDebugColors = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}
local clouds = {}
local cloudWidth = 200
local cloudHeight = 80
local cloudCount = 25
local winW = love.graphics.getWidth()
for i = 1, cloudCount do
    local z = 1.0 + (1.0 - (i-1) / (cloudCount - 1)) * 4.0
    local x = randf() * winW * z
    local y = randf(-1, 1) * 200
    for j = 1, 3 do
        local w, h = randf(1.0, 2.0) * cloudWidth, randf(1.0, 2.0) * cloudHeight
        table.insert(clouds, {
            debugColor = cloudDebugColors[j],
            x = x, y = y, z = z,
            w = w, h = h
        })
        -- shift slightly
        x = x + cloudWidth * jitter(0.5, 0.9)
        y = y + cloudHeight * jitter(0.5, 0.9)
    end
end

local function isHalted()
    return halted or love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function game.enter(noInit)
    if not noInit then
        grid.init()
        block.spawn()
        camY = 0
    end
end
-- init stuff before we actually enter the scene, so game.draw works in other scenes
game.enter()

local function rebuildMarkerText()
    local leftEdge = -grid.width/2 * gridSize
    local markerFontH = markerFont:getHeight()
    scoreMarkerText:clear()
    for y = 1, grid.top do
        if grid.lineMarker[y] then
            local textAreaW = gridSize * 4
            local textX = math.floor(leftEdge - textAreaW - gridSize)
            local textY = math.floor(-y*gridSize + gridSize/2 - markerFontH/2)
            scoreMarkerText:addf(grid.lineMarker[y], textAreaW - 10, "right", textX, textY)
        end
    end
end

function game.resize(w, h)
    rocketHeight = backgroundSize * rocketHeightFactor
    ufoHeight = backgroundSize * ufoHeightFactor

    markerFont = font(markerFontSize * drawScale)
    scoreFont = font(scoreFontSize * drawScale)

    scoreMarkerText:setFont(markerFont)
    heightMarkerText:setFont(markerFont)

    heightMarkerText:clear()
    heightMarkerInText = {}

    rebuildMarkerText()
end

function game.keypressed(key)
    if key == "up" or key == "x" or key == "i" then
        if block.rotate() then
            sounds.move:play()
        end
    elseif key == "down" or key == "k" then
        if block.move(0, -1) then
            sounds.move:play()
        end
    elseif key == "left" or key == "j" then
        if block.move(-1, 0) then
            sounds.move:play()
        end
    elseif key == "right" or key == "l" then
        if block.move(1, 0) then
            sounds.move:play()
        end
    elseif key == "space" then
        halted = not halted
    elseif key == "lctrl" or key == "rctrl" then
        block.drop()
    elseif key == "pageup" then
        block.dropSpeed = math.min(block.maxDropSpeed, block.dropSpeed + 1)
    elseif key == "pagedown" then
        block.dropSpeed = math.max(1, block.dropSpeed - 1)
    elseif key == "escape" then
        scenes.enter(scenes.pause)
    end
end

function game.gamepadpressed(joystick, button)
    if button == "a" or button == "dpup" then
        game.keypressed("up")
    elseif button == "dpdown" then
        game.keypressed("down")
    elseif button == "dpleft" then
        game.keypressed("left")
    elseif button == "dpright" then
        game.keypressed("right")
    elseif button == "x" then
        game.keypressed("lctrl")
    elseif button == "b" then
        game.keypressed("space")
    end
end

local lastAxis = {}
local axisFresh = {}
function game.gamepadaxis(joystick, axis, value)
    local id = joystick:getID()
    lastAxis[id] = lastAxis[id] or {}
    axisFresh[id] = axisFresh[id] or {}

    local pressThresh = 0.7
    local freshThresh = 0.4
    local lastAbsValue = math.abs(lastAxis[id][axis] or 0)
    lastAxis[id][axis] = value
    if math.abs(value) < freshThresh then
        axisFresh[id][axis] = true
    end
    local pressed = math.abs(value) >= pressThresh and lastAbsValue < pressThresh and axisFresh[id][axis]

    if pressed then
        axisFresh[id][axis] = false
        if axis == "leftx" then
            if value > 0 then
                game.keypressed("right")
            else
                game.keypressed("left")
            end
        elseif axis == "lefty" then
            if value > 0 then
                game.keypressed("down")
            else
                game.keypressed("up")
            end
        end
    end
end

function game.updateGimmicks(dt)
    local winW, winH = love.graphics.getDimensions()

    if camY > ufoHeight and not ufoPosition then
        ufoPosition = winW/2
        sounds.ufo:play()
    end
    if ufoPosition then
        ufoPosition = ufoPosition - winW/2.5 * dt
    end

    if camY > rocketHeight and not rocketPosition then
        rocketPosition = -winW/2 - 200
        sounds.rocket:play()
    end
    if rocketPosition then
        local xVel = winW/3.0
        local speed = xVel / math.cos(rocketAngle)
        rocketPosition = rocketPosition + xVel * dt
        rocketHeight = rocketHeight + math.sin(rocketAngle) * speed * dt
    end

    for i = 1, #clouds do
        local cloud = clouds[i]
        cloud.x = cloud.x + winW/8.0 * dt
        if cloud.x / cloud.z > winW then
            cloud.x = cloud.x - winW * cloud.z
        end
    end
end

function game.update(dt)
    local winW, winH = love.graphics.getDimensions()

    grid.update(dt)
    if not isHalted() then
        block.update(dt)
        local targetCamY = math.min(block.position[2] * gridSize - 4 * gridSize, (grid.top + 5) * gridSize)
        camY = camY + (targetCamY - camY) * 1.0 * dt
    else
        local camMove = (love.keyboard.isDown("w") and 1 or 0) - (love.keyboard.isDown("s") and 1 or 0)
        camY = camY + camMove * gridSize * 15 * dt
    end
    camY = math.max(camY, winH/2 - gridSize)

    game.updateGimmicks(dt)
end

local function drawBlock(x, y, color)
    local x, y = -grid.width/2 * gridSize + (x-1) * gridSize, -y*gridSize
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, gridSize, gridSize)
    --love.graphics.setColor(0, 0, 0)
    --love.graphics.rectangle("fill", x + 2, y + 2, gridSize - 4, gridSize - 4)
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

function game.draw(_camY, hideScoreText, zoomOut)
    local lg = love.graphics
    local winW, winH = lg.getDimensions()
    local markerFontH = markerFont:getHeight()

    local zoomOutScale = 1.0
    if zoomOut then
        zoomOutScale = winH / math.max(winH, (grid.top + 3) * gridSize)
    end

    _camY = _camY or camY -- give the possibility to override as argument
    if zoomOut then
        _camY = winH/2 - gridSize * zoomOutScale
    end

    local drawCamY = math.floor(winH/2 + _camY + 0.5)

    local atmosphereTop = drawCamY - backgroundSize
    starRng:setSeed(42 + drawCamY)
    lg.push()
        --lg.translate((1 - zoomOutScale) / 2.0 * winW, 0)
        for i = 1, #stars do
            local star = stars[i]
            local size = star.size
            local xScale = 1.0 --zoomOutScale
            local x = math.floor(star.x * winW * xScale - size/2)
            local y = math.floor(star.y * winH - size/2)
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
            lg.rectangle("fill", x, y, size, size)
        end
    lg.pop()

    lg.push()
        local leftEdge = -grid.width/2 * gridSize
        lg.translate(winW/2, drawCamY)
        lg.scale(1, zoomOutScale)

        -- draw background
        lg.push()
            local imgW, imgH = backgroundImage:getDimensions()
            lg.translate(-winW/2, gridSize)
            lg.scale(winW / imgW, backgroundSize / imgH)
            lg.setColor(1, 1, 1)
            lg.draw(backgroundImage, 0, -imgH)
        lg.pop()

        lg.scale(zoomOutScale, 1)

        -- draw other background elements
        -- clouds
        local cloudRepetitions = math.floor(1/zoomOutScale + 1)
        for c = 1, #clouds do
            local cloud = clouds[c]
            for r = 1, cloudRepetitions do
                local offset = (r - 1) * winW

                -- for the first one, only render the center
                -- for all further ones, render left and right
                -- and then render one extra on the left (the extra is the +1 in cloudRepetitions)
                local sideFrom, sideTo, sideStep = 0, 0, 1
                if r == cloudRepetitions then
                    sideFrom, sideTo, sideStep = -1, -1, 1
                elseif r > 1 then
                    sideFrom, sideTo, sideStep = -1, 1, 2
                end

                for s = sideFrom, sideTo, sideStep do
                    local cloudsY = -backgroundSize * 0.4
                    local cloudAlpha = 1.0
                    lg.setColor(lerpColor({1, 1, 1, cloudAlpha},
                                          {0.8, 0.8, 1.0, cloudAlpha},
                                          (cloud.z - 1.0) / 1.0))
                    local x = cloud.x / cloud.z - winW/2
                    x = x + offset * s
                    local y = -_camY + (cloud.y + cloudsY + _camY) / cloud.z
                    local w = math.floor(cloud.w / cloud.z * drawScale)
                    local h = math.floor(cloud.h / cloud.z * drawScale)
                    lg.rectangle("fill", x, y, w, h)
                end
            end
        end

        -- moon
        local moonHeight = backgroundSize * 0.96
        lg.setColor(0.6, 0.6, 0.6)
        lg.push()
            local moonZ = 1.5
            lg.translate(-leftEdge + 100, -moonHeight / moonZ - _camY * (1 - 1/moonZ))
            lg.scale(drawScale)
            lg.rectangle("fill", -25, 25, 350, 250)
            lg.rectangle("fill", 25, -25, 250, 350)
            lg.setColor(0.3, 0.3, 0.3)
            lg.rectangle("fill", 50, 50, 100, 100)
            lg.rectangle("fill", 90, 100, 80, 80)
            lg.rectangle("fill", 140, 50, 50, 50)
            lg.rectangle("fill", 40, 50, 40, 200)
            lg.rectangle("fill", 200, 200, 50, 50)
        lg.pop()

        -- ufo
        if ufoPosition and ufoPosition > -winW/2*1.5 then
            local ufoY = -backgroundSize * 0.2
            lg.push()
                lg.translate(ufoPosition, -ufoHeight)
                lg.scale(drawScale)
                lg.rotate(-0.1 * math.pi)
                lg.setColor(0.8, 0.8, 0.8) -- disc
                lg.rectangle("fill", 0, 0, 300, 60)
                lg.rectangle("fill", 20, -20, 260, 100)
                lg.setColor(0.2, 0.7, 0.2) -- alien
                lg.rectangle("fill", 150 - 20, -40, 40, 20)
                lg.rectangle("fill", 150 - 10, -60, 20, 20)
                lg.setColor(0.5, 0.5, 1.0, 0.7) -- window
                lg.rectangle("fill", 40, -40, 220, 30)
                lg.rectangle("fill", 50, -70, 200, 30)
            lg.pop()
        end

        -- rocket
        if rocketPosition and rocketPosition < winW/2*1.5 then
            lg.push()
                lg.translate(rocketPosition, -rocketHeight)
                lg.rotate(-rocketAngle + math.pi * 0.5)
                lg.scale(3 * drawScale)
                lg.setColor(1, 1, 1)
                local fireFrame = fireFrames[(love.timer.getTime() % 0.5) > 0.25 and 1 or 2]
                lg.draw(tetrisRocket, 0, 0, 0, 1, 1, tetrisRocket:getWidth()/2, tetrisRocket:getHeight()/2)
                lg.draw(fireFrame, 0, tetrisRocket:getHeight()/2, 0, 1, 1, fireFrame:getWidth()/2, 0)
            lg.pop()
        end

        -- draw borders
        lg.setColor(0.2, 0.2, 0.2, 1.0)
        lg.rectangle("fill", leftEdge - gridSize, 0, (grid.width + 2) * gridSize, gridSize)
        local wallHeight = grid.top * gridSize
        lg.rectangle("fill", leftEdge - gridSize, -wallHeight, gridSize, wallHeight)
        lg.rectangle("fill", -leftEdge, -wallHeight, gridSize, wallHeight)

        -- draw grid
        if grid.lineMarkersDirty then
            rebuildMarkerText()
            grid.lineMarkersDirty = false
        end

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
                lg.setColor(0, 0, 0, 0.2)
                lg.rectangle("fill", leftEdge, -y*gridSize, grid.width * gridSize, gridSize)
            end

            if y % 50 == 0 and not heightMarkerInText[y] then
                local textY = math.floor(-y*gridSize + gridSize/2 - markerFontH/2)
                heightMarkerText:add("Height: " .. y, math.floor(-leftEdge + gridSize + 10), textY)
                heightMarkerInText[y] = true
            end
        end

        if not zoomOut then
            lg.setColor(1, 1, 1)
            love.graphics.draw(scoreMarkerText)
            love.graphics.draw(heightMarkerText)
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
    if not hideScoreText then
        lg.setFont(scoreFont)
        local scoreText =
        shadowTextFRight("SCORE\n" .. grid.score, 0, 10, winW/2 - (grid.width/2 + 1) * gridSize - 10)
        shadowText("SPEED\n" .. block.dropSpeed, winW/2 + (grid.width/2 + 1) * gridSize + 10, 10)
    end
end

return game
