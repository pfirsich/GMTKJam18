local scenes = {}

scenes.current = nil
scenes.list = {}

function scenes.enter(scene, ...)
    assert(scene, "Scene does not exist")
    if scenes.current then
        if scenes.current.exit then
            scenes.current.exit(scene)
        end
    end

    scenes.current = scene
    if scene.enter then
        scene.enter(...)
    end
end

function scenes.call(scene, funcName, ...)
    local func = scene[funcName]
    if func then
        return func(...)
    end
end

function scenes.callCurrent(funcName, ...)
    scenes.call(scenes.current, funcName, ...)
end

function scenes.callAll(funcName, ...)
    for name, scene in pairs(scenes.list) do
        scenes.call(scene, funcName, ...)
    end
end

function scenes.import()
    for _, item in ipairs(love.filesystem.getDirectoryItems("scenes")) do
        local path = "scenes/" .. item

        local reqPath = nil

        if love.filesystem.getInfo(path, "file") and item ~= "init.lua" then
            reqPath = "scenes." .. item:sub(1, -5)
        elseif love.filesystem.getInfo(path, "directory") then
            reqPath = "scenes." .. item
        end

        if reqPath then
            local scene = require(reqPath)
            scenes[scene.name] = scene
            scenes.list[scene.name] = scene
        end
    end
end

return scenes
