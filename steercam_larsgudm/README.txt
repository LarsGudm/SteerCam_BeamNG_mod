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

Profiles, picked from the "Presets" dropdown at the top:

  Default       LOCKED (read-only) - a simple, conservative baseline.

  Dev's Preset  LOCKED (read-only) - a tuned "immersion" set (steer fade,
                reverse mirror, speed vertigo + roll, softer glance easing).

  (more)        Any extra presets found on disk - see ADDING PRESETS below.

  Custom        Your own profile. Pick it to unlock the controls and edit. Your
                changes are saved separately, so you can switch presets and back
                without losing them. It starts from the Default values.

Controls (editable on Custom):
  Camera settings override      (section) seat position, aim + FOV override
  Forward Offset   -0.5..0.5 m  move the seat forward (+) or back (-)
  Vertical Offset  -0.5..0.5 m  move the seat up (+) or down (-)
  Rotate L/R        -45..45 deg pan the view (gimbal): - = left, + = right
  Rotate D/U        -45..45 deg tilt the view (gimbal): always world-vertical
  FOV               40-120 deg  field of view; overrides the camera's own FOV
                                (def. 65). Speed vertigo stacks on top of this.

  Steering Input Pan            (section) the steer-following turn
  Angle              0-90 deg   how far the view turns at full lock
  Steering range     10-100 %   how much steering reaches the full angle
                                (e.g. 50% = fully turned by half-lock; lower =
                                more reactive to small steering inputs)
  Stiffness          1-40       transition speed; higher = snappier
  Mirror turn ...reversing      while reversing, mirror the turn the other way
  Reverse angle      0-90 deg   its own angle while reversing (def. 9)
  Reverse blend      0-1000 ms  how slowly it eases between forward/reverse
                                (buffers spin-outs; def. 500)
  Fade in with speed            scales the turn by speed (off = full at any
                                speed; on = none when stopped, ramps to full by
                                Fade speed)
  Fade speed         5-150 km/h (only shown when fade is on; def. 30)

  Left angle         0-170 deg  blind-spot glance angle to the left (def. 115)
  Right angle        0-170 deg  blind-spot glance angle to the right (def. 115)
  Glance time        0-500 ms   how fast a glance snaps in/out (0 = instant)
  Glance curve                  easing curve (dropdown): Exponential (native) /
                                Linear / S-curve / Ease1 / Ease2
  Left offset        0-0.6 m    lean left when glancing left (def. 0.10) - bump
                                it up if the view clips into the seat
  Right offset       0-0.6 m    lean right when glancing right (def. 0.10)

Each category header ("Steer camera turn", "Blind-spot glance", "Speed
modifiers") has an enable checkbox. Unticking a header turns that whole feature
off (the glance keybinds keep existing, they just do nothing while it's off).

Speed modifiers (mostly for fun, scale with speed; SteerCam view only):
  Speed modifiers               master enable for this section
  Speed vertigo (FOV)           widen the FOV as you go faster, with a matching
                                forward dolly (the dolly-zoom "vertigo" warp)
  FOV change         0-40 deg   max extra FOV reached at the speed range
  Dolly depth        0-1.5 m    distance kept "pinned" by the counter-dolly
                                (def. 0.30): 0 = FOV only (no camera move);
                                higher pins more distant things but moves the
                                camera forward more
  Speed camera roll             lean into the turn from steering input; hidden
                                at low speed, grows as you near the speed range
  Roll change        0-20 deg   max lean angle (full steering at the speed range)
  Speed range        20-400     km/h at which BOTH effects reach full strength
                                (def. 160; shared ceiling)

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

The actions ship UNBOUND - assign whatever keys you like. Glance only affects
the view while the SteerCam camera is the active view (press C).

Tuning the angles: open the panel, switch to Custom, click "Preview left" or
"Preview right" to hold the glance, then drag the Left/Right angle slider until
it feels right. Click the preview button again to release.


ADDING PRESETS
--------------
Presets are plain .json files. The mod ships Default + Dev's Preset; any other
.json found in the presets folder shows up in the dropdown automatically (read-
only, like the built-ins).

To add your own without unzipping the mod, create this folder in your BeamNG
User Folder and drop a .json in it:

  settings/steercam/presets/mypreset.json

Easiest start: copy the shipped default.json (inside the mod's
settings/steercam/presets/), rename it, and edit. Format:

  - "name"  : what shows in the dropdown (e.g. "Track day"). If omitted, the
              filename is used. Don't use "Custom" - that name is reserved.
  - "order" : optional number for sort position (lower = higher in the list).
  - Any setting key you want to change (same names the panel uses). Keys you
    leave out fall back to Default; out-of-range numbers are clamped; unknown
    keys are ignored - so a partial file is perfectly fine.

After adding/editing files, either reload the game UI (Ctrl+L) or run
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
- Can't move the sliders: you're on the Default profile (locked) - click Custom.
