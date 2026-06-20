-- SteerCam :: driver camera with ETS2-style "steer camera turn"
-- ----------------------------------------------------------------------------
-- File: lua/ge/extensions/core/cameraModes/driversteer.lua
--
-- A selectable driver camera that turns the view toward where the wheels are
-- pointed. Enable in Options -> Camera -> Switching order (tick "Driversteer"),
-- press C. Adjust from the "SteerCam Settings" UI app.
--
-- Profiles:
--   File presets : every *.json in /settings/steercam/presets/ becomes a
--                  read-only preset (Default + Dev's Preset ship with the mod).
--                  Drop another .json in that folder to add your own.
--   Custom       : your own saved values, editable. Persists independently, so
--                  it remembers your tweaks even after switching presets.
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

  -- Baseline values. Kept inline as the guaranteed fallback if no preset files
  -- load, the base sanitizePreset fills missing keys from, and the seed for the
  -- Custom profile. The shipped default.json mirrors this for the dropdown entry.
  steerCam.defaults = {
    camEnable = true, camFwd = 0.0, camUp = 0.0, camYaw = 0.0, camPitch = 0.0, camFov = 65.0, stableHorizon = 0.0,
    steerEnable = true, angle = 18.0, reach = 65.0, stiffness = 15.0,
    reverseSteer = false, reverseAngle = 9.0, reverseTime = 500.0, speedFade = false, fadeSpeed = 30.0, fadeFloor = 0.0,
    glanceEnable = true, glanceLeft = 115.0, glanceRight = 115.0, glanceTime = 120.0,
    glanceOffsetLeft = 0.10, glanceOffsetRight = 0.10, glanceCurve = "Exponential",
    speedModEnable = false, vertigo = false, vertigoFov = 12.0, vertigoDolly = 0.30,
    speedRoll = false, rollAngle = 5.0, speedRange = 160.0,
  }

  -- Setting metadata: numeric ranges (clamped), booleans, and string-valued keys.
  -- Shared by sanitizePreset (file loads) and steerCam.set (Custom edits).
  local ranges = {
    camFwd = {-0.5, 0.5},
    camUp = {-0.5, 0.5},
    camYaw = {-45, 45},
    camPitch = {-45, 45},
    camFov = {40, 120}, stableHorizon = {0, 100},
    angle = {0, 90}, reach = {10, 100}, stiffness = {1, 40}, fadeSpeed = {5, 150}, fadeFloor = {0, 100},
    reverseAngle = {0, 90}, reverseTime = {0, 3000},
    glanceLeft = {0, 170}, glanceRight = {0, 170}, glanceTime = {0, 500},
    glanceOffsetLeft = {-0.5, 0.5}, glanceOffsetRight = {-0.5, 0.5},
    vertigoFov = {0, 40}, vertigoDolly = {0, 1.5}, rollAngle = {0, 20}, speedRange = {20, 400},
  }
  local bools  = {
    speedFade = true, vertigo = true, speedRoll = true,
    camEnable = true, steerEnable = true, glanceEnable = true, speedModEnable = true,
    reverseSteer = true,
  }
  local strs = { glanceCurve = true }   -- string-valued settings

  -- Build a clean cfg from a decoded preset file: start from Default, then copy
  -- over any KNOWN key (correct type; numbers clamped to range). Unknown keys are
  -- ignored and missing keys keep the Default, so partial/old files stay valid.
  local function sanitizePreset(raw)
    local cfg = {}
    for k, v in pairs(steerCam.defaults) do cfg[k] = v end
    if type(raw) == "table" then
      for k in pairs(steerCam.defaults) do
        local rv = raw[k]
        if rv ~= nil then
          if bools[k] then
            cfg[k] = (rv == true or rv == 1 or rv == "true")
          elseif strs[k] then
            cfg[k] = tostring(rv)
          else
            local n = tonumber(rv)
            if n ~= nil then
              local r = ranges[k]
              if r then n = clampv(n, r[1], r[2]) end
              cfg[k] = n
            end
          end
        end
      end
    end
    return cfg
  end

  -- Scan the presets folder and load every *.json as a read-only preset -- the
  -- same FS:findFiles + jsonReadFile pattern the game uses for campaigns etc. The
  -- virtual filesystem overlays the mod's bundled presets AND any files the user
  -- drops in <userfolder>/settings/steercam/presets/, so both appear here.
  steerCam.presetsDir = "/settings/steercam/presets/"
  function steerCam.loadPresets()
    local presets, meta, order = {}, {}, {}   -- name->cfg, name->sortKey, [names]
    local files = (FS and FS.findFiles) and FS:findFiles(steerCam.presetsDir, "*.json", 0, false, false) or {}
    for _, file in ipairs(files) do
      local raw = jsonReadFile(file)
      if type(raw) == "table" then
        local name = (type(raw.name) == "string" and raw.name ~= "") and raw.name or nil
        if not name then
          local _, fn = path.splitWithoutExt(file)   -- fall back to the filename
          name = fn
        end
        if name and name ~= "Custom" and not presets[name] then
          presets[name] = sanitizePreset(raw)
          meta[name]    = tonumber(raw.order) or 100
          order[#order + 1] = name
        end
      end
    end
    -- Default always exists (synthesized from the inline table if no file loads)
    -- and is always pinned to the top of the list.
    if not presets["Default"] then
      presets["Default"] = sanitizePreset(steerCam.defaults)
      order[#order + 1] = "Default"
    end
    meta["Default"] = -math.huge
    table.sort(order, function(a, b)
      local oa, ob = meta[a] or 100, meta[b] or 100
      if oa ~= ob then return oa < ob end
      return a < b
    end)
    steerCam.presets     = presets
    steerCam.presetOrder = order
  end
  steerCam.loadPresets()

  -- The Custom profile (editable; starts as a copy of Default, then persists).
  steerCam.custom = {
    camEnable  = getBool("steerCam_custom_camEnable", steerCam.defaults.camEnable),
    camFwd     = getNum("steerCam_custom_camFwd",     steerCam.defaults.camFwd),
    camUp      = getNum("steerCam_custom_camUp",      steerCam.defaults.camUp),
    camYaw     = getNum("steerCam_custom_camYaw",     steerCam.defaults.camYaw),
    camPitch   = getNum("steerCam_custom_camPitch",   steerCam.defaults.camPitch),
    camFov     = getNum("steerCam_custom_camFov",     steerCam.defaults.camFov),
    stableHorizon = getNum("steerCam_custom_stableHorizon", steerCam.defaults.stableHorizon),
    steerEnable = getBool("steerCam_custom_steerEnable", steerCam.defaults.steerEnable),
    angle      = getNum("steerCam_custom_angle",       steerCam.defaults.angle),
    reach      = getNum("steerCam_custom_reach",       steerCam.defaults.reach),
    stiffness  = getNum("steerCam_custom_stiffness",   steerCam.defaults.stiffness),
    reverseSteer = getBool("steerCam_custom_reverseSteer", steerCam.defaults.reverseSteer),
    reverseAngle = getNum("steerCam_custom_reverseAngle",  steerCam.defaults.reverseAngle),
    reverseTime  = getNum("steerCam_custom_reverseTime",   steerCam.defaults.reverseTime),
    speedFade  = getBool("steerCam_custom_speedFade",  steerCam.defaults.speedFade),
    fadeSpeed  = getNum("steerCam_custom_fadeSpeed",   steerCam.defaults.fadeSpeed),
    fadeFloor  = getNum("steerCam_custom_fadeFloor",   steerCam.defaults.fadeFloor),
    glanceEnable = getBool("steerCam_custom_glanceEnable", steerCam.defaults.glanceEnable),
    glanceLeft  = getNum("steerCam_custom_glanceLeft",   steerCam.defaults.glanceLeft),
    glanceRight = getNum("steerCam_custom_glanceRight",  steerCam.defaults.glanceRight),
    glanceTime  = getNum("steerCam_custom_glanceTime",   steerCam.defaults.glanceTime),
    glanceOffsetLeft  = getNum("steerCam_custom_glanceOffsetLeft",  steerCam.defaults.glanceOffsetLeft),
    glanceOffsetRight = getNum("steerCam_custom_glanceOffsetRight", steerCam.defaults.glanceOffsetRight),
    glanceCurve = getStr("steerCam_custom_glanceCurve", steerCam.defaults.glanceCurve),
    speedModEnable = getBool("steerCam_custom_speedModEnable", steerCam.defaults.speedModEnable),
    vertigo    = getBool("steerCam_custom_vertigo",    steerCam.defaults.vertigo),
    vertigoFov = getNum("steerCam_custom_vertigoFov",  steerCam.defaults.vertigoFov),
    vertigoDolly = getNum("steerCam_custom_vertigoDolly", steerCam.defaults.vertigoDolly),
    speedRoll  = getBool("steerCam_custom_speedRoll",  steerCam.defaults.speedRoll),
    rollAngle  = getNum("steerCam_custom_rollAngle",   steerCam.defaults.rollAngle),
    speedRange = getNum("steerCam_custom_speedRange",  steerCam.defaults.speedRange),
  }

  -- steerCam.cfg points at whichever profile is active (the camera reads this).
  local function resolveCfg(name)
    if name == "Custom" then return steerCam.custom end
    return steerCam.presets[name] or steerCam.presets["Default"] or steerCam.defaults
  end
  steerCam.preset = getStr("steerCam_preset", "Default")
  steerCam.cfg = resolveCfg(steerCam.preset)

  -- Global mod on/off (independent of the preset; persists). When off, the camera
  -- behaves like the stock driver cam -- every SteerCam effect below is skipped.
  steerCam.enabled = getBool("steerCam_enabled", true)
  function steerCam.setEnabled(v)
    steerCam.enabled = (v == true or v == 1 or v == "true")
    save("steerCam_enabled", steerCam.enabled)
  end

  -- Driver-seat mirroring (global, default on). Saved values describe a LEFT-hand-
  -- drive seat (the ground truth, since most cars are LHD). In a right-hand-drive
  -- car we auto-flip the side-specific settings (camera pan + glance L/R) so the
  -- feel is symmetric about the driver -- the input direction is never flipped.
  steerCam.mirrorSeat = getBool("steerCam_mirrorSeat", true)
  function steerCam.setMirror(v)
    steerCam.mirrorSeat = (v == true or v == 1 or v == "true")
    save("steerCam_mirrorSeat", steerCam.mirrorSeat)
  end

  -- UI: switch active profile (presets are file-defined; only Custom is editable)
  function steerCam.setPreset(name)
    if name ~= "Custom" and not steerCam.presets[name] then name = "Default" end
    steerCam.preset = name
    steerCam.cfg = resolveCfg(name)
    save("steerCam_preset", name)
  end

  -- Re-scan the presets folder at runtime (console: steerCam.reloadPresets()).
  -- Re-resolves the active cfg so a removed/renamed preset falls back cleanly.
  function steerCam.reloadPresets()
    steerCam.loadPresets()
    steerCam.setPreset(steerCam.preset)
  end

  -- UI: edit a Custom value (Default is never modified)
  function steerCam.set(key, value)
    local c = steerCam.custom
    if c[key] == nil then return end
    if bools[key] then
      c[key] = (value == true or value == 1 or value == "true")
    elseif strs[key] then
      c[key] = tostring(value)
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
      modEnabled = steerCam.enabled,
      mirrorSeat = steerCam.mirrorSeat,
      camEnable = a.camEnable, camFwd = a.camFwd, camUp = a.camUp,
      camYaw = a.camYaw, camPitch = a.camPitch, camFov = a.camFov, stableHorizon = a.stableHorizon,
      steerEnable = a.steerEnable,
      angle = a.angle, reach = a.reach, stiffness = a.stiffness,
      reverseSteer = a.reverseSteer, reverseAngle = a.reverseAngle, reverseTime = a.reverseTime,
      speedFade = a.speedFade, fadeSpeed = a.fadeSpeed, fadeFloor = a.fadeFloor,
      glanceEnable = a.glanceEnable,
      glanceLeft = a.glanceLeft, glanceRight = a.glanceRight, glanceTime = a.glanceTime,
      glanceOffsetLeft = a.glanceOffsetLeft, glanceOffsetRight = a.glanceOffsetRight,
      glanceCurve = a.glanceCurve,
      speedModEnable = a.speedModEnable,
      vertigo = a.vertigo, vertigoFov = a.vertigoFov, vertigoDolly = a.vertigoDolly,
      speedRoll = a.speedRoll, rollAngle = a.rollAngle, speedRange = a.speedRange,
    }
  end

  -- UI: the ordered preset list for the dropdown (Custom pinned last)
  function steerCam.getPresetNames()
    local names = {}
    for _, n in ipairs(steerCam.presetOrder or {}) do names[#names + 1] = n end
    names[#names + 1] = "Custom"
    return names
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

-- Easing curves: map a 0..1 progress to a 0..1 eased value (glance + reverse).
local exp = math.exp
local function easeLinear(p) return p end
local function easeExp(p)             -- exponential ease-out: sharp start, soft tail
  if p <= 0 then return 0 end
  if p >= 1 then return 1 end
  return (1 - exp(-5 * p)) / (1 - exp(-5))
end
local function easeSCurve(p)          -- smootherstep S-curve: gentle in and out
  if p <= 0 then return 0 end
  if p >= 1 then return 1 end
  return p * p * p * (p * (p * 6 - 15) + 10)
end
local function makeBezier(x1, y1, x2, y2)   -- CSS cubic-bezier(x1,y1,x2,y2)
  return function(p)
    if p <= 0 then return 0 end
    if p >= 1 then return 1 end
    local t = p
    for _ = 1, 6 do                   -- Newton: solve bezierX(t) = p for t
      local mt = 1 - t
      local fx = 3*mt*mt*t*x1 + 3*mt*t*t*x2 + t*t*t - p
      local dx = 3*mt*mt*x1 + 6*mt*t*(x2 - x1) + 3*t*t*(1 - x2)
      if dx > -1e-6 and dx < 1e-6 then break end
      t = t - fx / dx
      if t < 0 then t = 0 elseif t > 1 then t = 1 end
    end
    local mt = 1 - t
    return 3*mt*mt*t*y1 + 3*mt*t*t*y2 + t*t*t   -- bezierY(t)
  end
end
local easeCurves = {
  Exponential = easeExp,
  Linear      = easeLinear,
  ["S-curve"] = easeSCurve,
  Ease1       = makeBezier(0.520, 0.359, 0.262, 0.934),
  Ease2       = makeBezier(0.311, 0.130, 0.109, 0.992),
}

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
  -- Guard with a stored function ref in _G, NOT a key on the `extensions` table:
  -- the extension loader treated that key as a module name and logged "extension
  -- unavailable: _steerCamCamWrap". Comparing the live hook against our stored
  -- wrapper also re-wraps correctly if `extensions` ever reloads.
  if type(ex) == 'table' and type(ex.hook) == 'function' and ex.hook ~= rawget(_G, '_steerCamExHook') then
    local origHook = ex.hook
    local wrapped = function(evt, ...)
      if evt == 'onCameraModeChanged' and select(1, ...) == 'steercam' then
        return origHook(evt, 'driver', select(2, ...))   -- forward remaining args intact
      end
      return origHook(evt, ...)
    end
    ex.hook = wrapped
    rawset(_G, '_steerCamExHook', wrapped)
  end
end

return function(...)
  local o = makeStockDriver(...)   -- a real stock driver-camera instance
  o.steerYaw  = 0
  o.reverseBlend = 0   -- 0 = forward turn, 1 = mirrored (reverse) turn
  o.reverseFrom = 0; o.reverseProg = 1; o.reverseTargetVal = 0   -- reverse tween state
  o.glanceAmt = 0   -- 0..1 how far the glance overrides steer-follow
  o.glanceFrom = 0; o.glanceProg = 1; o.glanceTargetVal = 0      -- glance tween state
  o.glanceYaw = 0   -- target yaw of the active glance (rad)
  o.glanceLat = 0   -- target lateral lean of the active glance (m, + = car right)
  o.rollCur   = 0   -- current smoothed speed-roll (rad)
  o.spdSmooth = 0   -- low-passed speed, so scrub/surge doesn't jitter the effects
  o._uiKeepAlive = 0   -- timer to reassert the cockpit-hide while active
  o._rhd = nil   -- last-logged right-hand-drive flag (debug log throttle only)

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

    -- Mod globally disabled -> leave the stock driver result untouched.
    if not steerCam.enabled then return end

    local c = steerCam.cfg
    local dt = data.dt
    if dt < 1e-4 then dt = 1e-4 end

    -- Driver-seat mirroring: the saved values describe a LEFT-hand-drive seat; in
    -- a right-hand-drive car we flip the side-specific ones (camera pan + glance
    -- L/R) so the feel is symmetric about the driver. Input direction is never
    -- flipped (the right glance still looks right). RHD is the same flag the stock
    -- driver cam reads (core_camera.getDriverData), cached per vehicle.
    -- Driver-seat mirroring: recompute EVERY frame (cheap -- the stock driver cam
    -- calls getDriverData every frame too), so switching vehicles updates the
    -- mirror immediately with no Ctrl+L. RHD = the vehicle's onboard.driver camera
    -- flag (same one the stock cam uses for look-back). Seat-node geometry was
    -- unreliable (some cars centre the cam node); the earlier "mirrored an LHD car"
    -- was a false alarm -- that car was actually RHD, so the flag had been right.
    local rhd = false
    if data.veh ~= nil and core_camera and core_camera.getDriverData then
      local _, isRHD = core_camera.getDriverData(data.veh)
      rhd = (isRHD == true)
    end
    if rhd ~= self._rhd then        -- (debug) log only when it changes
      self._rhd = rhd
      log('I', 'steercam', 'rhd=' .. tostring(rhd)
          .. ' veh=' .. tostring(data.veh and data.veh.getJBeamFilename and data.veh:getJBeamFilename()))
    end
    local mirrored = steerCam.mirrorSeat and rhd

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
      -- Orientation rebuild: re-aim (pan/tilt) AND set the roll/up. This runs
      -- whenever there's a vehicle, so the roll ALWAYS applies -- not only when a
      -- pan/tilt value is set (that gating was why the bank + horizon slider "did
      -- nothing" with yaw/pitch at 0, falling back to the stock world-up rotation).
      -- Pan/tilt gimbal (tripod/turret): aim by azimuth (about WORLD up) + elevation
      -- (about the horizontal-right) -- up/down stays world-vertical, pan stays
      -- horizontal, independent, no curve. The rebuild's UP is the CAR's up (seat
      -- up) by default, so the horizon BANKS WITH THE CAR (NASCAR banking, off-
      -- camber turns). "Lock roll to horizon" (stableHorizon, copied 1:1 from the
      -- stock cam's cameraDriverStableHorizon) blends it back toward world-level,
      -- easing off the more the car is banked. setFromDir keeps the forward exactly,
      -- so only the roll changes.
      if data.veh ~= nil or (c.camYaw or 0) ~= 0 or (c.camPitch or 0) ~= 0 then
        gFwd:set(data.res.rot * vecY)                 -- current look direction
        if (c.camYaw or 0) ~= 0 then
          local camYaw = mirrored and -(c.camYaw) or c.camYaw   -- flip pan for a RHD seat
          gFwd:set(quatFromAxisAngle(vecZup, rad(camYaw)) * gFwd) -- azimuth; - = left
        end
        if (c.camPitch or 0) ~= 0 then
          gRight:setCross(gFwd, vecZup); gRight:normalize()            -- horizontal right
          gFwd:set(quatFromAxisAngle(gRight, rad(-(c.camPitch))) * gFwd) -- elevation; flipped
        end
        if data.veh ~= nil then
          gUp:set(data.veh:getDirectionVectorUp())    -- car/seat up (world)
          local sh = (c.stableHorizon or 0) / 100     -- 0..1 (0 = full bank, default)
          if sh > 0 then
            -- carRollFactor: 1 = follow car roll fully, 0 = dead level. The stock
            -- formula keeps more roll the steeper the bank (small up.z).
            local f = 1 - sh * smootheststep(clamp01(1.42 * gUp.z))
            gUp:setScaled(f)                          -- f * carUp
            gRight:set(vecZup); gRight:setScaled(1 - f)  -- (1-f) * worldUp
            gUp:setAdd(gRight)                        -- blended up
            gUp:normalize()
          end
          data.res.rot:setFromDir(gFwd, gUp)
        else
          data.res.rot:setFromDir(gFwd, vecZup)       -- no vehicle: fall back to level
        end
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
    -- while reversing (velocity opposes forward), blend toward the mirrored turn
    -- over reverseTime (anim curve like the glance). Smooths the low-speed kick-in
    -- AND buffers spin-outs where the velocity briefly flips direction.
    -- Reverse target: the SPEED vector decides whenever we're clearly moving
    -- (faster than ~1 km/h either way). Near a standstill the gear decides intent
    -- instead -- reverse gear -> reverse, a forward gear -> forward, park/neutral
    -- -> hold the current state. (steerCamGear is fed from the vehicle VM:
    -- -1 reverse / 0 neutral|park / +1 forward.)
    local revTarget = 0
    if c.reverseSteer and data.vel ~= nil and data.veh ~= nil then
      gFwd:set(data.veh:getDirectionVector())
      local fwdSpeed = data.vel:dot(gFwd)          -- m/s along the car's forward
      local nzSpd = 1 / 3.6                         -- 1 km/h dead-zone for the speed test
      if fwdSpeed < -nzSpd then
        revTarget = 1                              -- clearly rolling backward
      elseif fwdSpeed > nzSpd then
        revTarget = 0                              -- clearly rolling forward
      else                                          -- near standstill: let the gear decide
        local vid = data.veh.getID and data.veh:getID() or nil
        local gdir = (vid ~= nil and steerCamGear ~= nil) and steerCamGear[vid] or 0
        if gdir == -1 then revTarget = 1
        elseif gdir == 1 then revTarget = 0
        else revTarget = self.reverseTargetVal end  -- park/neutral: keep current
      end
    end
    if revTarget ~= self.reverseTargetVal then       -- (re)start the tween on a flip
      self.reverseFrom = self.reverseBlend
      self.reverseTargetVal = revTarget
      self.reverseProg = 0
    end
    local rt = c.reverseTime or 0
    if rt <= 5 then
      self.reverseProg = 1
      self.reverseBlend = self.reverseTargetVal
    else
      self.reverseProg = clamp01(self.reverseProg + dt * 1000 / rt)
      self.reverseBlend = self.reverseFrom + (self.reverseTargetVal - self.reverseFrom) * easeSCurve(self.reverseProg)
    end
    -- effective angle blends forward (+angle) -> mirrored (-reverseAngle)
    local effAngle = rad(c.angle) * (1 - self.reverseBlend) - rad(c.reverseAngle or 0) * self.reverseBlend
    local yawTarget = effAngle * clampUnit(steer / reachFrac)
    if c.speedFade then
      local spd = (data.vel and data.vel:length()) or 0
      local fadeMs = (c.fadeSpeed or 30) / 3.6     -- km/h -> m/s
      local ramp = clamp01(spd / (fadeMs > 0.1 and fadeMs or 0.1))
      -- fadeFloor: a % of the full turn that's allowed even at a standstill; the
      -- rest ramps in by fadeSpeed. 0 (default) = original "no turn until moving".
      local floor = (c.fadeFloor or 0) / 100
      yawTarget = yawTarget * (floor + (1 - floor) * ramp)
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
      -- side: left = +1, right = -1. The DIRECTION always follows the input (left
      -- input looks/leans left = negative), but the magnitude comes from that
      -- side's settings -- swapped L<->R when mirroring a right-hand-drive seat, so
      -- e.g. the right glance keybind still looks right but uses the left settings.
      local leftInput = side > 0
      local useLeft = leftInput
      if mirrored then useLeft = not useLeft end
      local gAngle  = useLeft and (c.glanceLeft or 0)       or (c.glanceRight or 0)
      local gOffset = useLeft and (c.glanceOffsetLeft or 0) or (c.glanceOffsetRight or 0)
      local dir = leftInput and -1 or 1
      self.glanceYaw = dir * rad(gAngle)
      self.glanceLat = dir * gOffset
    end
    -- glance amount: timed tween 0<->1 over glanceTime, through the chosen curve
    if desired ~= self.glanceTargetVal then          -- (re)start on engage/release
      self.glanceFrom = self.glanceAmt
      self.glanceTargetVal = desired
      self.glanceProg = 0
    end
    local gt = c.glanceTime or 100
    if gt <= 5 then
      self.glanceProg = 1
      self.glanceAmt = self.glanceTargetVal
    else
      self.glanceProg = clamp01(self.glanceProg + dt * 1000 / gt)
      local cf = easeCurves[c.glanceCurve] or easeExp
      self.glanceAmt = self.glanceFrom + (self.glanceTargetVal - self.glanceFrom) * cf(self.glanceProg)
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
      -- IMPORTANT: roll with OUR OWN vectors via a clean setFromDir REBUILD -- never
      -- by composing the roll on top of the incoming orientation. Multiplying a roll
      -- onto data.res.rot drags the stock driver cam's own cornering roll/pitch
      -- wobble along, which reads as the camera gently swaying up/down (a long-
      -- standing bug). So we pick a STABLE base "up" ourselves and rebuild from it:
      -- the SAME banked + horizon-locked up the camera override uses (so the lean
      -- rides the same horizon and keeps the car bank), or world-level when the
      -- override is off. Then lean that base by rollCur about the look axis
      -- (vecY = forward = the roll axis) and setFromDir. Stable like the old world-up
      -- rebuild, but it no longer flattens the bank.
      gFwd:set(data.res.rot * vecY)                            -- look direction (roll axis)
      if c.camEnable and data.veh ~= nil then
        gUp:set(data.veh:getDirectionVectorUp())              -- car/seat up: stable, banked
        local sh = (c.stableHorizon or 0) / 100
        if sh > 0 then                                        -- mirror the override's blend
          local f = 1 - sh * smootheststep(clamp01(1.42 * gUp.z))
          gUp:setScaled(f); gRight:set(vecZup); gRight:setScaled(1 - f)
          gUp:setAdd(gRight); gUp:normalize()
        end
      else
        gUp:set(vecZup)                                       -- override off: level base
      end
      gUp:set(quatFromAxisAngle(gFwd, -self.rollCur) * gUp)   -- lean the base up by rollCur
      data.res.rot:setFromDir(gFwd, gUp)                      -- clean rebuild, our own transform
    end
  end

  return o
end
