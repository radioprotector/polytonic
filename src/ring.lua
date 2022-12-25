import 'CoreLibs/object'
import 'CoreLibs/timer'

import 'glue'
local C <const> = require 'constants'

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

  -- printTable(self)
end

function Ring:addVelocity(change_deg)
  -- Convert change radians to change degrees and make it more difficult as the layer moves outward
  local change_rad = math.rad(change_deg) / self.inertia

  self.angle_velocity = self.angle_velocity + change_rad

  -- Clamp the velocity
  self.angle_velocity = math.clamp(self.angle_velocity, -C.VELOCITY_MAX, C.VELOCITY_MAX)
end

function Ring:update()
  -- Don't bother if this isn't moving
  if self.angle_velocity == 0 then
    return
  end

  local refreshRate <const> = playdate.display.getRefreshRate()

  -- Update the angular position based on the velocity, normalized by the number of frames
  self.angle_rad = self.angle_rad + (self.angle_velocity / refreshRate)

  if self.angle_rad > C.TWO_PI then
    self.angle_rad = self.angle_rad - C.TWO_PI
  end

  -- Dampen the velocity towards zero
  self.angle_velocity = self.angle_velocity - (self.angle_velocity / (self.inertia * refreshRate * C.VELOCITY_DECAY_SECONDS))

  if math.abs(self.angle_velocity) < C.VELOCITY_MIN then
    self.angle_velocity = 0
  end
end
