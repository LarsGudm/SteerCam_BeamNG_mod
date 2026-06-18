-- SteerCam :: vehicle-side feed
-- ----------------------------------------------------------------------------
-- The camera runs in the Game-Engine (GE) Lua VM, but the steering value lives
-- here in the vehicle VM. This reads the normalized steering input (-1 .. 1)
-- and forwards it to GE, where the SteerCam camera turns it into an ETS2-style
-- "look into the corner" yaw.
--
-- Lives in lua/vehicle/extensions/auto/ so it auto-loads on every vehicle.
-- ----------------------------------------------------------------------------

local M = {}

local lastSent = -999
local minDelta = 0.0025  -- only forward when the wheel actually moved a little

local function updateGFX(dt)
  local s = electrics.values.steering_input or 0  -- raw, assist-free, -1..1
  if math.abs(s - lastSent) >= minDelta then
    lastSent = s
    local id = objectId or 0
    -- write into a per-vehicle table in the GE VM so traffic cars don't clobber
    -- each other's values; the camera reads its own vehicle's entry.
    obj:queueGameEngineLua(string.format(
      "if not steerCamFeed then steerCamFeed={} end; steerCamFeed[%d]=%.4f", id, s))
  end
end

M.updateGFX = updateGFX
return M
