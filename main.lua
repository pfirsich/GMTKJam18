inspect = require("inspect") -- global for convenience
require("globalUtil") -- ugh

local scenes = require("scenes")

-- global because it's 2h before deadline and everything sucks
drawScale = 1
gridSize = 40
backgroundSize = 100 * gridSize

scenes.import()
scenes.enter(scenes.menu)

function love.resize(w, h)
    drawScale = h/900
    gridSize = math.floor(40 * drawScale)
    backgroundSize = 100 * gridSize
    scenes.callAll("resize", w, h)
end

function love.update(dt)
    scenes.callCurrent("update", dt)
end

function love.draw()
    scenes.callCurrent("draw")
end

function love.keypressed(key)
    scenes.callCurrent("keypressed", key)
    if key == "f11" then
        toggleFullscreen()
    end
end
