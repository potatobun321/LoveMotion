-- anim8tor_loader.lua
-- Optional single-file runtime helper (MIT) for loading Anim8tor manifest exports.
-- Copy this file into your LÖVE2D project alongside anim8.lua.
--
-- Usage:
--   local anim8tor = require("anim8tor_loader")
--   local hero = anim8tor.load("assets/hero/hero.lua", "lib.anim8")
--   hero.animations.idle:update(dt)
--   hero.animations.idle:draw(hero.image, x, y)

local Loader = {}

function Loader.load(manifestPath, anim8Ref)
    local anim8 = type(anim8Ref) == "table" and anim8Ref or require(anim8Ref or "anim8")

    local chunk, err = love.filesystem.load(manifestPath)
    assert(chunk, "anim8tor_loader: failed to load '" .. tostring(manifestPath) .. "': " .. tostring(err))
    local data = chunk()

    local dir = manifestPath:match("^(.*)/[^/]+$")
    local imgPath = dir and (dir .. "/" .. data.image) or data.image
    local image = love.graphics.newImage(imgPath)

    local g = data.grid or {}
    local grid = anim8.newGrid(
        g.frameW or 32,
        g.frameH or 32,
        image:getWidth(),
        image:getHeight(),
        g.left or 0,
        g.top or 0,
        g.border or 0
    )

    local animations = {}
    for name, def in pairs(data.animations or {}) do
        local frames = grid(unpack(def.frames))
        if def.mode == "pauseAtEnd" then
            animations[name] = anim8.newAnimation(frames, def.duration or 0.1, "pauseAtEnd")
        else
            animations[name] = anim8.newAnimation(frames, def.duration or 0.1)
        end
    end

    return {
        image = image,
        grid = grid,
        animations = animations,
        data = data,
    }
end

return Loader
