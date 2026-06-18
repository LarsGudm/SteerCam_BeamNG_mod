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
  Full angle at      10-100 %   how much steering reaches that full angle
                                (e.g. 50% = fully turned by half-lock; lower =
                                more reactive to small steering inputs)
  Stiffness          1-40       transition speed; higher = snappier
  Invert direction              flip if it turns the wrong way
  Fade in with speed            scales the turn by speed (off = full at any
                                speed; on = none when stopped, ramps to full by
                                Fade speed)
  Fade speed                    (only shown when fade is on)

Changes apply instantly and persist between drives. You can keep the panel open
while driving to dial in the feel, then remove it.


WHAT'S INSIDE
-------------
  lua/ge/extensions/core/cameraModes/steercam.lua    the camera + config
  lua/vehicle/extensions/auto/steerCamFeed.lua          feeds steering to GE
  ui/modules/apps/SteerCam/                             the settings panel app


IF SOMETHING'S OFF
------------------
- "Steercam" missing from the camera list: confirm the file is at
  .../core/cameraModes/steercam.lua, Ctrl+L, reopen the menu.
- "SteerCam Settings" missing from Add App: close/reopen the app list once;
  if still missing, Ctrl+L and check the console (~) for UI errors.
- Can't move the sliders: you're on the Default profile (locked) - click Custom.
