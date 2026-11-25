local suit = require 'suit'
local state = require 'src.state'
local logic = require 'src.logic'
local ui_left = require 'src.ui_left'
local ui_right = require 'src.ui_right'
local viewport = require 'src.viewport'

function love.load()
    state.screenW, state.screenH = love.graphics.getDimensions()
    
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Load PressStart2P Font
    local success, font = pcall(love.graphics.newFont, "PressStart2P.ttf", 16)
    local successSmall, fontSmall = pcall(love.graphics.newFont, "PressStart2P.ttf", 10)
    
    if success then state.font = font else state.font = love.graphics.getFont() end
    if successSmall then state.fontSmall = fontSmall else state.fontSmall = love.graphics.getFont() end
    
    suit.theme.color.normal.bg = {0.3, 0.3, 0.3}
    suit.theme.color.hovered.bg = {0.4, 0.4, 0.4}
    suit.theme.color.active.bg = {0.5, 0.5, 0.5}
end

function love.filedropped(file)
    logic.handleFileDropped(file)
end

function love.update(dt)
    if state.toastTimer and state.toastTimer > 0 then
        state.toastTimer = math.max(0, state.toastTimer - dt)
    end
    if state.animation and state.playing then
        state.animation:update(dt)
    end
    ui_left.update()
    ui_right.update()
end

function love.draw()
    viewport.draw()
    ui_left.draw()
    ui_right.draw()
    suit.draw()

    if state.toastTimer and state.toastTimer > 0 and state.toastText ~= "" then
        local tw = (state.fontSmall and state.fontSmall:getWidth(state.toastText) or #state.toastText * 8) + 24
        local tx = (state.screenW - tw) / 2
        local ty = state.screenH - 44
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", tx, ty, tw, 28, 4, 4)
        love.graphics.setColor(0.4, 0.9, 0.5, 1)
        love.graphics.rectangle("line", tx, ty, tw, 28, 4, 4)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(state.toastText, tx, ty + 8, tw, "center")
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Don't register viewport clicks if clicked on the left or right panels
    if x > 320 and x < state.screenW - 320 then
        viewport.mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    viewport.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    viewport.mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    local mx = love.mouse.getX()
    if mx > 320 and mx < state.screenW - 320 then
        viewport.wheelmoved(x, y)
    end
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.resize(w, h)
    state.screenW = w
    state.screenH = h
end
