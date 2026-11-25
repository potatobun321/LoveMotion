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

    suit.Label("ANIM8TOR", {align="left", font=state.font}, suit.layout:row(fullW, 24))

    -- Quick size presets + FIT zoom
    local prx, pry = suit.layout:row(fullW, 24)
    local bw = math.floor((fullW - 12) / 4)
    for idx, sz in ipairs({16, 32, 64}) do
        if suit.Button(tostring(sz), {id="p"..sz, font=state.fontSmall}, prx + (idx - 1) * (bw + 4), pry, bw, 22).hit then
            state.inputState.frameWidth.text = tostring(sz)
            state.inputState.frameHeight.text = tostring(sz)
            logic.updateGrid()
        end
    end
    if suit.Button("FIT", {font=state.fontSmall}, prx + 3 * (bw + 4), pry, bw, 22).hit then
        logic.fitViewport()
    end

    local function addField(label, inputStateObj, onChange)
        local rx, ry = suit.layout:row(fullW, 22)
        suit.Label(label, {align="left", font=state.fontSmall}, rx, ry, 110, 22)
        if suit.Input(inputStateObj, {font=state.fontSmall}, rx + 110, ry, inputW, 22).changed then
            onChange()
        end
    end

    addField("Frame W:", state.inputState.frameWidth, logic.updateGrid)
    addField("Frame H:", state.inputState.frameHeight, logic.updateGrid)
    addField("Margin L:", state.inputState.left, logic.updateGrid)
    addField("Margin T:", state.inputState.top, logic.updateGrid)
    addField("Border:", state.inputState.border, logic.updateGrid)

    suit.layout:row(fullW, 6)
    suit.Label("CLIPS", {align="left", font=state.font}, suit.layout:row(fullW, 22))

    -- Clip switcher row: <  clipName  >  +  X
    local crx, cry = suit.layout:row(fullW, 24)
    if suit.Button("<", {id="clip_prev", font=state.fontSmall}, crx, cry, 26, 22).hit then
        logic.cycleClip(-1)
    end
    if suit.Input(state.inputState.clipName, {id="clip_name", font=state.fontSmall}, crx + 30, cry, fullW - 122, 22).changed then
        logic.renameActiveClip(state.inputState.clipName.text)
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

    addField("Duration:", state.inputState.duration, logic.createAnimation)

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
