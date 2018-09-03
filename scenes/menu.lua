local scenes = require("scenes")

local menu = {name = "menu"}

local titleFontSize = 120
local titleFont = fontBold(titleFontSize)

local creditFontSize = 30
local creditFont = font(creditFontSize)

local credits = [[Code:    Joel Schumacher - https://theshoemaker.de/
Music:   jkx feat. Flipso (Jan & Philipp Koerver)]]

local startGameFontSize = 45
local startGameFont = fontBold(startGameFontSize)

local controlsFontSize = 30
local controlsFont = font(controlsFontSize)

local controls = [[Move Block = Arrow Keys
Drop Block = CTRL
Pause Time (you can still move the block!) = Space (toggle), Shift (hold)
Move Camera (while paused) = W/S
Change Speed = Page Up/Page Down]]

local controlsImage = love.graphics.newImage("media/controls.png")

local toggles = [[M to toggle audio
N to toggle music
F11 to toggle fullscreen]]

local menuFirstEnterTime
local controlReadDuration = 5.0

local function controlReadPercent()
    return (love.timer.getTime() - menuFirstEnterTime) / controlReadDuration
end

function menu.enter()
    if not menuFirstEnterTime then
        menuFirstEnterTime = love.timer.getTime()
    end
end

function menu.resize(w, h)
    titleFont = fontBold(titleFontSize * drawScale)
    creditFont = font(creditFontSize * drawScale)
    startGameFont = fontBold(startGameFontSize * drawScale)
    controlsFont = font(controlsFontSize * drawScale)
end

function menu.keypressed(key)
    if key == "return" and controlReadPercent() >= 1.0 then
        scenes.enter(scenes.game)
    end
end

function menu.update(dt)
    scenes.game.updateGimmicks(dt)
end

function menu.draw()
    local lg = love.graphics
    local winW, winH = lg.getDimensions()

    scenes.game.draw(60*gridSize, true)

    lg.setColor(1, 1, 1)

    lg.setFont(titleFont)
    local titleFontH = titleFont:getHeight()
    local titleFontY = 10
    lg.printf("SPACETRIS", 0, titleFontY, winW, "center")

    lg.setFont(creditFont)
    local creditFontH = creditFont:getHeight()
    local creditsY = math.floor(winH - creditFontH * 2 - 10)
    shadowText(credits, 10, creditsY, 1)

    local toggleY = math.floor(winH - creditFontH * 3 - 10)
    shadowTextFRight(toggles, 0, toggleY, winW - 10, 1)

    local deltaRead = controlReadPercent()
    local startGameFontH = startGameFont:getHeight()
    local startTextY = math.floor(winH - creditFontH * 3 - startGameFontH)
    if deltaRead > 1.0 then
        lg.setFont(startGameFont)
        local show = math.cos(love.timer.getTime() * 2.0 * math.pi) > 0.5
        if show then
            shadowTextFCenter("PRESS RETURN TO START", 0, startTextY, winW, 2)
        end
    else
        local w = 500
        local h = 50
        local x = winW/2 - w/2
        lg.rectangle("line", x, startTextY, w, h)
        local barW = math.floor(w * math.min(1, deltaRead))
        lg.rectangle("fill", x, startTextY, barW, h)
    end

    lg.setFont(controlsFont)
    local controlsFontH = controlsFont:getHeight()
    local controlsY = titleFontY + titleFontH + 0
    local height = startTextY - controlsY
    --lg.printf(controls, 0, titleFontY + titleFontH + controlsFontH, winW, "center")
    local scale = height/controlsImage:getHeight()
    lg.draw(controlsImage, winW/2, controlsY, 0, scale, scale, controlsImage:getWidth()/2)
end

return menu
