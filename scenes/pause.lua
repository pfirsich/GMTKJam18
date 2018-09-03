local scenes = require("scenes")

local pause = {name = "pause"}

local pauseFontSize = 35
local pauseFont = fontBold(pauseFontSize)

local quitReally = false

function pause.enter()
end

function pause.resize(w, h)
    pauseFont = fontBold(pauseFontSize * drawScale)
end

function pause.keypressed(key)
    if key == "escape" then
        if quitReally then
            love.event.quit()
        else
            quitReally = true
        end
    elseif key == "return" then
        if quitReally then
            quitReally = false
        else
            scenes.enter(scenes.game, true)
        end
    end
end

function pause.update(dt)
    scenes.game.updateGimmicks(dt)
end

function pause.draw()
    local lg = love.graphics
    local winW, winH = lg.getDimensions()

    scenes.game.draw(nil, true, true)

    lg.setColor(1, 1, 1)
    lg.setFont(pauseFont)

    local fontH = pauseFont:getHeight()
    local w = math.floor(winW / 3)
    local h = math.floor(fontH * 3)
    local x = math.floor(winW/2 - w/2)
    local y = math.floor(winH/2 - h/2)

    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", x, y, w, h)
    lg.setColor(1, 1, 1)
    if quitReally then
        lg.printf("Really Quit?", x, math.floor(winH/2 - fontH/2), w, "center")
    else
        lg.printf("<RETURN> to Resume", x, math.floor(winH/2 - fontH), w, "center")
        lg.printf("<ESCAPE> to Quit", x, math.floor(winH/2), w, "center")
    end
end

return pause
