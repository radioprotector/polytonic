--- The core ring entity.
--- @class Ring
--- @field layer integer The layer number of this instance.
--- @field angle_rad number The angle, in radians, of this instance.
--- @field angle_velocity number The angular velocity, in radians, of this instance.
--- @field selected boolean Whether this instance is currently selected.
--- @field addVelocity fun(self: Ring, change_deg: number) Adds velocity to this ring instance.
--- @field update fun(self: Ring) Updates this ring instance by applying and damping velocity and normalizing angular position.
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
local VELOCITY_DECAY_SECONDS <const> = C.VELOCITY_DECAY_SECONDS
--- The refresh rate to assume when calculating in velocity decay per frame.
local REFRESH_RATE <const> = 30

--- The inertia applied to any velocity modifications, keyed by ring layer.
local RING_INERTIA <const> = {
  C.PHI,
  C.PHI * 1.4,
  C.PHI * 1.8,
  C.PHI * 2.2,
  C.PHI * 2.6,
  C.PHI * 3.0,
  C.PHI * 3.4,
  C.PHI * 3.8
}

class('Ring').extends()

--- Creates a new instance of the Ring class.
--- @param layer number The layer of the ring that this instance represents.
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

--- @param change_deg number The amount of angular velocity to add, in degrees.
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
