local state = require 'src.state'
local logic = require 'src.logic'

local viewport = {}

function viewport.drawCheckerboard(x, y, w, h, size)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    for i = 0, math.ceil(w / size) - 1 do
        for j = 0, math.ceil(h / size) - 1 do
            if (i + j) % 2 == 0 then
                local cx = x + i * size
                local cy = y + j * size
                local cw = math.min(size, w - i * size)
                local ch = math.min(size, h - j * size)
                love.graphics.rectangle("fill", cx, cy, cw, ch)
            end
        end
    end
end

function viewport.getBounds()
    local panelX = 320
    local panelW = state.screenW - 640

    local fixSize = 256
    local centerX = panelX + (panelW / 2)
    local centerY = state.screenH / 2

    local drawX = centerX - (fixSize / 2)
    local drawY = centerY - (fixSize / 2)

    return drawX, drawY, fixSize, fixSize, panelX, panelW
end

local function getImageTransform()
    local baseX, baseY = viewport.getBounds()
    local zoom = state.viewZoom or 1
    local imgX = baseX + (state.viewPanX or 0)
    local imgY = baseY + (state.viewPanY or 0)
    return imgX, imgY, zoom
end

function viewport.mousepressed(x, y, button)
    if button == 3 then
        state.isPanning = true
        return
    end

    if not state.image or not state.grid then return end

    local imgX, imgY, zoom = getImageTransform()
    local imgW, imgH = state.image:getDimensions()

    local localImgX = (x - imgX) / zoom
    local localImgY = (y - imgY) / zoom

    if localImgX >= 0 and localImgX < imgW and localImgY >= 0 and localImgY < imgH then
        local fw = tonumber(state.inputState.frameWidth.text) or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32
        local l = tonumber(state.inputState.left.text) or 0
        local t = tonumber(state.inputState.top.text) or 0
        local b = tonumber(state.inputState.border.text) or 0

        local localX = localImgX - l
        local localY = localImgY - t

        if localX >= 0 and localY >= 0 then
            local cellX = math.floor(localX / (fw + b)) + 1
            local cellY = math.floor(localY / (fh + b)) + 1

            local cols = math.floor((imgW - l) / (fw + b))
            local rows = math.floor((imgH - t) / (fh + b))

            if cellX >= 1 and cellX <= cols and cellY >= 1 and cellY <= rows then
                if button == 1 then
                    local shift = love.keyboard.isDown("lshift", "rshift")
                    if shift and #state.selectedFrames > 0 then
                        local prev = state.selectedFrames[#state.selectedFrames]
                        local startIdx = (prev.y - 1) * cols + prev.x
                        local endIdx = (cellY - 1) * cols + cellX
                        local step = (endIdx >= startIdx) and 1 or -1
                        for idx = startIdx + step, endIdx, step do
                            local cx = ((idx - 1) % cols) + 1
                            local cy = math.floor((idx - 1) / cols) + 1
                            table.insert(state.selectedFrames, {x = cx, y = cy})
                        end
                    else
                        table.insert(state.selectedFrames, {x = cellX, y = cellY})
                    end
                    logic.createAnimation()
                elseif button == 2 then
                    for i = #state.selectedFrames, 1, -1 do
                        local f = state.selectedFrames[i]
                        if f.x == cellX and f.y == cellY then
                            table.remove(state.selectedFrames, i)
                            logic.createAnimation()
                            break
                        end
                    end
                end
            end
        end
    end
end

function viewport.mousereleased(x, y, button)
    if button == 3 then
        state.isPanning = false
    end
end

function viewport.mousemoved(x, y, dx, dy)
    if state.isPanning then
        state.viewPanX = (state.viewPanX or 0) + dx
        state.viewPanY = (state.viewPanY or 0) + dy
    end
end

function viewport.wheelmoved(x, y)
    if not state.image then return end
    local oldZoom = state.viewZoom or 1
    local factor = y > 0 and 1.15 or (1 / 1.15)
    local newZoom = math.max(0.25, math.min(16, oldZoom * factor))

    local mx, my = love.mouse.getPosition()
    local imgX, imgY = getImageTransform()
    local worldX = (mx - imgX) / oldZoom
    local worldY = (my - imgY) / oldZoom

    local baseX, baseY = viewport.getBounds()
    state.viewZoom = newZoom
    state.viewPanX = mx - baseX - worldX * newZoom
    state.viewPanY = my - baseY - worldY * newZoom
end

function viewport.draw()
    local baseX, baseY, fixW, fixH, panelX, panelW = viewport.getBounds()

    -- Draw middle panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", panelX, 0, panelW, state.screenH)

    love.graphics.setScissor(panelX, 0, panelW, state.screenH)

    if not state.image then
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", baseX, baseY, fixW, fixH)
        love.graphics.setColor(0.4, 0.4, 0.4, 1)
        love.graphics.rectangle("line", baseX, baseY, fixW, fixH)

        love.graphics.setColor(1, 1, 1, 0.5)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.printf("IMPORT SPRITESHEET HERE", baseX, baseY - 20, fixW, "center")
    else
        local imgX, imgY, zoom = getImageTransform()
        local w, h = state.image:getDimensions()
        viewport.drawCheckerboard(imgX, imgY, w * zoom, h * zoom, 16)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(state.image, imgX, imgY, 0, zoom, zoom)

        local fw = tonumber(state.inputState.frameWidth.text) or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32
        local l = tonumber(state.inputState.left.text) or 0
        local t = tonumber(state.inputState.top.text) or 0
        local b = tonumber(state.inputState.border.text) or 0

        local cols = math.floor((w - l) / (fw + b))
        local rows = math.floor((h - t) / (fh + b))

        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 0, 0, 0.7)
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                local cx = imgX + (l + col * fw + (col + 1) * b) * zoom
                local cy = imgY + (t + row * fh + (row + 1) * b) * zoom
                love.graphics.rectangle("line", cx, cy, fw * zoom, fh * zoom)
            end
        end

        for i, f in ipairs(state.selectedFrames) do
            local cx = imgX + (l + (f.x - 1) * fw + f.x * b) * zoom
            local cy = imgY + (t + (f.y - 1) * fh + f.y * b) * zoom
            local cw = fw * zoom
            local ch = fh * zoom

            love.graphics.setColor(1, 0.8, 0, 0.5)
            love.graphics.rectangle("fill", cx, cy, cw, ch)

            love.graphics.setColor(1, 1, 1, 1)
            if state.fontSmall then love.graphics.setFont(state.fontSmall) end
            local txt = tostring(i)
            local tw = state.fontSmall and state.fontSmall:getWidth(txt) or 10
            local th = state.fontSmall and state.fontSmall:getHeight() or 10

            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", cx + cw / 2 - tw / 2 - 2, cy + ch / 2 - th / 2 - 2, tw + 4, th + 4)
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print(txt, cx + cw / 2 - tw / 2, cy + ch / 2 - th / 2)
        end
    end

    love.graphics.setScissor()
end

return viewport
