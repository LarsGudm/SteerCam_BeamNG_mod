# Steer Cam

A subtle, fully adjustable driver camera for **BeamNG.drive** that turns the
view toward where your front wheels are pointed — the "look into the corner"
feel from truck and driving sims. It reacts to your actual steering input, so
the view leads the turn instead of trailing the car.

It's added as its own camera (**Steercam**), layered on top of the stock driver
camera, so it keeps all the normal interior behaviour (seat position, horizon,
head-look) and doesn't replace or conflict with other camera mods.

## Features
- Steering-linked "look into corner" yaw, layered on the stock driver camera.
- **Blind-spot glance**: bindable keys to snap the view to a fixed left/right
  angle and back — hold to check, release to return (plus a toggle binding for
  tuning). The glance overrides the steer-follow while it's active.
- In-game settings app with **Default** (locked) and **Custom** (editable, saved) profiles.
- Tunable: turn **Angle** (0–90°), **Full angle at** (10–100% of steering),
  **Stiffness** (follow speed), **Invert**, and optional **Fade in with speed**.
- Glance tunables: **Left/Right angle** (0–170°, default 90), **Glance time**
  (0–500 ms, 0 = instant), and **Side offset** (lean toward the glanced side to
  avoid clipping into the seat), with in-panel **Preview** buttons to dial in
  each side live.

## Install (for players)
1. Download the latest `steercam_larsgudm.zip` from Releases.
2. Drop it into your BeamNG `mods` folder (Launcher → Manage User Folder → Open User Folder). Leave it zipped.
3. In game: `Ctrl+L`, then `Ctrl+R`.
4. Options → Camera → Switching order → tick **Steercam**, then press `C` to reach it.
5. Add the **Steer Cam Settings** app from Esc → UI Apps → Add App to tune it.
6. (Optional) Bind the glance keys in Options → Controls → Bindings (Camera) —
   the four **SteerCam - Glance …** actions ship unbound.

## Repository layout
This repo holds the **unpacked source**. The playable mod is just these folders
zipped with `lua` and `ui` at the root:

```
lua/ge/extensions/core/cameraModes/steercam.lua      # the camera + config + UI hooks
lua/ge/extensions/core/input/actions/steercam.json   # glance key-binding actions
lua/vehicle/extensions/auto/steerCamFeed.lua         # feeds steering input GE-side
ui/modules/apps/SteerCam/app.js                      # settings panel (AngularJS)
ui/modules/apps/SteerCam/app.json                    # app manifest
ui/modules/apps/SteerCam/app.png                     # app tile icon
README.txt                                           # in-mod readme
```

## Building the mod zip
Select the `lua` and `ui` folders (and `README.txt`) and compress them so that
`lua` is the **first folder inside the zip** — not a parent folder. Name it
`steercam_larsgudm.zip`. That zip is what you drop in `mods/` or upload to the
BeamNG repository.

> Do **not** commit the built zip to git — commit the source files above. The
> zip is a build artifact you generate from them.

## Compatibility
- BeamNG.drive 0.38+.
- Adds a camera rather than overwriting one, so it coexists with other camera mods.
- Because it builds on the stock driver camera, a large future rework of the
  game's `driver.lua` may need a refresh.

## Credits
Author: **LarsGudm**
