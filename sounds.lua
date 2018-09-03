require "slam"

local sounds = {}

function prepareSound(name, filename, volume)
    sounds[name] = love.audio.newSource("media/" .. filename, "static")
    sounds[name]:setVolume(volume or 1.0)
end

prepareSound("move", "move.ogg", 0.5)
prepareSound("drop", "drop.ogg", 0.5)
prepareSound("lineDirty", "linedirty.ogg")
prepareSound("lineFull", "linefull.ogg")
prepareSound("rocket", "rocket.ogg")
prepareSound("ufo", "ufo.ogg")

sounds.music = love.audio.newSource("media/tetrizzle.ogg", "static")
sounds.music:setLooping(true)
sounds.music:play()

return sounds
