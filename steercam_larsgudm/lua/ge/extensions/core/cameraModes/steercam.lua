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
    angle     = 18.0,   -- max yaw at full lock (deg)
    reach     = 35.0,   -- % of steering input at which the full angle is reached
    stiffness = 15.0,   -- transition speed (higher = snappier)
    invert    = false,  -- flip turn direction
    speedFade = false,  -- scale turn by speed (off = full at any speed)
    fadeSpeed = 8.0,    -- m/s for full strength when speedFade is on
  }

  -- The Custom profile (editable; starts as a copy of Default, then persists).
  steerCam.custom = {
    angle     = getNum("steerCam_custom_angle",      steerCam.defaults.angle),
    reach     = getNum("steerCam_custom_reach",      steerCam.defaults.reach),
    stiffness = getNum("steerCam_custom_stiffness",  steerCam.defaults.stiffness),
    invert    = getBool("steerCam_custom_invert",    steerCam.defaults.invert),
    speedFade = getBool("steerCam_custom_speedFade", steerCam.defaults.speedFade),
    fadeSpeed = getNum("steerCam_custom_fadeSpeed",  steerCam.defaults.fadeSpeed),
  }

  steerCam.preset = getStr("steerCam_preset", "Default")
  -- steerCam.cfg points at whichever profile is active (the camera reads this)
  steerCam.cfg = (steerCam.preset == "Custom") and steerCam.custom or steerCam.defaults

  local ranges = { angle = {0, 90}, reach = {10, 100}, stiffness = {1, 40}, fadeSpeed = {0.5, 40} }
  local bools  = { invert = true, speedFade = true }

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
      angle = a.angle, reach = a.reach, stiffness = a.stiffness,
      invert = a.invert, speedFade = a.speedFade, fadeSpeed = a.fadeSpeed,
    }
  end
end

local makeStockDriver = require('core/cameraModes/driver')

local qtmp = quat()
local rad = math.rad
local function clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end
local function clampUnit(x) return x < -1 and -1 or (x > 1 and 1 or x) end

return function(...)
  local o = makeStockDriver(...)   -- a real stock driver-camera instance
  o.steerYaw = 0

  local stockUpdate = o.update
  o.update = function(self, data)
    stockUpdate(self, data)        -- stock fills data.res.pos / rot / fov

    local c = steerCam.cfg
    local dt = data.dt
    if dt < 1e-4 then dt = 1e-4 end

    local steer = 0
    if steerCamFeed ~= nil and data.veh ~= nil then
      local vid = data.veh.getID and data.veh:getID() or nil
      if vid ~= nil then steer = steerCamFeed[vid] or 0 end
    end

    local reachFrac = (c.reach or 100) / 100
    if reachFrac < 0.1 then reachFrac = 0.1 end
    local yawTarget = rad(c.angle) * clampUnit(steer / reachFrac)
    if c.invert then yawTarget = -yawTarget end
    if c.speedFade then
      local spd = (data.vel and data.vel:length()) or 0
      yawTarget = yawTarget * clamp01(spd / (c.fadeSpeed > 0.1 and c.fadeSpeed or 0.1))
    end
    self.steerYaw = self.steerYaw + (yawTarget - self.steerYaw) * clamp01(dt * c.stiffness)

    qtmp:setFromEuler(0, 0, self.steerYaw)
    data.res.rot:setMul2(qtmp, data.res.rot)
  end

  return o
end
