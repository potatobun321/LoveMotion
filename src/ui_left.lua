local suit = require 'suit'
local state = require 'src.state'
local logic = require 'src.logic'

local ui_left = {}

function ui_left.update()
    local panelW = 320
    local padding = 16
    local fullW = panelW - padding * 2
    local inputW = fullW - 110

    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, panelW, state.screenH)
    love.graphics.setColor(1, 1, 1, 1)

    suit.layout:reset(padding, padding, 6)

    suit.Label("LOVEMOTION", {align="left", font=state.font}, suit.layout:row(fullW, 24))

    -- Image dimensions & remainder indicator
    if state.image then
        local iw, ih = state.image:getDimensions()
        local fw = tonumber(state.inputState.frameWidth.text) or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32
        local l = tonumber(state.inputState.left.text) or 0
        local t = tonumber(state.inputState.top.text) or 0
        local b = tonumber(state.inputState.border.text) or 0
        local remX = (iw - l) % math.max(1, fw + b)
        local remY = (ih - t) % math.max(1, fh + b)
        local infoTxt = string.format("%dx%dpx (rem %d,%d)", iw, ih, remX, remY)
        suit.Label(infoTxt, {align="left", font=state.fontSmall}, suit.layout:row(fullW, 18))
    end

    -- Grid mode toggle + AUTO-DETECT + FIT
    local mr1x, mr1y = suit.layout:row(fullW, 22)
    local hw = math.floor((fullW - 6) / 2)
    local gModeTxt = (state.gridMode == "count") and "BY COUNT" or "BY PIXELS"
    if suit.Button(gModeTxt, {id="grid_mode", font=state.fontSmall}, mr1x, mr1y, hw, 22).hit then
        state.gridMode = (state.gridMode == "count") and "pixels" or "count"
        if state.gridMode == "count" then logic.applyCountGrid() end
    end
    if suit.Button("AUTO", {id="auto_detect", font=state.fontSmall}, mr1x + hw + 6, mr1y, hw, 22).hit then
        logic.autoDetectGrid()
    end

    -- Quick size presets + FIT zoom
    local prx, pry = suit.layout:row(fullW, 24)
    local bw = math.floor((fullW - 12) / 4)
    for idx, sz in ipairs({16, 32, 64}) do
        if suit.Button(tostring(sz), {id="p"..sz, font=state.fontSmall}, prx + (idx - 1) * (bw + 4), pry, bw, 22).hit then
            state.gridMode = "pixels"
            state.inputState.frameWidth.text = tostring(sz)
            state.inputState.frameHeight.text = tostring(sz)
            logic.updateGrid()
        end
    end
    if suit.Button("FIT", {font=state.fontSmall}, prx + 3 * (bw + 4), pry, bw, 22).hit then
        logic.fitViewport()
    end

    local function addField(label, inputStateObj, onChange, minVal)
        local rx, ry = suit.layout:row(fullW, 22)
        suit.Label(label, {align="left", font=state.fontSmall}, rx, ry, 100, 22)
        local boxW = fullW - 152
        if suit.Input(inputStateObj, {font=state.fontSmall}, rx + 100, ry, boxW, 22).changed then
            onChange()
        end
        if suit.Button("-", {id="dec_"..label, font=state.fontSmall}, rx + 104 + boxW, ry, 22, 22).hit then
            local v = math.max(minVal or 0, (tonumber(inputStateObj.text) or 0) - 1)
            inputStateObj.text = tostring(v)
            onChange()
        end
        if suit.Button("+", {id="inc_"..label, font=state.fontSmall}, rx + 128 + boxW, ry, 22, 22).hit then
            local v = (tonumber(inputStateObj.text) or 0) + 1
            inputStateObj.text = tostring(v)
            onChange()
        end
    end

    if state.gridMode == "count" then
        addField("Cols:", state.inputState.cols, logic.applyCountGrid, 1)
        addField("Rows:", state.inputState.rows, logic.applyCountGrid, 1)
        addField("Margin L:", state.inputState.left, logic.applyCountGrid, 0)
        addField("Margin T:", state.inputState.top, logic.applyCountGrid, 0)
        addField("Border:", state.inputState.border, logic.applyCountGrid, 0)
    else
        addField("Frame W:", state.inputState.frameWidth, logic.updateGrid, 1)
        addField("Frame H:", state.inputState.frameHeight, logic.updateGrid, 1)
        addField("Margin L:", state.inputState.left, logic.updateGrid, 0)
        addField("Margin T:", state.inputState.top, logic.updateGrid, 0)
        addField("Border:", state.inputState.border, logic.updateGrid, 0)
    end

    suit.layout:row(fullW, 6)
    local clipNames = {}
    for k in pairs(state.clips) do table.insert(clipNames, k) end
    table.sort(clipNames)
    suit.Label("CLIPS (" .. #clipNames .. ")", {align="left", font=state.font}, suit.layout:row(fullW, 20))
    suit.Label(table.concat(clipNames, ", "), {align="left", font=state.fontSmall}, suit.layout:row(fullW, 16))

    -- Clip switcher row: <  clipName  >  +  X
    local crx, cry = suit.layout:row(fullW, 24)
    if suit.Button("<", {id="clip_prev", font=state.fontSmall}, crx, cry, 26, 22).hit then
        logic.cycleClip(-1)
    end
    if suit.Input(state.inputState.clipName, {id="clip_name", font=state.fontSmall}, crx + 30, cry, fullW - 122, 22).submitted then
        logic.commitClipName()
    end
    if suit.Button(">", {id="clip_next", font=state.fontSmall}, crx + fullW - 88, cry, 26, 22).hit then
        logic.cycleClip(1)
    end
    if suit.Button("+", {id="clip_new", font=state.fontSmall}, crx + fullW - 58, cry, 26, 22).hit then
        logic.newClip()
    end
    if suit.Button("X", {id="clip_del", font=state.fontSmall}, crx + fullW - 28, cry, 28, 22).hit then
        logic.deleteActiveClip()
    end

    local durNum = tonumber(state.inputState.duration.text) or 0.1
    if durNum >= state.durationSlider.min and durNum <= state.durationSlider.max then
        state.durationSlider.value = durNum
    end
    local fps = math.floor((1 / math.max(0.01, durNum)) + 0.5)
    suit.Label(string.format("Dur: %.2fs (%d FPS)", durNum, fps), {align="left", font=state.fontSmall}, suit.layout:row(fullW, 18))
    if suit.Slider(state.durationSlider, {id="dur_slider"}, suit.layout:row(fullW, 20)).changed then
        state.inputState.duration.text = string.format("%.2f", state.durationSlider.value)
        logic.createAnimation()
    end

    local mrx, mry = suit.layout:row(fullW, 24)
    local modeText = (logic.getActiveMode() == "pauseAtEnd") and "MODE: ONCE" or "MODE: LOOP"
    local hw = math.floor((fullW - 6) / 2)
    if suit.Button(modeText, {id="clip_mode", font=state.fontSmall}, mrx, mry, fullW, 22).hit then
        logic.toggleClipMode()
    end

    local prx2, pry2 = suit.layout:row(fullW, 22)
    if suit.Button("TOP-DOWN", {id="pre_td", font=state.fontSmall}, prx2, pry2, hw, 22).hit then
        logic.applyClipPreset("topdown")
    end
    if suit.Button("SIDE", {id="pre_side", font=state.fontSmall}, prx2 + hw + 6, pry2, hw, 22).hit then
        logic.applyClipPreset("side")
    end

    local arx, ary = suit.layout:row(fullW, 24)
    if suit.Button("REFRESH", {font=state.fontSmall}, arx, ary, hw, 24).hit then
        logic.updateGrid()
    end
    if suit.Button("CLEAR", {font=state.fontSmall}, arx + hw + 6, ary, hw, 24).hit then
        state.selectedFrames = {}
        logic.createAnimation()
    end

    suit.layout:row(fullW, 8)
    suit.Label("EXPORT", {align="left", font=state.font}, suit.layout:row(fullW, 22))

    local erx, ery = suit.layout:row(fullW, 24)
    suit.Label("File:", {align="left", font=state.fontSmall}, erx, ery, 70, 24)
    suit.Input(state.inputState.exportName, {font=state.fontSmall}, erx + 70, ery, fullW - 70, 24)

    if suit.Button("SAVE MANIFEST", {font=state.fontSmall}, suit.layout:row(fullW, 32)).hit then
        logic.saveToDisk()
    end
end

function ui_left.draw()
    -- SUIT draws globally in main.lua
end

return ui_left
