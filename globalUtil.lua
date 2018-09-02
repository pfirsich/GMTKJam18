function font(size)
    return love.graphics.newFont("media/Lato-Regular.ttf", size)
end

function fontBold(size)
    return love.graphics.newFont("media/Lato-Bold.ttf", size)
end

function shadowText(text, x, y, offset)
    offset = offset or 3
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + offset, y + offset)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x, y)
end

function shadowTextFRight(text, x, y, wrap, offset)
    offset = offset or 3
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(text, x, y + offset, wrap + offset, "right")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, x, y, wrap, "right")
end

function shadowTextFCenter(text, x, y, wrap, offset)
    offset = offset or 3
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(text, x + offset, y + offset, wrap + offset, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, x, y, wrap, "center")
end

function toggleFullscreen()
    local w, h, flags = love.window.getMode()
    if flags.fullscreen then
        flags = {
            vsync = 1,
            resizable = true,
        }
        love.window.setMode(defaultResW, defaultResH, flags)
        love.resize(defaultResW, defaultResH)
    else
        autoFullscreen()
    end
end

function filter(list, func)
    local ret = {}
    for i = 1, #list do
        if func(list[i]) then ret[#ret+1] = list[i] end
    end
    return ret
end

function autoFullscreen()
    local supported = love.window.getFullscreenModes()
    table.sort(supported, function(a, b) return a.width*a.height < b.width*b.height end)

    local scrWidth, scrHeight = love.window.getDesktopDimensions()
    supported = filter(supported, function(mode) return mode.width*scrHeight == scrWidth*mode.height end)

    local max = supported[#supported]
    local flags = {fullscreen = true}
    if not love.window.setMode(max.width, max.height, flags) then
        error(string.format("Resolution %dx%d could not be set successfully.", w, h))
    end
    love.resize(max.width, max.height)
end
