SteerCam - ETS2-style "steer camera turn" for the BeamNG driver camera
======================================================================

Adds a selectable driver camera ("Steercam") that turns the view toward
where your wheels are pointed. It layers on top of the stock driver camera and
doesn't touch any other camera mod. Settings live in a small in-game app.


INSTALL
-------
1. BeamNG Launcher -> "Manage User Folder" -> "Open User Folder".
2. Drop SteerCam.zip into the  mods  folder (leave it zipped).
   (Delete any older SteerCam copy first so it isn't loaded twice.)
3. In-game: Ctrl+L, then Ctrl+R.
4. Esc -> Options -> Camera -> Switching order -> tick "Steercam".
5. Press C until you reach that camera.


THE SETTINGS PANEL
------------------
1. Esc -> UI Apps (enter UI edit mode) -> "Add App".
2. Find "SteerCam Settings", click it to drop it on screen, place/resize it.
3. Click anywhere to leave edit mode.

The per-app "Hide in cockpit view" checkbox works with SteerCam: any app with
it ticked hides while the SteerCam view is active (SteerCam reports itself to the
UI as a cockpit/"driver" view so the game's hide logic kicks in).

The "Enabled" checkbox at the top-right (next to the title) is the master switch
for the whole mod: untick it and the camera reverts to the plain stock driver
view (all SteerCam effects off) without changing your preset or saved settings.

"Driver seat mirrors settings" (below the Presets row, on by default) treats your
saved values as a LEFT-hand-drive seat and auto-mirrors the side-specific ones in
right-hand-drive cars: the camera pan (Rotate L/R) flips, and the glance Left/
Right angle + offset swap. Keybinds never flip -- the right glance still looks
right, it just uses your left-side tuning. Turn it off to use your values as-is in
every car.

Profiles, picked from the "Presets" dropdown at the top. EVERY profile is editable:
tweak any slider and the dropdown shows "(modified)". A "Reset" button discards
those tweaks (back to the saved preset); in the Presets menu, "Save changes to this
preset" bakes them into it, or "Save as new preset..." makes a new one. Each preset
remembers its own tweaks, so switching back and forth keeps them.

  Default       PROTECTED - a simple, conservative baseline. Editable (with a lock
                in the menu); you can't overwrite or delete it, only Save as new.

  Dev's Preset  PROTECTED - a tuned "immersion" set (steer fade, reverse mirror,
                speed vertigo + roll, softer glance easing). Same: edit + Save as new.

  (more)        Any preset you make or drop on disk - see ADDING PRESETS below.
                Your own presets can be edited, Saved over, or deleted (× in the menu,
                with a confirm).

  Custom        A free scratch profile. Edits save straight to it (no "modified"
                state); starts from the Default values.

Controls:
  Camera settings override      (section) seat position, aim + FOV override
  Forward Offset   -0.5..0.5 m  move the seat forward (+) or back (-)
  Vertical Offset  -0.5..0.5 m  move the seat up (+) or down (-)
  Rotate L/R        -45..45 deg pan the view (gimbal): - = left, + = right
  Rotate D/U        -45..45 deg tilt the view (gimbal): always world-vertical
  Horizon lock       0-100 %    how much the horizon stays level vs. banks with
                                the car (NASCAR banking, off-camber turns). 0
                                (def.) = banks fully with the car; 100 = stays
                                level (eases off on steep banks). Same as the
                                game's "Lock roll to horizon" camera option.
  FOV               40-120 deg  field of view; overrides the camera's own FOV
                                (def. 65). Speed vertigo stacks on top of this.
  Near clip        0.01-0.2 m   how close to the camera things start drawing; lower
                                hides nearby geometry (e.g. the roof poking in at high
                                FOV). Def. 0.05 (game uses 0.1); too low can flicker
                                distant surfaces.

  Steering Input Pan            (section) the steer-following turn
  Angle              0-90 deg   how far the view turns at full lock
  Steering range     10-100 %   how much steering reaches the full angle
                                (e.g. 50% = fully turned by half-lock; lower =
                                more reactive to small steering inputs)
  Stiffness          1-40       transition speed; higher = snappier
  Mirror turn ...reversing      while reversing, mirror the turn the other way.
                                Direction follows your speed; at a near standstill
                                (<1 km/h) it follows the gear instead, so it flips
                                the moment you shift to/from reverse.
  Reverse angle      0-90 deg   its own angle while reversing (def. 9)
  Reverse blend      0-1000 ms  how slowly it eases between forward/reverse
                                (buffers spin-outs; def. 500)
  Fade in with speed            scales the turn by speed (off = full at any
                                speed; on = none when stopped, ramps to full by
                                Fade speed)
  Fade speed         5-150 km/h (only shown when fade is on; def. 30)
  Standstill turn    0-100 %    (fade on) how much of the turn is kept even when
                                stopped; the rest ramps in by Fade speed. 0
                                (def.) = no turn until moving. e.g. 10% lets you
                                see a bit of steer lean while parked.

  Left angle         0-170 deg  blind-spot glance angle to the left (def. 115)
  Left offset     -0.5..0.5 m   lean toward the side you glance (def. 0.10) - bump
                                it up if the view clips into the seat; negative
                                leans/pulls back the other way
  Right angle        0-170 deg  blind-spot glance angle to the right (def. 115)
  Right offset    -0.5..0.5 m   same for the right glance (def. 0.10)
  Back angle      -90..90 deg   bias the rear glance off straight-back (def. 0 =
                                looking directly back; +-90 = more over one
                                shoulder). Direction follows the seat side
  Back offset     -0.5..0.5 m   lateral shift for the rear glance (def. 0)
  Back roll        -15..15 deg  head-tilt while glancing back (def. 0; just for
                                flavour - your head leans a touch looking back).
                                Mirrors with the seat side
  Glance time        0-500 ms   how fast a glance snaps in/out (0 = instant)
  Glance curve                  easing curve (dropdown): Exponential (native) /
                                Linear / S-curve / Ease1 / Ease2

Hover any category name or setting label (marked with a small i) for a short
description of what it does.

Each category header has a twirl and a checkbox on the right: click the category
NAME to collapse/expand it, click the CHECKBOX to turn the feature on/off.
Disabling a category dims it but leaves it open, so you can still see and tweak
its settings; use the twirl on the name to collapse/expand. Unticking a category
turns that whole feature off (the glance keybinds keep existing, they just do
nothing while it's off).

Immersive extras (optional cabin-feel effects; SteerCam view only):
  Immersive extras              master enable for this section (off by default)
  Speed vertigo (FOV)           widen the FOV as you go faster, with a matching
                                forward dolly (the dolly-zoom "vertigo" warp)
  FOV change         0-40 deg   max extra FOV reached at the speed range
  Dolly depth        0-1.5 m    distance kept "pinned" by the counter-dolly
                                (def. 0.30): 0 = FOV only (no camera move);
                                higher pins more distant things but moves the
                                camera forward more
  Speed camera roll             lean the head into the turn; leans the camera-
                                override horizon (keeps the bank, doesn't flatten
                                it or add up/down sway)
  Roll change        0-20 deg   max lean angle
  Roll source                   what drives the lean: Steering input (scaled by
                                speed) or Inertia (real lateral g-force, full lean
                                at ~1g, so it follows actual cornering load/slides)
  Speed range        20-400     km/h at which the speed-scaled effects reach full
                                strength (def. 160; shared by vertigo + steering
                                roll. Inertia roll uses g-force instead)
  Head lift (vert. inertia)     the driver lifts off the seat when the car drops
                                away (cresting, going light, airborne) and sinks
                                under compression -- a vertical offset added on top
                                of the camera Up offset
  Max lift           0-30 cm    how far the head travels at most (full at ~1g)
  Engine vibration              a small rapid camera buzz as the engine fires up (just
                                after a brief ignition delay), plus a gentler quarter-
                                strength shudder when you switch it off (road texture
                                is mostly suspension-damped, so not shaken)
  Vibration amount   0-0.5 cm   how far the buzz moves the camera at its peak
  Rotation amount    0-1 deg    how much the buzz also rotates the view (keep it tiny)

Changes apply instantly and persist between drives. You can keep the panel open
while driving to dial in the feel, then remove it.


BLIND-SPOT GLANCE
-----------------
Quickly snap the view to a fixed angle to check a blind spot, then return. The
glance overrides the steer-following turn while it's active.

Bind keys in Esc -> Options -> Controls -> Bindings (Camera category):
  SteerCam - Glance left/right (hold)     hold to look, release to return
                                          (the intended everyday binding)
  SteerCam - Glance left/right (toggle)   press to latch on, press again off
                                          (handy for tuning)
  SteerCam - Glance back (hold/toggle)    look over your shoulder to the rear.
                                          Meant to REPLACE the native look-back:
                                          bind it to your look-back key (and unbind
                                          the native one) so cockpit views all run
                                          through SteerCam and don't stack/fight.

The actions ship UNBOUND - assign whatever keys you like. Glance only affects
the view while the SteerCam camera is the active view (press C).

Tuning the angles: open the panel, switch to Custom, click "Preview left/back/
right" to hold the glance, then drag the matching angle slider until it feels
right. Click the preview button again to release. Pressing a glance keybind also
cancels an active preview, so you can test the real binding right away.


ADDING PRESETS
--------------
Easiest way - from the app: tune the look (on Custom, or any profile), type a
name in the box under the Presets dropdown and hit Save. It's written as a .json
in your User Folder and is then available for every car. Saving onto an existing
name of your own asks to overwrite; Delete (next to the dropdown) removes the
selected one. Default and Dev's Preset are PROTECTED and can't be overwritten or
deleted from the app (they show a lock).

By hand: presets are plain .json files. Any .json in the presets folder shows up
in the dropdown automatically. To add one without unzipping the mod, drop it in
your User Folder:

  settings/steercam/presets/mypreset.json

Easiest start: copy the shipped default.json (inside the mod's
settings/steercam/presets/), rename it, and edit. Format:

  - "name"  : what shows in the dropdown (e.g. "Track day"). If omitted, the
              filename is used. Don't use "Custom" - that name is reserved.
  - "order" : optional number for sort position (lower = higher in the list).
  - "protected" : optional. Set true to make a preset safe from the app's Save/
              Delete (like Default and Dev's). Add it to your own files if you
              want to guard them; leave it out and the app can overwrite/delete.
  - Any setting key you want to change (same names the panel uses). Keys you
    leave out fall back to Default; out-of-range numbers are clamped; unknown
    keys are ignored - so a partial file is perfectly fine.

After editing files by hand, either reload the game UI (Ctrl+L) or run
  steerCam.reloadPresets()
in the console (~) to re-scan without a restart.


WHAT'S INSIDE
-------------
  lua/ge/extensions/core/cameraModes/steercam.lua    the camera + config loader
  lua/ge/extensions/core/input/actions/steercam.json    glance key bindings
  lua/vehicle/extensions/auto/steerCamFeed.lua          feeds steering to GE
  settings/steercam/presets/*.json                      the bundled presets
  ui/modules/apps/SteerCam/                             the settings panel app


IF SOMETHING'S OFF
------------------
- "Steercam" missing from the camera list: confirm the file is at
  .../core/cameraModes/steercam.lua, Ctrl+L, reopen the menu.
- "SteerCam Settings" missing from Add App: close/reopen the app list once;
  if still missing, Ctrl+L and check the console (~) for UI errors.
- Tweaked a preset by accident: hit Reset (next to the dropdown) to discard the
  changes, or Save as new preset to keep them under a new name.
