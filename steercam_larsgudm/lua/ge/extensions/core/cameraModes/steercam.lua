-- SteerCam :: driver camera with ETS2-style "steer camera turn"
-- ----------------------------------------------------------------------------
-- File: lua/ge/extensions/core/cameraModes/driversteer.lua
--
-- A selectable driver camera that turns the view toward where the wheels are
-- pointed. Enable in Options -> Camera -> Switching order (tick "Driversteer"),
-- press C. Adjust from the "SteerCam Settings" UI app.
--
-- Two profiles:
--   Default : fixed values, locked (read-only) in the UI.
--   Custom  : your own saved values, editable. Persists independently, so it
--             remembers your tweaks even after switching to Default and back.
-- ----------------------------------------------------------------------------

if not steerCam then
  steerCam = {}

  local function getNum(k, d)
    local v = settings and settings.getValue and settings.getValue(k)
    if type(v) == "number" then return v end
    return d
  end
  local function getBool(k, d)
    local v = settings and settings.getValue and settings.getValue(k)
    if type(v) == "boolean" then return v end
    return d
  end
  local function getStr(k, d)
    local v = settings and settings.getValue and settings.getValue(k)
    if type(v) == "string" then return v end
    return d
  end
  local function save(k, v)
    if settings and settings.setValue then settings.setValue(k, v) end
  end
  local function clampv(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end

  -- The Default profile (fixed; never written to).
  steerCam.defaults = {
    -- Camera (seat position + FOV override); first category in the UI
    camEnable  = true,   -- master toggle for the camera-options section
    camFwd     = 0.0,    -- seat offset forward/back (m, + = forward)
    camUp      = 0.0,    -- seat offset up/down (m, + = up)
    camYaw     = 0.0,    -- aim rotation left/right (deg, + = right)
    camPitch   = 0.0,    -- aim rotation up/down (deg, + = up)
    camFov     = 65.0,   -- FOV override (deg); replaces the stock camera FOV
    steerEnable = true,  -- master toggle for the steer-follow turn
    angle      = 18.0,   -- max yaw at full lock (deg)
    reach      = 65.0,   -- % of steering input at which the full angle is reached
    stiffness  = 15.0,   -- transition speed (higher = snappier)
    speedFade  = false,  -- scale turn by speed (off = full at any speed)
    fadeSpeed  = 8.0,    -- m/s for full strength when speedFade is on
    glanceEnable = true, -- master toggle for blind-spot glance
    glanceLeft  = 115.0, -- blind-spot glance angle to the left (deg)
    glanceRight = 115.0, -- blind-spot glance angle to the right (deg)
    glanceTime  = 120.0, -- ms to complete a glance (<=5 = instant snap)
    glanceOffsetLeft  = 0.10, -- m to lean left when glancing left
    glanceOffsetRight = 0.10, -- m to lean right when glancing right
    -- "Speed modifiers" (mostly for fun; both ramp to full strength at speedRange)
    speedModEnable = true, -- master toggle for the whole speed-modifiers section
    vertigo    = false,  -- FOV widens with speed (speed vertigo)
    vertigoFov = 12.0,   -- max extra FOV (deg) reached at speedRange
    vertigoDolly = 0.30, -- distance (m) kept pinned by the counter-dolly (0 = off)
    speedRoll  = false,  -- camera banks into corners, scaled by speed
    rollAngle  = 5.0,    -- max roll (deg)
    speedRange = 160.0,  -- km/h at which the effects reach full strength
  }

  -- The Custom profile (editable; starts as a copy of Default, then persists).
  steerCam.custom = {
    camEnable  = getBool("steerCam_custom_camEnable", steerCam.defaults.camEnable),
    camFwd     = getNum("steerCam_custom_camFwd",     steerCam.defaults.camFwd),
    camUp      = getNum("steerCam_custom_camUp",      steerCam.defaults.camUp),
    camYaw     = getNum("steerCam_custom_camYaw",     steerCam.defaults.camYaw),
    camPitch   = getNum("steerCam_custom_camPitch",   steerCam.defaults.camPitch),
    camFov     = getNum("steerCam_custom_camFov",     steerCam.defaults.camFov),
    steerEnable = getBool("steerCam_custom_steerEnable", steerCam.defaults.steerEnable),
    angle      = getNum("steerCam_custom_angle",       steerCam.defaults.angle),
    reach      = getNum("steerCam_custom_reach",       steerCam.defaults.reach),
    stiffness  = getNum("steerCam_custom_stiffness",   steerCam.defaults.stiffness),
    speedFade  = getBool("steerCam_custom_speedFade",  steerCam.defaults.speedFade),
    fadeSpeed  = getNum("steerCam_custom_fadeSpeed",   steerCam.defaults.fadeSpeed),
    glanceEnable = getBool("steerCam_custom_glanceEnable", steerCam.defaults.glanceEnable),
    glanceLeft  = getNum("steerCam_custom_glanceLeft",   steerCam.defaults.glanceLeft),
    glanceRight = getNum("steerCam_custom_glanceRight",  steerCam.defaults.glanceRight),
    glanceTime  = getNum("steerCam_custom_glanceTime",   steerCam.defaults.glanceTime),
    glanceOffsetLeft  = getNum("steerCam_custom_glanceOffsetLeft",  steerCam.defaults.glanceOffsetLeft),
    glanceOffsetRight = getNum("steerCam_custom_glanceOffsetRight", steerCam.defaults.glanceOffsetRight),
    speedModEnable = getBool("steerCam_custom_speedModEnable", steerCam.defaults.speedModEnable),
    vertigo    = getBool("steerCam_custom_vertigo",    steerCam.defaults.vertigo),
    vertigoFov = getNum("steerCam_custom_vertigoFov",  steerCam.defaults.vertigoFov),
    vertigoDolly = getNum("steerCam_custom_vertigoDolly", steerCam.defaults.vertigoDolly),
    speedRoll  = getBool("steerCam_custom_speedRoll",  steerCam.defaults.speedRoll),
    rollAngle  = getNum("steerCam_custom_rollAngle",   steerCam.defaults.rollAngle),
    speedRange = getNum("steerCam_custom_speedRange",  steerCam.defaults.speedRange),
  }

  steerCam.preset = getStr("steerCam_preset", "Default")
  -- steerCam.cfg points at whichever profile is active (the camera reads this)
  steerCam.cfg = (steerCam.preset == "Custom") and steerCam.custom or steerCam.defaults

  local ranges = {
    camFwd = {-0.5, 0.5}, camUp = {-0.5, 0.5}, camYaw = {-45, 45}, camPitch = {-45, 45}, camFov = {40, 120},
    angle = {0, 90}, reach = {10, 100}, stiffness = {1, 40}, fadeSpeed = {0.5, 40},
    glanceLeft = {0, 170}, glanceRight = {0, 170}, glanceTime = {0, 500},
    glanceOffsetLeft = {0, 0.6}, glanceOffsetRight = {0, 0.6},
    vertigoFov = {0, 40}, vertigoDolly = {0, 1.5}, rollAngle = {0, 20}, speedRange = {20, 400},
  }
  local bools  = {
    speedFade = true, vertigo = true, speedRoll = true,
    camEnable = true, steerEnable = true, glanceEnable = true, speedModEnable = true,
  }

  -- UI: switch active profile
  function steerCam.setPreset(name)
    if name ~= "Custom" then name = "Default" end
    steerCam.preset = name
    steerCam.cfg = (name == "Custom") and steerCam.custom or steerCam.defaults
    save("steerCam_preset", name)
  end

  -- UI: edit a Custom value (Default is never modified)
  function steerCam.set(key, value)
    local c = steerCam.custom
    if c[key] == nil then return end
    if bools[key] then
      c[key] = (value == true or value == 1 or value == "true")
    else
      value = tonumber(value)
      if value == nil then return end
      local r = ranges[key]
      if r then value = clampv(value, r[1], r[2]) end
      c[key] = value
    end
    save("steerCam_custom_" .. key, c[key])
  end

  -- UI: read the active profile's values + which preset is selected
  function steerCam.getCfg()
    local a = steerCam.cfg
    return {
      preset = steerCam.preset,
      camEnable = a.camEnable, camFwd = a.camFwd, camUp = a.camUp,
      camYaw = a.camYaw, camPitch = a.camPitch, camFov = a.camFov,
      steerEnable = a.steerEnable,
      angle = a.angle, reach = a.reach, stiffness = a.stiffness,
      speedFade = a.speedFade, fadeSpeed = a.fadeSpeed,
      glanceEnable = a.glanceEnable,
      glanceLeft = a.glanceLeft, glanceRight = a.glanceRight, glanceTime = a.glanceTime,
      glanceOffsetLeft = a.glanceOffsetLeft, glanceOffsetRight = a.glanceOffsetRight,
      speedModEnable = a.speedModEnable,
      vertigo = a.vertigo, vertigoFov = a.vertigoFov, vertigoDolly = a.vertigoDolly,
      speedRoll = a.speedRoll, rollAngle = a.rollAngle, speedRange = a.speedRange,
    }
  end

  -- ----- Blind-spot glance runtime ------------------------------------------
  -- Side convention: left = +1, right = -1 (matches steer-left = positive yaw).
  steerCam.glanceHoldSide   = 0   -- held key: -1 right / 0 none / +1 left
  steerCam.glanceToggleSide = 0   -- latched side (toggle binding / UI preview)

  local function sideNum(s)
    if s == "left"  or s == 1  then return 1  end
    if s == "right" or s == -1 then return -1 end
    return 0
  end
  local function truthy(v) return v == true or v == 1 or v == "true" end

  -- hold bindings: glance while the key is down, return on release
  function steerCam.glanceHold(side, down)
    local s = sideNum(side); if s == 0 then return end
    if truthy(down) then
      steerCam.glanceHoldSide = s
    elseif steerCam.glanceHoldSide == s then
      steerCam.glanceHoldSide = 0
    end
  end

  -- toggle bindings: flip the latched glance for a side
  function steerCam.glanceToggle(side)
    local s = sideNum(side); if s == 0 then return end
    steerCam.glanceToggleSide = (steerCam.glanceToggleSide == s) and 0 or s
  end

  -- UI preview buttons: set the latched glance explicitly
  function steerCam.glanceSet(side, on)
    local s = sideNum(side); if s == 0 then return end
    if truthy(on) then
      steerCam.glanceToggleSide = s
    elseif steerCam.glanceToggleSide == s then
      steerCam.glanceToggleSide = 0
    end
  end

  -- UI: read latched/held state so the app can highlight the active side
  function steerCam.getGlanceState()
    return { hold = steerCam.glanceHoldSide, toggle = steerCam.glanceToggleSide }
  end
end

local makeStockDriver = require('core/cameraModes/driver')

local qtmp = quat()
local gFwd, gUp, gRight = vec3(), vec3(), vec3()  -- scratch for the glance lean
local vecY = vec3(0, 1, 0)                         -- camera-local forward axis
local vecZup = vec3(0, 0, 1)                       -- world up axis
local rad = math.rad
local function clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end
local function clampUnit(x) return x < -1 and -1 or (x > 1 and 1 or x) end

-- Make SteerCam look like the stock "driver" camera to the UI, so per-app
-- "Hide in cockpit view" works while SteerCam is active. BeamNG only hides
-- cockpit apps when the active camera name is exactly "driver" (see the UI's
-- app-service handleCameraChange). We remap our name on EVERY notification so a
-- later engine re-broadcast of "steercam" can't undo it (a one-shot is not
-- enough). Approach mirrors the Enhanced Interior Camera mod. Installed once.
do
  local gh = rawget(_G, 'guihooks')
  if type(gh) == 'table' and type(gh.trigger) == 'function' and not gh._steerCamWrapped then
    local orig = gh.trigger
    gh.trigger = function(evt, payload, ...)
      if evt == 'onCameraNameChanged' then          -- drives cockpit app hide/show
        if type(payload) ~= 'table' then payload = { name = payload } end
        if payload.name == 'steercam' then payload.name = 'driver' end
      elseif evt == 'CameraConfigChanged' and type(payload) == 'table' then
        if payload.focusedCamName == 'steercam' then payload.focusedCamName = 'driver' end
      end
      return orig(evt, payload, ...)
    end
    gh._steerCamWrapped = true
  end
