local lovemotion = require("lovemotion")

local player = {
    x = 400,
    y = 300,
    speed = 180,
    facing = "down",
    moving = false,
    scale = 2,
    clip = "idle_down"
}

local hero

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    hero = lovemotion.load("assets/player/player.lua", "anim8")
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left")  then dx = dx - 1; player.facing = "left" end
    if love.keyboard.isDown("d", "right") then dx = dx + 1; player.facing = "right" end
    if love.keyboard.isDown("w", "up")    then dy = dy - 1; player.facing = "up" end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1; player.facing = "down" end

    player.moving = (dx ~= 0 or dy ~= 0)
    if player.moving then
        local len = math.sqrt(dx * dx + dy * dy)
        player.x = player.x + (dx / len) * player.speed * dt
        player.y = player.y + (dy / len) * player.speed * dt
    end

    local desired = (player.moving and "walk_" or "idle_") .. player.facing
    if not hero.animations[desired] then
        desired = player.moving and "walk_down" or "idle_down"
    end
    if desired ~= player.clip then
        player.clip = desired
        if hero.animations[player.clip] then
            hero.animations[player.clip]:gotoFrame(1)
        end
    end

    if hero.animations[player.clip] then
        hero.animations[player.clip]:update(dt)
    end
end

function love.draw()
    local sw, sh = love.graphics.getDimensions()

    -- Simple tile grid background
    love.graphics.setColor(0.12, 0.14, 0.17)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setColor(0.18, 0.21, 0.26)
    for x = 0, sw, 32 do love.graphics.line(x, 0, x, sh) end
    for y = 0, sh, 32 do love.graphics.line(0, y, sw, y) end

    -- Draw animated character centered at (player.x, player.y)
    local anim = hero.animations[player.clip]
    if anim then
        local fw = hero.data.grid.frameW or 64
        local fh = hero.data.grid.frameH or 64
        love.graphics.setColor(1, 1, 1)
        anim:draw(hero.image, player.x, player.y, 0, player.scale, player.scale, fw / 2, fh / 2)
    end

    -- HUD
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 12, 12, 430, 68, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LoveMotion Top-Down Demo", 22, 20)
    love.graphics.print("WASD / Arrows: Move   |   Active Clip: " .. player.clip, 22, 40)
    love.graphics.setColor(0.7, 0.85, 1)
    love.graphics.print("Replace assets/player/player.lua + spritesheet to test your own!", 22, 58)
end
