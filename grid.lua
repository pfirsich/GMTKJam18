local grid = {}

function grid.init(width)
    width = width or 10

    grid.cells = {}
    grid.width = width
    grid.top = 0
    grid.score = 0
    grid.lineFull = {}
    grid.lineDirty = {}
end

function grid.checkBlock(block)
    for y = 1, #block.grid do
        local gridY = block.position[2] + y
        for x = 1, #block.grid[y] do
            local gridX = block.position[1] + x
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

function grid.isLineDirty(y)
    return false
end

function grid.calculateScore()
    grid.score = 0
    for y = 1, grid.top do
        assert(grid.lineFull[y] ~= nil)
        assert(grid.lineDirty[y] ~= nil)
        if grid.lineFull[y] then
            grid.score = grid.score + 1
        elseif grid.lineDirty[y] then
            grid.score = grid.score - 1
        end
    end
end

function grid.addBlock(block)
    for y = 1, #block.grid do
        local gridY = block.position[2] + y
        if not grid.cells[gridY] then
            grid.cells[gridY] = {}
        end
        for x = 1, #block.grid[y] do
            local gridX = block.position[1] + x
            if block.grid[y][x] then
                assert(grid.cells[gridY][gridX] == nil) -- make sure we place in an empty cell
                grid.cells[gridY][gridX] = block.color
            end
        end
        grid.top = math.max(grid.top, gridY)
        grid.lineFull[gridY] = grid.isLineFull(gridY)
        grid.lineDirty[gridY] = grid.isLineDirty(gridY)
    end
    grid.calculateScore()
end

return grid
