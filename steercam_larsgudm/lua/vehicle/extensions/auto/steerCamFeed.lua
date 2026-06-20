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
end

M.updateGFX = updateGFX
return M
