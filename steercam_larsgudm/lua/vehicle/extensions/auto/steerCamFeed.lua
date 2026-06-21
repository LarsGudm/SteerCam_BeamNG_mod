-- SteerCam :: vehicle-side feed
-- ----------------------------------------------------------------------------
-- The camera runs in the Game-Engine (GE) Lua VM, but the steering value and
-- the gear live here in the vehicle VM. This reads the normalized steering input
-- (-1 .. 1) and the current gear, and forwards both to GE, where the SteerCam
-- camera turns steering into an ETS2-style "look into the corner" yaw and uses
-- the gear to decide reverse intent at a standstill.
--
-- Lives in lua/vehicle/extensions/auto/ so it auto-loads on every vehicle.
-- ----------------------------------------------------------------------------

local M = {}

local lastSent = -999
local lastGear = -999
local lastVibe = -999
local prevIgn = 0        -- last ignition level, to catch the switch-off edge
local prevRpm = 0        -- last rpm, so we only shudder if the engine had revs
local crankT = 0         -- seconds spent cranking, for the start ignition delay
local shutoffT = 0       -- seconds left in the shut-down shudder window
local minDelta = 0.0025  -- only forward when the wheel actually moved a little

local function updateGFX(dt)
  local id = objectId or 0
  -- steering: forward the raw, assist-free input, throttled to actual movement.
  -- Per-vehicle table in GE so traffic cars don't clobber each other's values.
  local s = electrics.values.steering_input or 0  -- -1..1
  if math.abs(s - lastSent) >= minDelta then
    lastSent = s
    obj:queueGameEngineLua(string.format(
      "if not steerCamFeed then steerCamFeed={} end; steerCamFeed[%d]=%.4f", id, s))
  end
  -- gear direction for the reverse-turn intent: -1 reverse / 0 neutral|park /
  -- +1 forward. gearIndex is the game's canonical numeric gear (negative=reverse,
  -- 0=neutral/park, positive=forward). Sent only on change (shifts are rare).
  local gi = electrics.values.gearIndex or 0
  local dir = (gi < 0) and -1 or ((gi > 0) and 1 or 0)
  if dir ~= lastGear then
    lastGear = dir
    obj:queueGameEngineLua(string.format(
      "if not steerCamGear then steerCamGear={} end; steerCamGear[%d]=%d", id, dir))
  end
  -- engine vibration STATE for GE (which owns the amplitude): 1 = starting rumble
  -- (while cranking, but only AFTER a short ignition delay -- the starter turns first,
  -- THEN the engine fires and rumbles; it still ends when the crank does), 2 = the
  -- gentler shudder as the engine is switched off with revs up, 0 = none. Sent only on
  -- change. EVs / already-running spawns never crank, so they don't buzz.
  local ign = electrics.values.ignitionLevel or 0
  local rpm = electrics.values.rpm or 0
  crankT = (ign == 3) and (crankT + dt) or 0                              -- time spent cranking
  if prevIgn >= 2 and ign < 2 and prevRpm > 100 then shutoffT = 0.3 end   -- engine killed (short shudder)
  if shutoffT > 0 then shutoffT = math.max(0, shutoffT - dt) end
  prevIgn, prevRpm = ign, rpm
  local vibeState = 0
  if ign == 3 and crankT >= 0.2 then vibeState = 1   -- start rumble (after the ignition delay)
  elseif shutoffT > 0 then vibeState = 2 end         -- shut-down shudder
  if vibeState ~= lastVibe then
    lastVibe = vibeState
    obj:queueGameEngineLua(string.format(
      "if not steerCamVibe then steerCamVibe={} end; steerCamVibe[%d]=%d", id, vibeState))
  end
end

M.updateGFX = updateGFX
return M
