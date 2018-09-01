local gradientHeight = 4096
local gradientData = love.image.newImageData(1, 4096)
local gradient = {
    {y = 0, color = {0, 0, 0, 0}},
    {y = 0.3, color = {0, 0.278, 0.533, 0.7}},
    {y = 0.5, color = {0, 0.58, 0.733, 0.9}},
    {y = 0.7, color = {0.17, 0.764, 0.831, 1.0}},
    {y = 0.9, color = {0.89, 0.796, 0.624, 1.0}},
    {y = 1.0, color = {0.733, 0.384, 0.251, 1.0}},
}

for y = 0, gradientHeight - 1 do
    local py = y / (gradientHeight - 1)
    local interpFrom, interpTo = nil, gradient[#gradient]
    for i, part in ipairs(gradient) do
        if part.y >= py then
            interpTo = part
            break
        end
        interpFrom = part
    end
    local color
    if interpFrom then
        local frac = (py - interpFrom.y) / (interpTo.y - interpFrom.y)
        color = {}
        for i = 1, 4 do
            color[i] = interpFrom.color[i] * (1 - frac) + interpTo.color[i] * frac
        end
    else
        color = interpTo.color
    end
    gradientData:setPixel(0, y, unpack(color))
end

return gradientData