end

do
  local ex = rawget(_G, 'extensions')
  if type(ex) == 'table' and type(ex.hook) == 'function' and not ex._steerCamCamWrap then
    local origHook = ex.hook
    ex.hook = function(evt, ...)
      if evt == 'onCameraModeChanged' and select(1, ...) == 'steercam' then
        return origHook(evt, 'driver', select(2, ...))   -- forward remaining args intact
      end
      return origHook(evt, ...)
    end
    ex._steerCamCamWrap = true
  end
end

return function(...)
  local o = makeStockDriver(...)   -- a real stock driver-camera instance
  o.steerYaw  = 0
  o.glanceAmt = 0   -- 0..1 how far the glance overrides steer-follow
  o.glanceYaw = 0   -- target yaw of the active glance (rad)
  o.glanceLat = 0   -- target lateral lean of the active glance (m, + = car right)
  o.rollCur   = 0   -- current smoothed speed-roll (rad)
  o.spdSmooth = 0   -- low-passed speed, so scrub/surge doesn't jitter the effects
  o._uiKeepAlive = 0   -- timer to reassert the cockpit-hide while active

  -- reset the reassert timer on any camera change so it fires again next frame
  o.onCameraChanged = function(self, focused)
    self._uiKeepAlive = 0
  end

  local stockUpdate = o.update
  o.update = function(self, data)
    stockUpdate(self, data)        -- stock fills data.res.pos / rot / fov

    -- Reassert "driver" to the UI every 0.5s while active. The guihooks wrapper
    -- (above) already remaps the engine's own notifications, but external toggles
    -- (UI close, multiplayer, etc.) can reset the cockpit state without one.
    self._uiKeepAlive = (self._uiKeepAlive or 0) - data.dt
    if self._uiKeepAlive <= 0 then
      self._uiKeepAlive = 0.5
      if guihooks then guihooks.trigger('onCameraNameChanged', { name = 'driver' }) end
    end

    local c = steerCam.cfg
    local dt = data.dt
    if dt < 1e-4 then dt = 1e-4 end

    -- Camera options: FOV override + seat position offset. Applied first, so the
    -- speed-vertigo FOV stacks on top of the override and offsets ride along.
    if c.camEnable then
      if c.camFov and data.res.fov then data.res.fov = c.camFov end
      if (c.camFwd ~= 0 or c.camUp ~= 0) and data.veh ~= nil then
        gFwd:set(data.veh:getDirectionVector())     -- car forward (world)
        gUp:set(data.veh:getDirectionVectorUp())    -- car up (world)
        gFwd:setScaled(c.camFwd or 0)
        gUp:setScaled(c.camUp or 0)
        data.res.pos:setAdd(gFwd)
        data.res.pos:setAdd(gUp)
      end
      -- Pan/tilt gimbal (tripod/turret style): aim by azimuth (about WORLD up) +
      -- elevation (about the horizontal-right), then rebuild with a LEVEL horizon.
      -- So up/down is ALWAYS world-vertical (straight up/down), pan stays
      -- horizontal, they're independent, and it can't curve at any pan amount.
      if (c.camYaw or 0) ~= 0 or (c.camPitch or 0) ~= 0 then
        gFwd:set(data.res.rot * vecY)                 -- current look direction
        if (c.camYaw or 0) ~= 0 then
          gFwd:set(quatFromAxisAngle(vecZup, rad(c.camYaw)) * gFwd)     -- azimuth; - = left
        end
        if (c.camPitch or 0) ~= 0 then
          gRight:setCross(gFwd, vecZup); gRight:normalize()            -- horizontal right
          gFwd:set(quatFromAxisAngle(gRight, rad(-(c.camPitch))) * gFwd) -- elevation; flipped
        end
        data.res.rot:setFromDir(gFwd, vecZup)         -- look at aimed dir, horizon level
      end
    end

    -- steerRaw is read regardless so the speed-roll can use it even when the
    -- steer-follow turn is disabled; the yaw itself respects steerEnable.
    local steerRaw = 0
    if steerCamFeed ~= nil and data.veh ~= nil then
      local vid = data.veh.getID and data.veh:getID() or nil
      if vid ~= nil then steerRaw = steerCamFeed[vid] or 0 end
    end
    local steer = c.steerEnable and steerRaw or 0

    local reachFrac = (c.reach or 100) / 100
    if reachFrac < 0.1 then reachFrac = 0.1 end
    local yawTarget = rad(c.angle) * clampUnit(steer / reachFrac)
    if c.speedFade then
      local spd = (data.vel and data.vel:length()) or 0
      yawTarget = yawTarget * clamp01(spd / (c.fadeSpeed > 0.1 and c.fadeSpeed or 0.1))
    end
    self.steerYaw = self.steerYaw + (yawTarget - self.steerYaw) * clamp01(dt * c.stiffness)

    -- Blind-spot glance: overrides steer-follow while a side is engaged, then
    -- blends back. A held key wins over a latched toggle / UI preview. When the
    -- category is disabled the keybinds still fire (harmless) but are ignored.
    local side = 0
    if c.glanceEnable then
      side = (steerCam.glanceHoldSide ~= 0) and steerCam.glanceHoldSide
                                             or steerCam.glanceToggleSide
    end
    local desired = 0
    if side ~= 0 then
      desired = 1
      -- side: left = +1, right = -1. Positive yaw turns the view right, so the
      -- left glance is negative. The lean leans toward the side you look at:
      -- left = -X (car left), right = +X (car right).
      self.glanceYaw = (side > 0) and -rad(c.glanceLeft or 0) or rad(c.glanceRight or 0)
      self.glanceLat = (side > 0) and -(c.glanceOffsetLeft or 0) or (c.glanceOffsetRight or 0)
    end
    -- glanceTime = ms to reach ~95% of the glance; <=5ms snaps instantly
    local gt = c.glanceTime or 100
    if gt <= 5 then
      self.glanceAmt = desired
    else
      self.glanceAmt = self.glanceAmt + (desired - self.glanceAmt) * clamp01(dt * (3000 / gt))
    end

    -- glanceAmt=1 → pure glance (override); glanceAmt=0 → pure steer-follow
    local finalYaw = self.steerYaw + (self.glanceYaw - self.steerYaw) * self.glanceAmt
    qtmp:setFromEuler(0, 0, finalYaw)
    data.res.rot:setMul2(qtmp, data.res.rot)

    -- lean the camera sideways along the car's world right vector (forward x up)
    local lat = self.glanceLat * self.glanceAmt
    if lat ~= 0 and data.veh ~= nil then
      gFwd:set(data.veh:getDirectionVector())
      gUp:set(data.veh:getDirectionVectorUp())
      gRight:setCross(gFwd, gUp)   -- standard X-right/Y-fwd/Z-up: fwd x up = right
      gRight:normalize()
      gRight:setScaled(lat)
      data.res.pos:setAdd(gRight)
    end

    -- ----- Speed modifiers: speed-driven FOV vertigo + corner roll -----------
    -- Both ramp to full strength as speed approaches speedRange (shared ceiling).
    -- Speed is low-passed so tyre scrub/surge can't jitter the roll or FOV.
    local spdRaw = (data.vel and data.vel:length()) or 0
    self.spdSmooth = self.spdSmooth + (spdRaw - self.spdSmooth) * clamp01(dt * 3)
    local sr = (c.speedRange or 160) / 3.6            -- km/h -> m/s ceiling
    local speedFac = clamp01(self.spdSmooth / (sr > 0.1 and sr or 0.1))
    local modsOn = c.speedModEnable

    if modsOn and c.vertigo and data.res.fov then
      local f0 = data.res.fov
      local fovAdd = (c.vertigoFov or 0) * speedFac
      data.res.fov = f0 + fovAdd
      -- dolly-zoom ("vertigo"): push the camera forward on the same speed curve
      -- so a plane at vertigoDolly metres keeps its size while the FOV widens.
      local refDist = c.vertigoDolly or 0
      if fovAdd > 0.01 and refDist > 0.001 then
        local t0 = math.tan(rad(f0) * 0.5)
        local t1 = math.tan(rad(f0 + fovAdd) * 0.5)
        local fwdMove = refDist * (1 - t0 / (t1 > 1e-4 and t1 or 1e-4))
        gFwd:set(data.res.rot * vecY)                  -- world view-forward
        gFwd:setScaled(fwdMove)
        data.res.pos:setAdd(gFwd)
      end
    end

    -- roll amount = (min(speed, speedRange) / speedRange) * steering * rollAngle
    -- steering: +1 = right, 0 = neutral, -1 = left.
    local rollTarget = 0
    if modsOn and c.speedRoll then
      rollTarget = rad(c.rollAngle or 0) * clampUnit(steerRaw) * speedFac
    end
    self.rollCur = self.rollCur + (rollTarget - self.rollCur) * clamp01(dt * 6)
    if modsOn and c.speedRoll then
      -- Our own transform: rebuild the orientation with a LEVEL horizon rolled by
      -- EXACTLY rollCur about the look axis. setFromDir(forward, up) discards the
      -- stock camera's own (wobbling) cornering roll, so only our tilt remains and
      -- the horizon is rock-steady level -- no roll wobble riding along on top.
      gFwd:set(data.res.rot * vecY)                             -- look direction (roll axis)
      gUp:set(quatFromAxisAngle(gFwd, -self.rollCur) * vecZup)  -- right turn -> lean right
      data.res.rot:setFromDir(gFwd, gUp)
    end
  end

  return o
end
