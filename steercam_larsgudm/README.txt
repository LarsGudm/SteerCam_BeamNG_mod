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

Two profiles, selected with the buttons at the top:

  Default   Shown but LOCKED (greyed out) - you can't
            change them. Angle 18, Full angle at 35%, Stiffness 15.

  Custom    Your own profile. Click it to unlock the controls and edit. Your
            changes are saved and kept separate from Default, so you can switch
            to Default and back to Custom without losing them. The first time
            you open Custom it starts from the Default values.

Controls (editable on Custom):
  Angle              0-90 deg   how far the view turns at full lock
  Steering range     10-100 %   how much steering reaches the full angle
                                (e.g. 50% = fully turned by half-lock; lower =
                                more reactive to small steering inputs). Also
                                normalizes the steering used by Speed camera roll.
  Stiffness          1-40       transition speed; higher = snappier
  Fade in with speed            scales the turn by speed (off = full at any
                                speed; on = none when stopped, ramps to full by
                                Fade speed)
  Fade speed                    (only shown when fade is on)

  Left angle         0-170 deg  blind-spot glance angle to the left (def. 115)
  Right angle        0-170 deg  blind-spot glance angle to the right (def. 115)
  Glance time        0-500 ms   how fast a glance snaps in/out (0 = instant)
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


WHAT'S INSIDE
-------------
  lua/ge/extensions/core/cameraModes/steercam.lua    the camera + config
  lua/ge/extensions/core/input/actions/steercam.json    glance key bindings
  lua/vehicle/extensions/auto/steerCamFeed.lua          feeds steering to GE
  ui/modules/apps/SteerCam/                             the settings panel app


IF SOMETHING'S OFF
------------------
- "Steercam" missing from the camera list: confirm the file is at
  .../core/cameraModes/steercam.lua, Ctrl+L, reopen the menu.
- "SteerCam Settings" missing from Add App: close/reopen the app list once;
  if still missing, Ctrl+L and check the console (~) for UI errors.
- Can't move the sliders: you're on the Default profile (locked) - click Custom.
