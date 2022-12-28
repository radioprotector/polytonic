--- The core ring entity.
-- @classmod Ring
import 'CoreLibs/object'
import 'CoreLibs/timer'

import 'glue'
local C <const> = require 'constants'

-- Ensure commonly-used math utilities are local for performance
local math_rad <const> = math.rad
local math_clamp <const> = math.clamp
local math_abs <const> = math.abs

-- Similarly localize key constants
local TWO_PI <const> = C.TWO_PI
local VELOCITY_MIN <const> = C.VELOCITY_MIN
local VELOCITY_MAX <const> = C.VELOCITY_MAX
local REFRESH_RATE <const> = 30
local VELOCITY_DECAY_SECONDS <const> = C.VELOCITY_DECAY_SECONDS

--- The inertia applied to any velocity modifications
local RING_INERTIA <const> = {
  C.PHI,
  C.PHI * 1.5,
  C.PHI * 2,
  C.PHI * 2.5,
  C.PHI * 3,
  C.PHI * 3.25,
  C.PHI * 3.5,
  C.PHI * 4
}

class('Ring').extends()

function Ring:init(layer)
  Ring.super.init(self)
  self.layer = layer

  -- Ensure outermost layers have more "inertia"
  self.inertia = RING_INERTIA[self.layer]
  self.angle_rad = 0
  self.angle_velocity = 0
  self.selected = false

  if self.layer % 2 == 0 then
    self.angle_rad = C.HALF_PI
  end

  if not self.inertia then
    print("invalid ring! layer #" .. ring.layer)
    return
  end

  -- Calculate per-frame decay
  self.decay_denominator = self.inertia * REFRESH_RATE * VELOCITY_DECAY_SECONDS

  -- printTable(self)
end

--- Adds velocity to the
function Ring:addVelocity(change_deg)
  -- Convert change radians to change degrees and make it more difficult as the layer moves outward
  local change_rad = math_rad(change_deg) / self.inertia

  self.angle_velocity = self.angle_velocity + change_rad

  -- Clamp the velocity
  self.angle_velocity = math_clamp(self.angle_velocity, -VELOCITY_MAX, VELOCITY_MAX)
end

function Ring:update()
  -- Don't bother if this isn't moving
  if self.angle_velocity == 0 then
    return
  end

  -- Update the angular position based on the velocity, normalized by the number of frames
  self.angle_rad = self.angle_rad + (self.angle_velocity / REFRESH_RATE)

  -- Dampen the velocity towards zero
  self.angle_velocity = self.angle_velocity - (self.angle_velocity / self.decay_denominator)

  -- Stop extremely slow values entirely
  if math_abs(self.angle_velocity) < VELOCITY_MIN then
    self.angle_velocity = 0
  end

  -- Try to keep radians values within 0-2pi radians
  if self.angle_rad > TWO_PI then
    self.angle_rad -= TWO_PI
  elseif self.angle_rad < 0 then
    self.angle_rad += TWO_PI
  end
end
