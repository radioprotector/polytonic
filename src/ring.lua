import 'CoreLibs/object'
import 'CoreLibs/timer'

local FULL_RADIANS <const> = 2 * math.pi
local VELOCITY_MAX <const> = 4 * math.pi
local VELOCITY_MIN <const> = 0.01 * math.pi
local DECAY_SECONDS <const> = 30

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
  local change_rad = (change_deg / FULL_RADIANS) / self.inertia

  self.angle_velocity = self.angle_velocity + change_rad

  -- Clamp the velocity
  if self.angle_velocity > VELOCITY_MAX then
    self.angle_velocity = VELOCITY_MAX
  elseif self.angle_velocity < -VELOCITY_MAX then
    self.angle_velocity = -VELOCITY_MAX
  end
end

function Ring:update()
  -- Don't bother if this is already still
  if self.angle_velocity == 0 then
    return
  end

  local refreshRate <const> = playdate.display.getRefreshRate()

  -- Update the angular position based on the velocity, normalized by the number of frames
  self.angle_rad = self.angle_rad + (self.angle_velocity / refreshRate)

  if self.angle_rad > FULL_RADIANS then
    self.angle_rad = self.angle_rad - FULL_RADIANS
  end

  -- Dampen the velocity towards zero
  self.angle_velocity = self.angle_velocity - (self.angle_velocity / (self.inertia * refreshRate * DECAY_SECONDS))

  if math.abs(self.angle_velocity) < VELOCITY_MIN then
    self.angle_velocity = 0
  end
end
