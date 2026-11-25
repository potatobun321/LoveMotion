local state = require 'src.state'
local viewport = require 'src.viewport'
local logic = require 'src.logic'
local suit = require 'suit'

local ui_right = {}

function ui_right.update()
    local panelW = 320
    local panelX = state.screenW - panelW
    local padding = 20

    -- Playback controls below preview box
    local ctrlY = math.floor(state.screenH / 2) - 34
    local bw = math.floor((panelW - padding * 2 - 12) / 4)
    if suit.Button("<", {id="prev_frame", font=state.fontSmall}, panelX + padding, ctrlY, bw, 24).hit then
        logic.stepFrame(-1)
    end
    local playLabel = state.playing and "PAUSE" or "PLAY"
    if suit.Button(playLabel, {id="play_pause", font=state.fontSmall}, panelX + padding + bw + 4, ctrlY, bw, 24).hit then
        state.playing = not state.playing
    end
    if suit.Button(">", {id="next_frame", font=state.fontSmall}, panelX + padding + (bw + 4) * 2, ctrlY, bw, 24).hit then
        logic.stepFrame(1)
    end
    local flipLabel = state.flipH and "FLIP*" or "FLIP"
    if suit.Button(flipLabel, {id="flip_h", font=state.fontSmall}, panelX + padding + (bw + 4) * 3, ctrlY, bw, 24).hit then
        state.flipH = not state.flipH
    end

    if state.generatedCode ~= "" and state.errorMessage == "" then
        local buttonY = state.screenH - 50
        if suit.Button("COPY SNIPPET", {font=state.fontSmall}, panelX + padding, buttonY, panelW - padding*2, 30).hit then
            love.system.setClipboardText(state.generatedCode)
        end
    end
end

function ui_right.draw()
    local panelW = 320
    local panelX = state.screenW - panelW
    local padding = 20

    love.graphics.setColor(0.12, 0.12, 0.12, 1)
    love.graphics.rectangle("fill", panelX, 0, panelW, state.screenH)

    if state.font then love.graphics.setFont(state.font) end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("PREVIEW", panelX + padding, padding)

    local previewY = padding + 36
    local previewAreaH = (state.screenH / 2) - previewY - 40

    local previewBoxX = panelX + padding
    local previewBoxW = panelW - padding*2

    love.graphics.setColor(0.08, 0.08, 0.08, 1)
    love.graphics.rectangle("fill", previewBoxX, previewY, previewBoxW, previewAreaH)

    if state.errorMessage ~= "" then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.printf("ERROR:\n" .. state.errorMessage, previewBoxX + 10, previewY + 10, previewBoxW - 20, "left")
    elseif state.animation and state.image then
        local fw = tonumber(state.inputState.frameWidth.text) or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32

        local scaleX = (previewBoxW - 20) / fw
        local scaleY = (previewAreaH - 20) / fh
        local pScale = math.min(scaleX, scaleY)
        if pScale > 1 then pScale = math.floor(pScale) end

        local drawW = fw * pScale
        local drawH = fh * pScale
        local drawX = previewBoxX + (previewBoxW / 2) - (drawW / 2)
        local drawY = previewY + (previewAreaH / 2) - (drawH / 2)

        viewport.drawCheckerboard(drawX, drawY, drawW, drawH, 16)

        love.graphics.setColor(1, 1, 1, 1)
        local sx = state.flipH and -pScale or pScale
        local ox = state.flipH and fw or 0
        state.animation:draw(state.image, drawX, drawY, 0, sx, pScale, ox, 0)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.print("CLICK TO ADD", previewBoxX + 10, previewY + 10)
    end

    -- Code Section (Lower half)
    local codeY = state.screenH / 2
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", panelX, codeY, panelW, state.screenH - codeY)

    love.graphics.setColor(1, 1, 1, 1)
    if state.font then love.graphics.setFont(state.font) end
    love.graphics.print("SNIPPET (" .. tostring(state.activeClip) .. ")", panelX + padding, codeY + padding)

    if state.generatedCode ~= "" and state.errorMessage == "" then
        love.graphics.setColor(0.6, 1, 0.6, 1)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.printf(state.generatedCode, panelX + padding, codeY + padding + 36, panelW - padding*2)
    end
end

return ui_right
