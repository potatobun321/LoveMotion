-- tests/test_smoke.lua
-- Lightweight headless smoke test for LoveMotion's runtime loader & manifest format.
-- Run from the repo root: lua tests/test_smoke.lua

local sampleManifest = [[
return {
    image = "spritesheet.png",
    grid = { frameW = 32, frameH = 32, left = 0, top = 0, border = 0 },
    animations = {
        ["idle"]   = { frames = { 1, 1, 2, 1 }, duration = 0.2, mode = "loop" },
        ["attack"] = { frames = { 1, 2, 2, 2, 3, 2 }, duration = 0.08, mode = "pauseAtEnd" },
    }
}
]]

-- Minimal LÖVE mock so anim8.lua + runtime/lovemotion.lua can run headlessly
local fakeImage = {
    getWidth = function() return 128 end,
    getHeight = function() return 128 end,
    getDimensions = function() return 128, 128 end,
}

_G.love = {
    filesystem = {
        load = function(path)
            if path == "assets/hero/hero.lua" then
                return loadstring(sampleManifest)
            end
            return nil, "file not found: " .. tostring(path)
        end
    },
    graphics = {
        newImage = function(path)
            assert(path == "assets/hero/spritesheet.png", "unexpected image path: " .. tostring(path))
            return fakeImage
        end,
        newQuad = function(x, y, w, h, sw, sh)
            return { x = x, y = y, w = w, h = h, sw = sw, sh = sh }
        end
    }
}

local loader = require("runtime.lovemotion")
local hero = loader.load("assets/hero/hero.lua", "anim8")

assert(hero.image == fakeImage, "image mismatch")
assert(hero.animations.idle ~= nil, "missing idle animation")
assert(hero.animations.attack ~= nil, "missing attack animation")
assert(#hero.animations.idle.frames == 2, "idle should have 2 frames")
assert(#hero.animations.attack.frames == 3, "attack should have 3 frames")
assert(hero.animations.attack.onLoop == "pauseAtEnd", "attack mode should be pauseAtEnd")

hero.animations.idle:update(0.25)
assert(hero.animations.idle.position == 2, "idle should advance to frame 2")

print("LoveMotion smoke tests: PASS")
