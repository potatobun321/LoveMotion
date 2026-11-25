local anim8 = require 'anim8'
local state = require 'src.state'

local logic = {}

local function syncActiveClip()
    local clipName = state.activeClip or "idle"
    local prev = state.clips[clipName] or {}
    state.clips[clipName] = {
        frames = state.selectedFrames,
        duration = state.inputState.duration.text,
        mode = prev.mode or "loop"
    }
end

function logic.getActiveMode()
    local c = state.clips[state.activeClip]
    return (c and c.mode) or "loop"
end

function logic.toggleClipMode()
    syncActiveClip()
    local c = state.clips[state.activeClip]
    c.mode = (c.mode == "pauseAtEnd") and "loop" or "pauseAtEnd"
    logic.createAnimation()
end

function logic.applyClipPreset(kind)
    syncActiveClip()
    local presets = {
        topdown = { "idle_down", "walk_down", "walk_up", "walk_left", "walk_right" },
        side    = { "idle", "run", "jump", "fall", "attack" }
    }
    local list = presets[kind]
    if not list then return end
    for _, name in ipairs(list) do
        if not state.clips[name] then
            state.clips[name] = { frames = {}, duration = "0.1", mode = (name == "jump" or name == "attack") and "pauseAtEnd" or "loop" }
        end
    end
    logic.switchClip(list[1])
end

function logic.switchClip(name)
    if not name or name == "" then return end
    syncActiveClip()
    if not state.clips[name] then
        state.clips[name] = { frames = {}, duration = state.inputState.duration.text }
    end
    state.activeClip = name
    state.inputState.clipName.text = name
    state.selectedFrames = state.clips[name].frames
    state.inputState.duration.text = state.clips[name].duration or "0.1"
    logic.createAnimation()
end

function logic.renameActiveClip(newName)
    if not newName or newName == "" or newName == state.activeClip then return end
    if state.clips[newName] then return end
    syncActiveClip()
    state.clips[newName] = state.clips[state.activeClip]
    state.clips[state.activeClip] = nil
    state.activeClip = newName
end

