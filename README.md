# Anim8tor

A standalone visual animation editor for **LÖVE (Love2D)** and `anim8`.

Drop in a spritesheet, slice it visually, click the frames in playback order, preview the animation live, and export either a copy-paste Lua snippet or a pure-data manifest for any 2D game (top-down, sidescroller, or UI/VFX).

---

## Running

1. Install **LÖVE 11.x** or newer from [love2d.org](https://love2d.org/).
2. Run inside this folder:

```bash
love .
```

---

## Controls & Workflow

1. **Load a Spritesheet:** Drag and drop any `.png`, `.jpg`, or `.jpeg` file into the window.
2. **Configure the Grid (Left Panel):**
   * Use the quick presets (`16`, `32`, `64`) or type custom `Frame W`, `Frame H`, `Margin L`, `Margin T`, and `Border` values.
   * Click `FIT` to center and scale the sheet in the viewport.
3. **Navigate the Viewport (Center Panel):**
   * **Mouse Wheel:** Zoom in and out (`0.25x` to `16x`).
   * **Middle-Click Drag:** Pan around large sheets.
4. **Select Frames:**
   * **Left-Click:** Add a frame to the current clip.
   * **Shift + Left-Click:** Select a range of frames from the last clicked cell.
   * **Right-Click:** Remove the most recent occurrence of that cell.
5. **Manage Multiple Clips:**
   * Use `<` / `>`, `+`, and `X` under `CLIPS` to create and switch between named clips (for example `idle`, `run`, `attack`).
   * Use `TOP-DOWN` or `SIDE` to seed common clip names.
   * Toggle `MODE: LOOP` / `MODE: ONCE` (`pauseAtEnd` in `anim8`) per clip.
6. **Preview (Right Panel):**
   * Use `<`, `PLAY`/`PAUSE`, `>`, and `FLIP` to inspect frames and horizontal facing.

---

## Using the Output in Your Game

### Option 1: Copy-Paste Snippet (Fastest for Prototypes)
Click **COPY SNIPPET** at the bottom-right to copy a ready-to-run `anim8` snippet for the active clip.

### Option 2: Pure-Data Manifest (Best for Custom Engines & State Managers)
Enter a folder/file name under `File:` and click **SAVE MANIFEST**.
This writes `exports/<name>/<name>.lua` alongside `spritesheet.<ext>` and opens the folder. The `.lua` file is a plain data table with zero dependency on Anim8tor:

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
Copy [anim8tor_loader.lua](runtime/anim8tor_loader.lua) into your LÖVE project next to `anim8.lua`:

```lua
local anim8tor = require("anim8tor_loader")
local hero = anim8tor.load("assets/hero/hero.lua", "lib.anim8")

-- In love.update(dt):
hero.animations.idle:update(dt)

-- In love.draw():
hero.animations.idle:draw(hero.image, x, y)
```

---

## Packaging for Distribution

* **Cross-platform `.love` file:** Zip the contents of this folder (you can omit `suit/docs/` to keep the archive small) and rename the zip to `Anim8tor.love`. Works on Windows, macOS, and Linux.
* **Windows standalone `.exe`:** Fuse `Anim8tor.love` with `love.exe`:
  ```cmd
  copy /b love.exe+Anim8tor.love Anim8tor.exe
  ```
  Distribute `Anim8tor.exe` together with the LÖVE `.dll` files.

---

## License

MIT — see [MIT-LICENSE.txt](MIT-LICENSE.txt). Includes [anim8](https://github.com/kikito/anim8) and [SUIT](https://github.com/vrld/suit).
