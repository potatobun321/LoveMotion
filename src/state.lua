local state = {
    image = nil,
    fileData = nil,
    fileExt = ".png",
    grid = nil,
    animation = nil,

    font = nil,
    fontSmall = nil,

    screenW = 0,
    screenH = 0,

    viewZoom = 1,
    viewPanX = 0,
    viewPanY = 0,
    isPanning = false,

    playing = true,
    flipH = false,
    gridMode = "pixels", -- "pixels" or "count"

    generatedCode = "",
    errorMessage = "",

    selectedFrames = {},
    activeClip = "idle",
    clips = {
        idle = { frames = {}, duration = "0.1", mode = "loop" }
    },

    inputState = {
        frameWidth = {text = "64"},
        frameHeight = {text = "64"},
        cols = {text = "3"},
        rows = {text = "4"},
        left = {text = "0"},
        top = {text = "0"},
        border = {text = "0"},
        duration = {text = "0.1"},
        clipName = {text = "idle"},
        exportName = {text = "my_anim"}
    }
}

return state