function logic.cycleClip(dir)
    syncActiveClip()
    local names = {}
    for k in pairs(state.clips) do table.insert(names, k) end
    table.sort(names)
    if #names <= 1 then return end
    local idx = 1
    for i, n in ipairs(names) do
        if n == state.activeClip then idx = i; break end
    end
    local nextIdx = ((idx - 1 + dir) % #names) + 1
    logic.switchClip(names[nextIdx])
end

function logic.newClip()
    syncActiveClip()
    local i = 1
    while state.clips["clip_" .. i] do i = i + 1 end
    logic.switchClip("clip_" .. i)
end

function logic.deleteActiveClip()
    local names = {}
    for k in pairs(state.clips) do
        if k ~= state.activeClip then table.insert(names, k) end
    end
    if #names == 0 then
        state.selectedFrames = {}
        syncActiveClip()
        logic.createAnimation()
        return
    end
    table.sort(names)
    state.clips[state.activeClip] = nil
    state.activeClip = names[1]
    state.inputState.clipName.text = names[1]
    state.selectedFrames = state.clips[names[1]].frames
    state.inputState.duration.text = state.clips[names[1]].duration or "0.1"
    logic.createAnimation()
end

function logic.stepFrame(dir)
    if not state.animation or not state.animation.frames or #state.animation.frames == 0 then return end
    state.playing = false
    local count = #state.animation.frames
    local cur = state.animation.position or 1
    local nxt = ((cur - 1 + dir) % count) + 1
    state.animation:gotoFrame(nxt)
end

function logic.applyCountGrid()
    if not state.image then return end
    local cols = math.max(1, math.floor(tonumber(state.inputState.cols.text) or 1))
    local rows = math.max(1, math.floor(tonumber(state.inputState.rows.text) or 1))
    local l = tonumber(state.inputState.left.text) or 0
    local t = tonumber(state.inputState.top.text) or 0
    local b = tonumber(state.inputState.border.text) or 0
    local imgW, imgH = state.image:getDimensions()

    local fw = math.max(1, math.floor((imgW - l) / cols) - b)
    local fh = math.max(1, math.floor((imgH - t) / rows) - b)
    state.inputState.frameWidth.text = tostring(fw)
    state.inputState.frameHeight.text = tostring(fh)
    logic.updateGrid()
end

function logic.autoDetectGrid()
    if not state.fileData or not state.image then return end
    local ok, imgData = pcall(love.image.newImageData, state.fileData)
    if not ok or not imgData then
        state.errorMessage = "Auto-detect failed."
        return
    end

    local w, h = imgData:getDimensions()
    local bgR, bgG, bgB, bgA = imgData:getPixel(0, 0)

    local function isEmpty(x, y)
        local r, g, b, a = imgData:getPixel(x, y)
        if a < 0.05 and bgA < 0.05 then return true end
        if a < 0.05 then return true end
        return math.abs(r - bgR) < 0.04 and math.abs(g - bgG) < 0.04 and math.abs(b - bgB) < 0.04 and math.abs(a - bgA) < 0.04
    end

    local function findSegments(len, checkLineEmpty)
        local segs = {}
        local inSeg = false
        local segStart = 0
        for i = 0, len - 1 do
            local empty = checkLineEmpty(i)
            if not empty and not inSeg then
                inSeg = true
                segStart = i
            elseif empty and inSeg then
                inSeg = false
                table.insert(segs, { start = segStart, stop = i - 1 })
            end
        end
        if inSeg then
            table.insert(segs, { start = segStart, stop = len - 1 })
        end
        return segs
    end

    local colSegs = findSegments(w, function(x)
        for y = 0, h - 1 do
            if not isEmpty(x, y) then return false end
        end
        return true
    end)

    local rowSegs = findSegments(h, function(y)
        for x = 0, w - 1 do
            if not isEmpty(x, y) then return false end
        end
        return true
    end)

    if #colSegs == 0 or #rowSegs == 0 then
        state.errorMessage = "No sprites detected."
        return
    end

    local cols = #colSegs
    local rows = #rowSegs
    state.inputState.cols.text = tostring(cols)
    state.inputState.rows.text = tostring(rows)
    state.inputState.left.text = "0"
    state.inputState.top.text = "0"
    state.inputState.border.text = "0"

    -- Divide evenly by detected sprite count so cells stay centered
    local fw = math.max(1, math.floor(w / cols))
    local fh = math.max(1, math.floor(h / rows))
    state.inputState.frameWidth.text = tostring(fw)
    state.inputState.frameHeight.text = tostring(fh)
    state.gridMode = "count"
    logic.updateGrid()
end

function logic.updateGrid()
    if not state.image then return end
    local fw = tonumber(state.inputState.frameWidth.text) or 32
    local fh = tonumber(state.inputState.frameHeight.text) or 32
    local l = tonumber(state.inputState.left.text) or 0
    local t = tonumber(state.inputState.top.text) or 0
    local b = tonumber(state.inputState.border.text) or 0

    local imgW, imgH = state.image:getDimensions()
    state.grid = anim8.newGrid(fw, fh, imgW, imgH, l, t, b)

    logic.createAnimation()
end

function logic.createAnimation()
    syncActiveClip()
    if not state.image or not state.grid then return end
    state.errorMessage = ""

    if #state.selectedFrames == 0 then
        state.animation = nil
        state.generatedCode = ""
        return
    end

    local dur = tonumber(state.inputState.duration.text)
    if not dur or dur <= 0 then
        state.errorMessage = "Invalid duration."
        state.animation = nil
        return
    end

    local framesArr = {}
    local framesStrArgs = {}
    for _, f in ipairs(state.selectedFrames) do
        table.insert(framesArr, f.x)
        table.insert(framesArr, f.y)
        table.insert(framesStrArgs, string.format("%d,%d", f.x, f.y))
    end

    local framesSuccess, frames = pcall(function() return state.grid(unpack(framesArr)) end)
    if not framesSuccess then
        state.errorMessage = "Frames out of bounds."
        state.animation = nil
        return
    end

    local mode = logic.getActiveMode()
    local animSuccess, anim = pcall(function()
        if mode == "pauseAtEnd" then
            return anim8.newAnimation(frames, dur, "pauseAtEnd")
        end
        return anim8.newAnimation(frames, dur)
    end)
    if not animSuccess then
        state.errorMessage = "Failed to create animation."
        state.animation = nil
        return
    end

    state.animation = anim

    local imgName = "spritesheet" .. (state.fileExt or ".png")
    local modeArg = (mode == "pauseAtEnd") and ", 'pauseAtEnd'" or ""
    state.generatedCode = string.format([[
local anim8 = require 'anim8'
local image = love.graphics.newImage('%s')

local g = anim8.newGrid(%d, %d, image:getWidth(), image:getHeight(), %d, %d, %d)

local anim = anim8.newAnimation(g(%s), %s%s)
]],
        imgName,
        tonumber(state.inputState.frameWidth.text) or 32,
        tonumber(state.inputState.frameHeight.text) or 32,
        tonumber(state.inputState.left.text) or 0,
        tonumber(state.inputState.top.text) or 0,
        tonumber(state.inputState.border.text) or 0,
        table.concat(framesStrArgs, ", "),
        state.inputState.duration.text,
        modeArg
    )
end

function logic.fitViewport()
    if not state.image then return end
    local panelW = state.screenW - 640
    local iw, ih = state.image:getDimensions()
    local sc = math.min((panelW - 40) / iw, (state.screenH - 40) / ih)
    sc = math.max(0.25, math.min(16, sc))
    state.viewZoom = sc
    local centerX = 320 + panelW / 2
    local centerY = state.screenH / 2
    local baseX = centerX - 128
    local baseY = centerY - 128
    state.viewPanX = (centerX - (iw * sc) / 2) - baseX
    state.viewPanY = (centerY - (ih * sc) / 2) - baseY
end

function logic.handleFileDropped(file)
    local ext = file:getFilename():match("^.+(%..+)$")
    if ext then ext = ext:lower() end
    if ext == ".png" or ext == ".jpg" or ext == ".jpeg" then
        file:open("r")
        state.fileData = file:read("data")
        state.fileExt = ext
        state.image = love.graphics.newImage(state.fileData)

        state.animation = nil
        state.generatedCode = ""
        state.errorMessage = ""
        state.selectedFrames = {}
        state.activeClip = "idle"
        state.inputState.clipName.text = "idle"
        state.clips = { idle = { frames = state.selectedFrames, duration = state.inputState.duration.text } }
        logic.fitViewport()
        logic.updateGrid()
    end
end

local function buildManifestData()
    syncActiveClip()
    local imgName = "spritesheet" .. (state.fileExt or ".png")
    local fw = tonumber(state.inputState.frameWidth.text) or 32
    local fh = tonumber(state.inputState.frameHeight.text) or 32
    local l = tonumber(state.inputState.left.text) or 0
    local t = tonumber(state.inputState.top.text) or 0
    local b = tonumber(state.inputState.border.text) or 0

    local lines = {
        "-- Generated by Anim8tor (standalone pure-data export)",
        "return {",
        string.format("    image = %q,", imgName),
        string.format("    grid = { frameW = %d, frameH = %d, left = %d, top = %d, border = %d },", fw, fh, l, t, b),
        "    animations = {"
    }

    local names = {}
    for k in pairs(state.clips) do table.insert(names, k) end
    table.sort(names)

    for _, clipName in ipairs(names) do
        local c = state.clips[clipName]
        if c.frames and #c.frames > 0 then
            local fList = {}
            for _, f in ipairs(c.frames) do
                table.insert(fList, string.format("%d, %d", f.x, f.y))
            end
            local dur = tonumber(c.duration) or 0.1
            local mode = c.mode or "loop"
            table.insert(lines, string.format(
                "        [%q] = { frames = { %s }, duration = %s, mode = %q },",
                clipName, table.concat(fList, ", "), tostring(dur), mode
            ))
        end
    end

    table.insert(lines, "    }")
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

function logic.saveToDisk()
    if not state.image then
        state.errorMessage = "Drop a spritesheet first!"
        return
    end
    syncActiveClip()

    local hasAnyFrames = false
    for _, c in pairs(state.clips) do
        if c.frames and #c.frames > 0 then hasAnyFrames = true; break end
    end
    if not hasAnyFrames then
        state.errorMessage = "No animation to save!"
        return
    end

    local name = state.inputState.exportName.text
    if name == "" then name = "anim_export" end

    local exportDir = "exports/" .. name
    love.filesystem.createDirectory(exportDir)

    local manifest = buildManifestData()
    local success1, err1 = love.filesystem.write(exportDir .. "/" .. name .. ".lua", manifest)
    if not success1 then
        state.errorMessage = "Failed to save Lua manifest: " .. tostring(err1)
        return
    end

    if state.fileData then
        local imgName = "spritesheet" .. (state.fileExt or ".png")
        local success2, err2 = love.filesystem.write(exportDir .. "/" .. imgName, state.fileData)
        if not success2 then
            state.errorMessage = "Failed to save image: " .. tostring(err2)
            return
        end
    else
        state.errorMessage = "Original image data lost, please re-drop image."
        return
    end

    local fullPath = love.filesystem.getSaveDirectory() .. "/" .. exportDir
    pcall(love.system.openURL, "file://" .. fullPath)
    state.errorMessage = ""
end

return logic
