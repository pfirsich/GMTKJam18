local sounds = require("sounds")

local grid = {}

function grid.init(width)
    width = width or 10

    grid.cells = {}
    grid.width = width
    grid.top = 0
    grid.score = 0
    grid.lineFull = {}
    grid.lineDirty = {}
    grid.lineGlow = {}
    grid.lineMarker = {}
    grid.lineMarkersDirty = true
end

function grid.checkBlock(block, position)
    position = position or block.position
    for y = 1, #block.grid do
        local gridY = position[2] + y
        for x = 1, #block.grid[y] do
            local gridX = position[1] + x
            if block.grid[y][x] and (grid.cells[gridY] and grid.cells[gridY][gridX] or
                    gridX < 1 or gridX > grid.width or gridY < 1) then
                return false
            end
        end
    end
    return true
end

function grid.isLineFull(y)
    for x = 1, grid.width do
        if not grid.cells[y][x] then
            return false
        end
    end
    return true
end

local function floodFill(x, y, visited)
    -- not a valid cell if out of bounds, visited or a filled grid cell
    if x < 1 or x > grid.width or y < 1 or y > grid.top or
            (visited[y] and visited[y][x]) or grid.cells[y][x] then
        return false
    end
    visited[y] = visited[y] or {}
    visited[y][x] = true
    return floodFill(x+1, y, visited) or floodFill(x-1, y, visited)
        or floodFill(x, y+1, visited) or floodFill(x, y-1, visited)
end

function grid.calculateScore()
    grid.score = 0
    grid.lineMarker = {}
    local markerCounter = 0
    for y = 1, grid.top do
        assert(grid.lineFull[y] ~= nil)
        assert(grid.lineDirty[y] ~= nil)
        if grid.lineFull[y] then
            grid.score = grid.score + 1
            markerCounter = markerCounter + 1
            if not grid.lineFull[y+1] then
                local tetrisBonus = math.floor(markerCounter / 4)
                grid.score = grid.score + tetrisBonus
                grid.lineMarker[y] = "+" .. markerCounter
                if tetrisBonus > 0 then
                    grid.lineMarker[y] = grid.lineMarker[y] .. " (+" .. tetrisBonus .. ")"
                end
                markerCounter = 0
            end
        elseif grid.lineDirty[y] then
            grid.score = grid.score - 1
            markerCounter = markerCounter + 1
            if not grid.lineDirty[y+1] then
                grid.lineMarker[y] = "-" .. markerCounter
                markerCounter = 0
            end
        end
    end
    grid.lineMarkersDirty = true
end

function grid.addBlock(block)
    local playLineFull, playLineDirty = false, false

    for y = 1, #block.grid do
        local gridY = block.position[2] + y
        grid.cells[gridY] = grid.cells[gridY] or {}

        for x = 1, #block.grid[y] do
            local gridX = block.position[1] + x
            if block.grid[y][x] then
                assert(grid.cells[gridY][gridX] == nil) -- make sure we place in an empty cell
                grid.cells[gridY][gridX] = block.color
            end
        end

        grid.top = math.max(grid.top, gridY)
        local lastFull = grid.lineFull[gridY]
        grid.lineFull[gridY] = grid.isLineFull(gridY)
        grid.lineGlow[gridY] = grid.lineGlow[gridY] or 0.0
        if not lastFull and grid.lineFull[gridY] then
            grid.lineGlow[gridY] = 1.0
            playLineFull = true
        end
    end

    local visited = {}
    -- fill reachability from every empty block in the top row
    for x = 1, grid.width do
        if not grid.cells[grid.top][x] then
            floodFill(x, grid.top, visited)
        end
    end

    for y = 1, grid.top do
        if not grid.lineFull[y] and not grid.lineDirty[y] then
            grid.lineDirty[y] = false
            -- check if any empty block in the line is not reachable
            for x = 1, grid.width do
                if not grid.cells[y][x] and (not visited[y] or not visited[y][x]) then
                    grid.lineDirty[y] = true
                    playLineDirty = true
                    break
                end
            end
        end
    end

    if playLineFull then sounds.lineFull:play() end
    if playLineDirty then sounds.lineDirty:play() end

    grid.calculateScore()
end

function grid.update(dt)
    for y = 1, grid.top do
        grid.lineGlow[y] = math.max(0, grid.lineGlow[y] - dt / 1.0)
    end
end

return grid
