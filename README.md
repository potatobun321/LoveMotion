# LoveMotion

A standalone visual animation editor for **LÖVE (Love2D)** and `anim8`.

Drop in a spritesheet, slice it visually, click the frames in playback order, preview the animation live, and export either a copy-paste Lua snippet or a pure-data manifest for any 2D game (top-down, sidescroller, or UI/VFX).

---

## Project Status & Disclosure

* **Early Public Release (Alpha):** LoveMotion is an early-stage project. Core slicing, previewing, and exporting work, but rough edges remain and updates or breaking changes to the UI and export format should be expected as development continues.
* **AI Assistance:** This project was built with AI coding assistance alongside human design, testing, and direction.

---

## Running

1. Download `LoveMotion.love` or `LoveMotion-win64.zip` from the [Releases](https://github.com/potatobun321/LoveMotion/releases) page, **or** clone this repository and run it with **LÖVE 11.x** or newer ([love2d.org](https://love2d.org/)):

```bash
love .
```

---

## Controls & Workflow

1. **Load a Spritesheet:** Drag and drop any `.png`, `.jpg`, or `.jpeg` file into the window, or click **TRY SAMPLE** to test with a bundled sheet.
2. **Configure the Grid (Left Panel):**
   * Switch between **BY PIXELS** (`Frame W` / `Frame H`) and **BY COUNT** (`Cols` / `Rows`), or click **AUTO** to detect sprites automatically.
   * Use the quick presets (`16`, `32`, `64`), `-` / `+` stepper buttons, and **FIT** to align the grid.
3. **Navigate the Viewport (Center Panel):**
   * **Mouse Wheel:** Zoom in and out (`0.25x` to `16x`).
   * **Middle-Click Drag:** Pan around large sheets.
4. **Select Frames:**
   * **Left-Click:** Add a frame to the current clip.
   * **Shift + Left-Click:** Select a range of frames from the last clicked cell.
   * **Right-Click:** Remove the most recent occurrence of that cell.
5. **Manage Multiple Clips & Timing:**
   * Use `<` / `>`, `+`, and `X` under `CLIPS` to create and switch between named clips (`idle`, `run`, `attack`, etc.).
   * Use **TOP-DOWN** or **SIDE** to seed common clip names.
   * Drag the **Duration / FPS slider** and toggle `MODE: LOOP` / `MODE: ONCE` (`pauseAtEnd` in `anim8`) per clip.
6. **Preview (Right Panel):**
   * Use `<`, `PLAY`/`PAUSE`, `>`, and `FLIP` to inspect frames and horizontal facing.

---

## Using the Output in Your Game

### Option 1: Copy-Paste Snippet (Fastest for Prototypes)
Click **COPY SNIPPET** at the bottom-right to copy a ready-to-run `anim8` snippet for the active clip.

### Option 2: Pure-Data Manifest (Best for Custom Engines & State Managers)
Enter a folder/file name under `File:` and click **SAVE MANIFEST**.
This writes `exports/<name>/<name>.lua` alongside `spritesheet.<ext>` and opens the folder. The `.lua` file is a plain data table with zero dependency on LoveMotion:

```lua
return {
    image = "spritesheet.png",
    grid = { frameW = 32, frameH = 32, left = 0, top = 0, border = 0 },
    animations = {
        ["idle"] = { frames = { 1, 1, 2, 1 }, duration = 0.1, mode = "loop" },
    }
}
```

### Option 3: Optional 1-File Runtime Loader
Copy [lovemotion.lua](runtime/lovemotion.lua) into your LÖVE project next to `anim8.lua`:

```lua
local lovemotion = require("lovemotion")
local hero = lovemotion.load("assets/hero/hero.lua", "lib.anim8")

-- In love.update(dt):
hero.animations.idle:update(dt)

-- In love.draw():
hero.animations.idle:draw(hero.image, x, y)
```

For a complete runnable example, check [examples/topdown_demo](examples/topdown_demo) (or download `LoveMotion-TopDownDemo.zip` from Releases).

---

## Packaging

* **Cross-platform `.love` file:** Zip the contents of this folder (omitting `.git/`, `tests/`, `exports/`, and `suit/docs/`) and rename it to `LoveMotion.love`.
* **Automated builds:** Pushing a `v*` tag triggers [release.yml](.github/workflows/release.yml) to build `LoveMotion.love` and `LoveMotion-win64.zip`.

---

## License

MIT — see [MIT-LICENSE.txt](MIT-LICENSE.txt). Includes [anim8](https://github.com/kikito/anim8) and [SUIT](https://github.com/vrld/suit).
