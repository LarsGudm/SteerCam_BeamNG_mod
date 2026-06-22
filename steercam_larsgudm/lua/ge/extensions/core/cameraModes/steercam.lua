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
  steerCam.version = "1.0"   -- shown in the Settings overlay; bump on release (keep app.json in sync)

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
    camEnable = true, camFwd = 0.0, camUp = 0.0, camYaw = 0.0, camPitch = 0.0, camFov = 65.0, stableHorizon = 0.0, nearClip = 0.05,
    steerEnable = true, angle = 18.0, reach = 65.0, stiffness = 15.0,
    reverseSteer = false, reverseAngle = 9.0, reverseTime = 500.0, speedFade = false, fadeSpeed = 30.0, fadeFloor = 0.0,
    glanceEnable = true, glanceLeft = 115.0, glanceRight = 115.0, glanceBack = 0.0, glanceTime = 120.0,
    glanceOffsetLeft = 0.10, glanceOffsetRight = 0.10, glanceOffsetBack = 0.0, glanceBackRoll = 0.0,
    glanceCurve = "Exponential", glanceTransition = "Fixed time",
    speedModEnable = false, vertigo = false, vertigoFov = 12.0, vertigoDolly = 0.30,
    speedRoll = false, rollAngle = 5.0, speedRange = 160.0, rollSource = "Steering",
    vertInertia = false, vertInertiaMax = 8.0,
    engineVibe = false, vibeAmount = 0.2, vibeRotAmount = 0.15,
  }

  -- Setting metadata: numeric ranges (clamped), booleans, and string-valued keys.
  -- Shared by sanitizePreset (file loads) and steerCam.set (Custom edits).
  local ranges = {
    camFwd = {-0.5, 0.5},
    camUp = {-0.5, 0.5},
    camYaw = {-45, 45},
    camPitch = {-45, 45},
    camFov = {40, 120}, stableHorizon = {0, 100}, nearClip = {0.01, 0.2},
    angle = {0, 90}, reach = {10, 100}, stiffness = {1, 40}, fadeSpeed = {5, 150}, fadeFloor = {0, 100},
    reverseAngle = {0, 90}, reverseTime = {0, 3000},
    glanceLeft = {0, 170}, glanceRight = {0, 170}, glanceBack = {-90, 90}, glanceTime = {0, 500},
    glanceOffsetLeft = {-0.5, 0.5}, glanceOffsetRight = {-0.5, 0.5}, glanceOffsetBack = {-0.5, 0.5}, glanceBackRoll = {-15, 15},
    vertigoFov = {0, 40}, vertigoDolly = {0, 1.5}, rollAngle = {0, 20}, speedRange = {20, 400},
    vertInertiaMax = {0, 30}, vibeAmount = {0, 0.5}, vibeRotAmount = {0, 1},
  }
  local bools  = {
    speedFade = true, vertigo = true, speedRoll = true,
    camEnable = true, steerEnable = true, glanceEnable = true, speedModEnable = true,
    reverseSteer = true, vertInertia = true, engineVibe = true,
  }
  local strs = { glanceCurve = true, glanceTransition = true, rollSource = true }   -- string-valued settings

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
    local protected, fileOf = {}, {}          -- name->bool, name->source file path
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
          protected[name] = (raw.protected == true)   -- safe tag: blocks UI overwrite/delete
          fileOf[name]  = file
          order[#order + 1] = name
        end
      end
    end
    -- Default always exists (synthesized from the inline table if no file loads)
    -- and is always pinned to the top of the list. Synthesized = protected by default.
    if not presets["Default"] then
      presets["Default"] = sanitizePreset(steerCam.defaults)
      protected["Default"] = true
      order[#order + 1] = "Default"
    end
    meta["Default"] = -math.huge
    table.sort(order, function(a, b)
      local oa, ob = meta[a] or 100, meta[b] or 100
      if oa ~= ob then return oa < ob end
      return a < b
    end)
    steerCam.presets      = presets
    steerCam.presetOrder  = order
    steerCam.presetProtected = protected
    steerCam.presetFiles  = fileOf
  end
  steerCam.loadPresets()

  -- (The old editable "Custom" profile was removed: every preset is now editable via
  --  the per-preset override layer below, so a separate scratch profile is redundant.)

  -- Edit model: a selected base preset + a sparse per-preset OVERRIDE layer (your live
  -- tweaks on top of it). Every preset is editable; tweaks are kept in
  -- steerCam.overrides[name] until you Reset (discard) or Save (bake into the file).
  -- steerCam.cfg is the merged result the camera reads. Overrides persist as one blob.
  steerCam.overrides = {}
  do
    local s = getStr("steerCam_overrides", "")
    if s ~= "" then
      local raw = jsonDecode(s)
      if type(raw) == "table" then steerCam.overrides = raw end
    end
  end
  local function saveOverrides() save("steerCam_overrides", jsonEncode(steerCam.overrides)) end

  -- (re)build steerCam.cfg = the selected base preset merged with its overrides
  function steerCam.applyCfg()
    local name = steerCam.preset
    local base = steerCam.presets[name] or steerCam.presets["Default"] or steerCam.defaults
    local ov = steerCam.overrides[name]
    if not ov or next(ov) == nil then steerCam.cfg = base; return end   -- base stays read-only
    local merged = {}
    for k, v in pairs(base) do merged[k] = v end
    for k, v in pairs(ov) do merged[k] = v end
    steerCam.cfg = merged
  end

  steerCam.preset = getStr("steerCam_preset", "Default")
  if not steerCam.presets[steerCam.preset] then steerCam.preset = "Default" end   -- (covers a saved "Custom")
  steerCam.applyCfg()

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

  -- Per-vehicle "notary" toggle (global). PLACEHOLDER: persisted so the choice is
  -- remembered, but it does nothing yet -- wired up when the per-vehicle config
  -- system lands. Default off.
  steerCam.notaryEnabled = getBool("steerCam_notaryEnabled", false)
  function steerCam.setNotary(v)
    steerCam.notaryEnabled = (v == true or v == 1 or v == "true")
    save("steerCam_notaryEnabled", steerCam.notaryEnabled)
  end

  -- UI: open the presets folder in the OS file browser (so users can find, share and
  -- hand-edit their .json presets). Resolves to <userfolder>/settings/steercam/presets/.
  function steerCam.openPresetFolder()
    -- make sure it exists first (a user who hasn't saved a preset yet has no folder)
    if FS and FS.directoryCreate then FS:directoryCreate(steerCam.presetsDir) end
    if Engine and Engine.Platform and Engine.Platform.exploreFolder then
      Engine.Platform.exploreFolder(steerCam.presetsDir)
    end
  end

  -- UI: switch the active base preset. Per-preset overrides are preserved, so a preset
  -- you'd tweaked still shows its changes when you return to it.
  function steerCam.setPreset(name)
    if not steerCam.presets[name] then name = "Default" end
    steerCam.preset = name
    steerCam.applyCfg()
    save("steerCam_preset", name)
  end

  -- Re-scan the presets folder at runtime (console: steerCam.reloadPresets()).
  -- Re-resolves the active cfg so a removed/renamed preset falls back cleanly.
  function steerCam.reloadPresets()
    steerCam.loadPresets()
    steerCam.setPreset(steerCam.preset)
  end

  -- UI: save the current effective settings as a named preset (global -- available to
  -- every car). New name -> new file; existing name -> overwrite in place (the UI
  -- confirms first). Protected presets (Default/Dev's) and the reserved "Custom" name
  -- are refused. User presets are written WITHOUT a protected tag, so they stay
  -- editable (power users can add "protected": true to the JSON by hand). The display
  -- name lives in the JSON's "name" field; the filename is just a slug.
  function steerCam.savePreset(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return { ok = false, reason = "empty" } end
    if name == "Custom" then return { ok = false, reason = "reserved" } end
    if steerCam.presetProtected and steerCam.presetProtected[name] then
      return { ok = false, reason = "protected" }
    end
    local file = steerCam.presetFiles and steerCam.presetFiles[name]   -- overwrite in place
    if not file then
      local slug = name:lower():gsub("%s+", "-"):gsub("[^a-z0-9%-_]", "")
      if slug == "" then slug = "preset" end
      file = steerCam.presetsDir .. slug .. ".json"
      local n = 2                                                      -- avoid clobbering a same-slug file
      while FS and FS.fileExists and FS:fileExists(file) do
        file = steerCam.presetsDir .. slug .. "-" .. n .. ".json"; n = n + 1
      end
    end
    local cfg = steerCam.getCfg()
    cfg.preset, cfg.modified, cfg.modEnabled, cfg.mirrorSeat = nil, nil, nil, nil   -- not preset data
    cfg.name, cfg.order = name, 100
    jsonWriteFile(file, cfg, true)
    steerCam.loadPresets()
    steerCam.setPreset(name)   -- select the new preset (clean, no overrides yet)
    return { ok = true, name = name }
  end

  -- UI: delete a user preset file. Refuses protected presets and "Custom"; falls the
  -- active selection back to Default if the deleted preset was selected.
  function steerCam.deletePreset(name)
    if not name or name == "Custom" then return { ok = false, reason = "reserved" } end
    if steerCam.presetProtected and steerCam.presetProtected[name] then
      return { ok = false, reason = "protected" }
    end
    local file = steerCam.presetFiles and steerCam.presetFiles[name]
    if not file then return { ok = false, reason = "missing" } end
    if FS and FS.removeFile then FS:removeFile(file) end
    steerCam.overrides[name] = nil; saveOverrides()   -- drop any tweaks for the gone preset
    steerCam.loadPresets()
    if steerCam.preset == name then steerCam.setPreset("Default") else steerCam.applyCfg() end
    return { ok = true }
  end

  -- UI: discard the current preset's overrides (Reset -- back to the saved preset). No
  -- confirmation by design; harmless no-op on Custom (which has no base to revert to).
  function steerCam.resetOverrides()
    local name = steerCam.preset
    if steerCam.overrides[name] ~= nil then
      steerCam.overrides[name] = nil
      saveOverrides()
      steerCam.applyCfg()
    end
  end

  -- UI: bake the current preset's overrides into its own file (Save changes to this
  -- preset), then clear them. Refuses Custom and protected presets.
  function steerCam.saveChanges()
    local name = steerCam.preset
    if name == "Custom" then return { ok = false, reason = "reserved" } end
    if steerCam.presetProtected and steerCam.presetProtected[name] then return { ok = false, reason = "protected" } end
    local file = steerCam.presetFiles and steerCam.presetFiles[name]
    if not file then return { ok = false, reason = "missing" } end
    local cfg = steerCam.getCfg()
    cfg.preset, cfg.modified, cfg.modEnabled, cfg.mirrorSeat = nil, nil, nil, nil
    cfg.name, cfg.order = name, 100
    jsonWriteFile(file, cfg, true)
    steerCam.overrides[name] = nil; saveOverrides()
    steerCam.loadPresets()
    steerCam.setPreset(name)
    return { ok = true }
  end

  -- UI: edit a value. Writes the selected preset's per-preset override layer (Reset
  -- discards it, Save bakes it in), then rebuilds steerCam.cfg.
  function steerCam.set(key, value)
    if steerCam.defaults[key] == nil then return end   -- unknown key
    local v
    if bools[key] then
      v = (value == true or value == 1 or value == "true")
    elseif strs[key] then
      v = tostring(value)
    else
      v = tonumber(value)
      if v == nil then return end
      local r = ranges[key]
      if r then v = clampv(v, r[1], r[2]) end
    end
    local ov = steerCam.overrides[steerCam.preset] or {}
    ov[key] = v
    steerCam.overrides[steerCam.preset] = ov
    saveOverrides()
    steerCam.applyCfg()
  end

  -- UI: read the active profile's values + which preset is selected
  function steerCam.getCfg()
    local a = steerCam.cfg
    local ov = steerCam.overrides[steerCam.preset]
    local modified = ov ~= nil and next(ov) ~= nil
    return {
      preset = steerCam.preset,
      modified = modified or false,
      modEnabled = steerCam.enabled,
      mirrorSeat = steerCam.mirrorSeat,
      notaryEnabled = steerCam.notaryEnabled,
      version = steerCam.version,
      camEnable = a.camEnable, camFwd = a.camFwd, camUp = a.camUp,
      camYaw = a.camYaw, camPitch = a.camPitch, camFov = a.camFov, stableHorizon = a.stableHorizon, nearClip = a.nearClip,
      steerEnable = a.steerEnable,
      angle = a.angle, reach = a.reach, stiffness = a.stiffness,
      reverseSteer = a.reverseSteer, reverseAngle = a.reverseAngle, reverseTime = a.reverseTime,
      speedFade = a.speedFade, fadeSpeed = a.fadeSpeed, fadeFloor = a.fadeFloor,
      glanceEnable = a.glanceEnable,
      glanceLeft = a.glanceLeft, glanceRight = a.glanceRight, glanceBack = a.glanceBack, glanceTime = a.glanceTime,
      glanceOffsetLeft = a.glanceOffsetLeft, glanceOffsetRight = a.glanceOffsetRight, glanceOffsetBack = a.glanceOffsetBack,
      glanceBackRoll = a.glanceBackRoll,
      glanceCurve = a.glanceCurve, glanceTransition = a.glanceTransition,
      speedModEnable = a.speedModEnable,
      vertigo = a.vertigo, vertigoFov = a.vertigoFov, vertigoDolly = a.vertigoDolly,
      speedRoll = a.speedRoll, rollAngle = a.rollAngle, speedRange = a.speedRange,
      rollSource = a.rollSource, vertInertia = a.vertInertia, vertInertiaMax = a.vertInertiaMax,
      engineVibe = a.engineVibe, vibeAmount = a.vibeAmount, vibeRotAmount = a.vibeRotAmount,
    }
  end

  -- UI: the ordered preset list for the dropdown
  function steerCam.getPresetNames()
    local names = {}
    for _, n in ipairs(steerCam.presetOrder or {}) do names[#names + 1] = n end
    return names
  end

  -- UI: ordered preset list WITH protection flags so the app can show a lock and
  -- block overwrite/delete.
  function steerCam.getPresetMeta()
    local out = {}
    for _, n in ipairs(steerCam.presetOrder or {}) do
      out[#out + 1] = { name = n, protected = (steerCam.presetProtected and steerCam.presetProtected[n]) == true }
    end
    return out
  end

  -- ----- Blind-spot glance runtime ------------------------------------------
  -- Side convention: left = +1, right = -1, back = 2 (0 = none). Left/right match
  -- steer-left = positive yaw; back is ~180deg with the camera re-centred.
  -- Hold keybinds form an ORDERED STACK so simultaneous holds resolve to the most
  -- recently pressed one, and releasing it falls back to whatever is STILL held
  -- (hold left, drop a back-glance on top, release it -> back to left). Toggle and
  -- preview stay single latches (last input wins), resolved as a fallback below.
  steerCam.glanceHeld    = {}     -- set: sideNum -> true while that hold key is down
  steerCam.glanceStack   = {}     -- ordered held sides, most-recently-pressed last
  steerCam.glanceToggleSide = 0   -- latched side from the TOGGLE keybind (last wins)
  steerCam.glancePreview    = 0   -- latched side from the UI Preview buttons -- kept
                                  -- separate so using ANY keybind cancels the preview

  local function sideNum(s)
    if s == "left"  or s == 1  then return 1  end
    if s == "right" or s == -1 then return -1 end
    if s == "back"  or s == 2  then return 2  end
    return 0
  end
  local function truthy(v) return v == true or v == 1 or v == "true" end

  -- remove every occurrence of a side from the hold stack (release / de-dupe)
  local function stackRemove(s)
    local st = steerCam.glanceStack
    for i = #st, 1, -1 do if st[i] == s then table.remove(st, i) end end
  end

  -- hold bindings: glance while the key is down, return on release. Multiple holds
  -- STACK -- the most recently pressed still-held side is the active glance, so you
  -- can hold left, drop a back-glance on top, then release it to fall back to left.
  -- Using a keybind cancels any UI Preview latch so you can test the real binding.
  function steerCam.glanceHold(side, down)
    local s = sideNum(side); if s == 0 then return end
    if truthy(down) then
      steerCam.glancePreview = 0
      if not steerCam.glanceHeld[s] then                     -- ignore key-repeat re-downs
        steerCam.glanceHeld[s] = true
        stackRemove(s)
        steerCam.glanceStack[#steerCam.glanceStack + 1] = s  -- push as most-recent
      end
    else
      steerCam.glanceHeld[s] = nil
      stackRemove(s)
    end
  end

  -- resolve the active glance side: the top of the hold stack wins (last pressed),
  -- then the toggle latch, then the UI preview, else 0 (front / steer-follow).
  function steerCam.glanceTarget()
    local st = steerCam.glanceStack
    if #st > 0 then return st[#st] end
    if steerCam.glanceToggleSide ~= 0 then return steerCam.glanceToggleSide end
    return steerCam.glancePreview
  end

  -- toggle bindings: flip the latched glance for a side (also cancels the preview)
  function steerCam.glanceToggle(side)
    local s = sideNum(side); if s == 0 then return end
    steerCam.glancePreview = 0
    steerCam.glanceToggleSide = (steerCam.glanceToggleSide == s) and 0 or s
  end

  -- UI preview buttons: latch a glance for tuning. Its own state, so a keybind clears
  -- it; a preview also clears any toggle latch so they don't fight.
  function steerCam.glanceSet(side, on)
    local s = sideNum(side); if s == 0 then return end
    if truthy(on) then
      steerCam.glanceToggleSide = 0
      steerCam.glancePreview = s
    elseif steerCam.glancePreview == s then
      steerCam.glancePreview = 0
    end
  end

  -- UI: read latched/held state so the app can highlight the active side. `preview`
  -- drives the Preview buttons and drops to 0 the moment a keybind is used.
  function steerCam.getGlanceState()
    local st = steerCam.glanceStack
    local hold = (#st > 0) and st[#st] or 0   -- top of the stack = the live held side
    return { hold = hold, toggle = steerCam.glanceToggleSide, preview = steerCam.glancePreview }
  end
end

local makeStockDriver = require('core/cameraModes/driver')

local qtmp = quat()
local gFwd, gUp, gRight = vec3(), vec3(), vec3()  -- scratch for the glance lean
local vecY = vec3(0, 1, 0)                         -- camera-local forward axis
local vecZup = vec3(0, 0, 1)                       -- world up axis
local rad = math.rad
local sin = math.sin
local function clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end
local function clampUnit(x) return x < -1 and -1 or (x > 1 and 1 or x) end

-- Engine-vibration noise: three decorrelated -1..1 values from a phase `t` (seconds),
-- two sines per axis at different rates so the shake is lively, non-repeating and
-- frame-rate independent. Shared by the positional buzz and the rotational wobble
-- (call with a phase offset to decorrelate the two). VIBE_FREQ is the one knob for
-- the overall pitch of the buzz -- lower = slower/coarser; tune it here, no slider.
local VIBE_FREQ = 7.0
local function vibeNoise(t)
  t = t * VIBE_FREQ
  return 0.6 * sin(t * 1.10) + 0.4 * sin(t * 1.60),
         0.6 * sin(t * 1.30) + 0.4 * sin(t * 1.50),
         0.6 * sin(t * 1.20) + 0.4 * sin(t * 1.40)
end

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
  -- Glance pose blend: the camera interpolates a (yaw, lateral, roll) pose between
  -- the FRONT target (the steer-follow aim) and the three glance targets. When the
  -- active target changes we snapshot the current pose as the tween's source, so the
  -- motion always continues from wherever the camera is -- no snapping on rapid
  -- side-swaps or when changing your mind mid-transition.
  o.glanceSide = 0   -- active target side (0 front, 1 left, -1 right, 2 back)
  o.glanceProg = 1   -- 0..1 tween progress from the snapshot toward the target
  o.poseYaw = 0; o.poseLat = 0; o.poseRoll = 0              -- current interpolated pose
  o.poseFromYaw = 0; o.poseFromLat = 0; o.poseFromRoll = 0  -- snapshot at tween start
  o.rollCur   = 0   -- current smoothed speed-roll (rad)
  o.spdSmooth = 0   -- low-passed speed, so scrub/surge doesn't jitter the effects
  -- Inertia (g-force) feel: velocity is differentiated each frame into the felt
  -- lateral push (inertia head-roll) and vertical push (head-lift), low-passed.
  o.prevVel = vec3(); o.velInit = false   -- last velocity + first-frame guard
  o.latAccLP = 0; o.vertAccLP = 0         -- low-passed lateral / vertical accel (m/s^2)
  o.vertOff = 0                           -- current head-lift offset (m, + = up off seat)
  o.vibePhase = 0; o.vibeEnv = 0          -- engine-vibration time accumulator + envelope
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
      -- near clip: the engine defaults this to ~0.1m before our update; pulling it
      -- closer stops nearby geometry (e.g. the roof at high FOV) poking through. Too
      -- low costs depth precision (distant z-fighting), hence the modest floor.
      if c.nearClip and data.res.nearClip ~= nil then data.res.nearClip = c.nearClip end
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

    -- Blind-spot glance: the camera blends a (yaw, lateral, roll) pose between the
    -- FRONT target (the steer-follow aim) and the three glance targets. The active
    -- target is resolved in steerCam.glanceTarget() -- the last still-held HOLD key,
    -- else the toggle latch, else the UI preview. When that target changes we
    -- snapshot the CURRENT pose and tween from there to the new one over glanceTime,
    -- so rapid side-swaps (and changing your mind mid-transition) flow continuously
    -- from wherever the camera is, instead of snapping. Category disabled -> front.
    local targetSide = c.glanceEnable and steerCam.glanceTarget() or 0
    local tgtYaw, tgtLat, tgtRoll
    if targetSide == 0 then
      tgtYaw, tgtLat, tgtRoll = self.steerYaw, 0, 0          -- front = steer-follow aim
    elseif targetSide == 2 then
      -- BACK: turn ~180deg from the SAME seat position as the other glances (just a
      -- big yaw + the back offset, no re-centring). Direction mirrors with the seat
      -- (LHD looks back over the right shoulder = +, RHD over the left).
      local d = mirrored and -1 or 1
      tgtYaw  = d * rad(180 + (c.glanceBack or 0))   -- 0 = straight back; +-90 biases the shoulder
      tgtLat  = d * (c.glanceOffsetBack or 0)
      tgtRoll = d * (c.glanceBackRoll or 0)          -- head-tilt over the shoulder
    else
      -- side: left = +1, right = -1. The DIRECTION always follows the input (left
      -- input looks/leans left = negative), but the magnitude comes from that side's
      -- settings -- swapped L<->R when mirroring a right-hand-drive seat, so e.g. the
      -- right glance keybind still looks right but uses the left settings.
      local leftInput = targetSide > 0
      local useLeft = leftInput
      if mirrored then useLeft = not useLeft end
      local gAngle  = useLeft and (c.glanceLeft or 0)       or (c.glanceRight or 0)
      local gOffset = useLeft and (c.glanceOffsetLeft or 0) or (c.glanceOffsetRight or 0)
      local dir = leftInput and -1 or 1
      tgtYaw, tgtLat, tgtRoll = dir * rad(gAngle), dir * gOffset, 0   -- only back tilts
    end

    -- (re)start the tween whenever the active target changes: freeze the current
    -- pose as the source so the new motion continues from where it is right now.
    if targetSide ~= self.glanceSide then
      self.poseFromYaw, self.poseFromLat, self.poseFromRoll = self.poseYaw, self.poseLat, self.poseRoll
      self.glanceSide = targetSide
      self.glanceProg = 0
    end
    -- transition timing. "Fixed time": glanceTime is the whole tween, any angle.
    -- "Constant speed": glanceTime is the time for a full 180deg head-turn, so this
    -- move's duration scales with its yaw distance (a 90deg glance takes half as
    -- long) -- a steady turn rate, like spinning your head. "None": snap instantly.
    local mode = c.glanceTransition or "Fixed time"
    local dur
    if mode == "None" then
      dur = 0
    elseif mode == "Constant speed" then
      local distDeg = math.abs(math.deg(tgtYaw - self.poseFromYaw))
      dur = (c.glanceTime or 100) * (distDeg / 180)
    else
      dur = c.glanceTime or 100
    end
    if dur <= 5 then
      self.glanceProg = 1
      self.poseYaw, self.poseLat, self.poseRoll = tgtYaw, tgtLat, tgtRoll
    else
      self.glanceProg = clamp01(self.glanceProg + dt * 1000 / dur)
      local e = (easeCurves[c.glanceCurve] or easeExp)(self.glanceProg)
      self.poseYaw  = self.poseFromYaw  + (tgtYaw  - self.poseFromYaw)  * e
      self.poseLat  = self.poseFromLat  + (tgtLat  - self.poseFromLat)  * e
      self.poseRoll = self.poseFromRoll + (tgtRoll - self.poseFromRoll) * e
    end

    -- poseYaw already folds the steer-follow (front target) and the active glance
    -- into one continuously-blended yaw (= steerYaw when fully front), so apply it.
    local finalYaw = self.poseYaw
    qtmp:setFromEuler(0, 0, finalYaw)
    data.res.rot:setMul2(qtmp, data.res.rot)
    -- (the glance back head-tilt is folded into the single Final ROLL block below,
    --  so it ADDS with the speed-roll instead of one overwriting the other)

    -- lean the camera sideways along the car's world right vector (forward x up).
    -- All three glances (incl. back) start from the same seat position; this is just
    -- the per-glance lateral offset, already blended into the pose (poseLat).
    local lat = self.poseLat
    if lat ~= 0 and data.veh ~= nil then
      gFwd:set(data.veh:getDirectionVector())
      gUp:set(data.veh:getDirectionVectorUp())
      gRight:setCross(gFwd, gUp)   -- standard X-right/Y-fwd/Z-up: fwd x up = right
      gRight:normalize()
      gRight:setScaled(lat)
      data.res.pos:setAdd(gRight)
    end

    -- ----- Immersive extras: FOV vertigo + corner roll + head inertia --------
    -- Vertigo and steering-roll ramp to full strength as speed approaches speedRange
    -- (shared ceiling); the inertia effects below use g-force instead of speedRange.
    -- Speed is low-passed so tyre scrub/surge can't jitter the roll or FOV.
    local spdRaw = (data.vel and data.vel:length()) or 0
    self.spdSmooth = self.spdSmooth + (spdRaw - self.spdSmooth) * clamp01(dt * 3)
    local sr = (c.speedRange or 160) / 3.6            -- km/h -> m/s ceiling
    local speedFac = clamp01(self.spdSmooth / (sr > 0.1 and sr or 0.1))
    local modsOn = c.speedModEnable

    -- Inertia g-force: differentiate the car velocity into the felt LATERAL push
    -- (inertia head-roll) and VERTICAL push (head-lift), low-passed so road buzz
    -- doesn't jitter them. Tracked every frame (regardless of which effects are on)
    -- so enabling one mid-drive starts clean. GFULL = the 1 g full-strength ref.
    local GFULL = 9.81
    local latAcc, vertAcc = 0, 0
    if data.veh ~= nil and data.vel ~= nil then
      gFwd:set(data.veh:getDirectionVector())
      gUp:set(data.veh:getDirectionVectorUp())
      gRight:setCross(gFwd, gUp); gRight:normalize()    -- car right (world)
      if self.velInit then
        latAcc  = (data.vel:dot(gRight) - self.prevVel:dot(gRight)) / dt   -- + = pushed right
        vertAcc = (data.vel.z - self.prevVel.z) / dt                       -- + = pushed up
      end
      self.prevVel:set(data.vel)
      self.velInit = true
    end
    self.latAccLP  = self.latAccLP  + (latAcc  - self.latAccLP)  * clamp01(dt * 6)
    self.vertAccLP = self.vertAccLP + (vertAcc - self.vertAccLP) * clamp01(dt * 6)

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

    -- corner roll: lean the head into the turn, up to rollAngle. "Steering" scales
    -- the steering input by speed (+1 = right, -1 = left). "Inertia" instead leans to
    -- the real lateral g-force -- already speed-aware via v^2/r, so it responds to
    -- actual cornering load (and to slides/kerbs), closer to how a real head behaves.
    -- Both keep the same sign, so rollAngle means the same thing either way.
    local rollTarget = 0
    if modsOn and c.speedRoll then
      local rollInput
      if (c.rollSource or "Steering") == "Inertia" then
        rollInput = clampUnit(self.latAccLP / GFULL)      -- full lean at ~1 g lateral
      else
        rollInput = clampUnit(steerRaw) * speedFac
      end
      rollTarget = rad(c.rollAngle or 0) * rollInput
    end
    self.rollCur = self.rollCur + (rollTarget - self.rollCur) * clamp01(dt * 6)

    -- vertical head inertia ("head lift"): the body lags the car's vertical motion --
    -- floating UP off the seat when the car drops away (cresting a rise, going light
    -- or airborne) and pressing DOWN under compression (landings, dips). Map the felt
    -- vertical g to an offset clamped to vertInertiaMax (cm -> m), then spring it so it
    -- moves like a head on a neck. Applied along the car's up axis, on top of camUp.
    local vTarget = 0
    if modsOn and c.vertInertia then
      vTarget = clampUnit(-self.vertAccLP / GFULL) * ((c.vertInertiaMax or 0) * 0.01)
    end
    self.vertOff = self.vertOff + (vTarget - self.vertOff) * clamp01(dt * 9)
    if self.vertOff ~= 0 and data.veh ~= nil then
      gUp:set(data.veh:getDirectionVectorUp())
      gUp:setScaled(self.vertOff)
      data.res.pos:setAdd(gUp)
    end

    -- engine vibration: a small, rapid positional buzz. steerCamVibe is the fed STATE
    -- per vehicle (1 = engine starting, 2 = engine stopping); the amplitude SCALE lives
    -- HERE next to the slider -- the start is full vibeAmount, the shut-down a quarter
    -- of it (gentler) -- and the envelope fades it in/out sharply. Two sines per axis at
    -- different rates give a lively, non-repeating, frame-rate-independent shake; sub-cm,
    -- so it reads as vibration without being nauseating.
    local vibeState = 0
    if modsOn and c.engineVibe and steerCamVibe ~= nil and data.veh ~= nil then
      local vid = data.veh.getID and data.veh:getID() or nil
      if vid ~= nil then vibeState = steerCamVibe[vid] or 0 end
    end
    local vibeTarget = (vibeState == 1) and 1 or (vibeState == 2 and 0.25 or 0)   -- start full, stop a quarter
    self.vibeEnv = self.vibeEnv + (vibeTarget - self.vibeEnv) * clamp01(dt * 14)
    if self.vibeEnv > 0.001 and data.veh ~= nil then
      self.vibePhase = self.vibePhase + dt
      local t = self.vibePhase * 6.2831853       -- seconds -> radians
      local amp = (c.vibeAmount or 0) * 0.01 * self.vibeEnv     -- cm -> m, enveloped
      local nx, ny, nz = vibeNoise(t)
      gFwd.x = amp * nx; gFwd.y = amp * ny; gFwd.z = amp * nz
      data.res.pos:setAdd(gFwd)
    end

    -- ----- Final camera ROLL (single, additive) ------------------------------
    -- The third rotation axis. Yaw (L/R: steer + glance) and pitch (U/D: override)
    -- are done above; ROLL is done HERE, once, so every source ADDS into one value
    -- instead of one rebuild overwriting another: speed-roll (steering lean) +
    -- glance back head-tilt. Base 0. We rebuild with OUR OWN transform (setFromDir)
    -- from a STABLE up -- the car up blended by Horizon lock (= the bank), or level
    -- if the override is off -- rolled by the total about the look axis. No stock
    -- wobble, and the bank is recomputed fresh so it stays right even glancing 180
    -- back. Add another roll source later by just adding it into totalRoll.
    local totalRoll = rad(self.poseRoll or 0)            -- glance head-tilt (blended)
    if modsOn and c.speedRoll then totalRoll = totalRoll - self.rollCur end   -- speed lean
    if data.veh ~= nil and (c.camEnable or totalRoll ~= 0) then
      gFwd:set(data.res.rot * vecY)                            -- final look (aim + yaw)
      if c.camEnable then
        gUp:set(data.veh:getDirectionVectorUp())              -- bank base = car/seat up
        local sh = (c.stableHorizon or 0) / 100
        if sh > 0 then                                        -- blend toward level by Horizon lock
          local f = 1 - sh * smootheststep(clamp01(1.42 * gUp.z))
          gUp:setScaled(f); gRight:set(vecZup); gRight:setScaled(1 - f)
          gUp:setAdd(gRight); gUp:normalize()
        end
      else
        gUp:set(vecZup)                                       -- override off: level base
      end
      if totalRoll ~= 0 then
        gUp:set(quatFromAxisAngle(gFwd, totalRoll) * gUp)     -- the single total roll, about the look axis
      end
      data.res.rot:setFromDir(gFwd, gUp)
    end

    -- rotation vibration: the same engine buzz as a tiny orientation wobble on top of
    -- everything (mega subtle, up to vibeRotAmount deg per axis). Phase-shifted noise so
    -- it isn't locked to the positional shake. Applied last, so nothing overwrites it.
    if self.vibeEnv > 0.001 and modsOn and c.engineVibe and (c.vibeRotAmount or 0) > 0 then
      local rx, ry, rz = vibeNoise(self.vibePhase * 6.2831853 + 137.0)
      local ra = rad(c.vibeRotAmount or 0) * self.vibeEnv      -- deg -> rad, enveloped
      qtmp:setFromEuler(rx * ra, ry * ra, rz * ra)
      data.res.rot:setMul2(qtmp, data.res.rot)
    end
  end

  return o
end
