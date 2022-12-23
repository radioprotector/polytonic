import 'CoreLibs/object'
import 'CoreLibs/timer'

import 'glue'
local C <const> = require 'constants'

class('Ring').extends()

function Ring:init(layer)
  Ring.super.init(self)
  self.layer = layer
  -- Ensure outermost layers have more "inertia"
  self.inertia = 1.618 ^ (layer / 1.5)
  self.angle_rad = 0
  self.angle_velocity = 0
  self.selected = false

  if self.layer % 2 == 0 then
    self.angle_rad = math.pi / 2
  end

  printTable(self)
end

function Ring:addVelocity(change_deg)
  -- Convert change radians to change degrees and make it more difficult as the layer moves outward
  local change_rad = (change_deg / C.TWO_PI) / self.inertia

  self.angle_velocity = self.angle_velocity + change_rad

  -- Clamp the velocity
  self.angle_velocity = math.min(C.VELOCITY_MAX, math.max(-C.VELOCITY_MAX, self.angle_velocity))
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
