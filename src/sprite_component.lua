import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'lib/gfxp'

local pd <const> = playdate
local gfx <const> = pd.graphics
local geo <const> = pd.geometry
local gfxp <const> = GFXP

local POLYGON_VERTICES <const> = 6
local THIRD_PI <const> = math.pi / 3
local VERTEX_RADIAN_OFFSETS <const> = {0, THIRD_PI, 2 * THIRD_PI, math.pi, 4 * THIRD_PI, 5 * THIRD_PI, 0}

local CENTER_X <const> = 200
local CENTER_Y <const> = 120

local BASE_SPRITE_ZINDEX <const> = 1000
local SPRITE_RADII <const> = {16, 32, 48, 64, 80, 96, 112, 128}
local SIMPLE_SPRITE_FILLS <const> = {
  'lightgray',
  'lightgray-1',
  'gray-1',
  'gray-3',
  'gray-4',
  'gray-5',
  'darkgray',
  'darkgray-1'
}
local OLD_SPRITE_FILLS <const> = {
  {
    'noise-2',
    'noise-1',
    'noise-3'
  },
  {
    'lightgray',
    'lightgray-1',
    'lightgray-2'
  },
  {
    'vline-1',
    'vline-2',
    'vline-3'
  },
  {
    'gray-3',
    'gray-4',
    'gray-5'
  },
  {
    'hline-1',
    'hline-2',
    'hline-3'
  },
  {
    'darkgray',
    'darkgray-1',
    'darkgray-2'
  },
  {
    'dline-4',
    'dline-1',
    'dline-7'
  },
  {
    'dot-1',
    'dot-2',
    'dot-3'
  }
}

class('SpriteComponent').extends()

function SpriteComponent:init(ring)
  SpriteComponent.super.init(self)
  self.ring = ring
  self.radius = SPRITE_RADII[ring.layer]

  if not self.radius then
    print("invalid ring! layer #" .. ring.layer)
    return
  end

  -- Create a polygon and an image to draw it to.
  -- Add an extra vertex to close the polygon.
  self.polygon = geo.polygon.new(POLYGON_VERTICES + 1)
  self.image = gfx.image.new(self.radius * 2, self.radius * 2)

  -- Initialize a sprite to use this image.
  -- Assign a z-index that decreases as the layer increases
  self.sprite = gfx.sprite.new(self.image)
  self.sprite:setCenter(0, 0)
  self.sprite:setZIndex(BASE_SPRITE_ZINDEX - ((self.ring.layer - 1) * 100))
  self.sprite:moveTo(CENTER_X - self.radius, CENTER_Y - self.radius)
  self.sprite:add()
end

function SpriteComponent:update()
  if not self.sprite or not self.image then
    return
  end

  local base_angle_rad <const> = self.ring.angle_rad

  for i = 1, POLYGON_VERTICES do
    -- Map each vertex to its coordinates on the unit circle.
    -- Ensure the y-coordinate is flipped so the vertices are ordered counter-clockwise around the unit circle.
    -- To center the vertices within the bounding box, ensure that each point is translated by the radius.
    local vertex_angle_rad = base_angle_rad + VERTEX_RADIAN_OFFSETS[i]
    local x = (self.radius * math.cos(vertex_angle_rad)) + self.radius
    local y = (-self.radius * math.sin(vertex_angle_rad)) + self.radius

    self.polygon:setPointAt(i, x, y)

    -- Ensure that the start and end points coincide
    if i == 1 then
      self.polygon:setPointAt(POLYGON_VERTICES + 1, x, y)
    end
  end

  -- Ensure the polygon is closed
  self.polygon:close()

  -- Now render the image
  gfx.lockFocus(self.image)
    self.image:clear(gfx.kColorClear)

    -- First stroke the polygon
    if self.ring.selected then
      gfx.setLineWidth(4)
      gfx.setColor(gfx.kColorBlack)
    else
      gfx.setLineWidth(2)
      gfx.setColor(gfx.kColorXOR)
    end

    gfx.setStrokeLocation(gfx.kStrokeCentered)
    gfx.drawPolygon(self.polygon)

    -- Then fill the polygon with a pattern
    if self.ring.selected then
      gfxp.set('white')
    else
      gfxp.set(SIMPLE_SPRITE_FILLS[self.ring.layer])
    end

    gfx.fillPolygon(self.polygon)

  gfx.unlockFocus(self.image)
  self.sprite:markDirty()
end
