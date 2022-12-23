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
local RING_FILLS <const> = {
  'white',
  'lightgray',
  'gray-1',
  'gray-3',
  'gray-4',
  'gray',
  'darkgray-1',
  'darkgray'
}

local selected_fill_index = 1
local selected_fill_frame_timer = 0
local SELECTED_FILLS_LENGTH <const> = 6
local SELECTED_FILLS_CYCLE_FRAMES <const> = 9
local SELECTED_FILLS <const> = {
  'white',
  'hline-1',
  'hline-2',
  'hline-4',
  'hline-2',
  'hline-1'
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
      gfx.setColor(gfx.kColorXOR)
    else
      gfx.setLineWidth(2)
      gfx.setColor(gfx.kColorBlack)
    end

    gfx.setStrokeLocation(gfx.kStrokeCentered)
    gfx.drawPolygon(self.polygon)

    -- Then fill the polygon with a pattern
    if self.ring.selected then
      -- Use a rudimentary timer to cycle through special fills for the selected ring
      selected_fill_frame_timer = selected_fill_frame_timer + 1

      if selected_fill_frame_timer > SELECTED_FILLS_CYCLE_FRAMES then
        selected_fill_frame_timer = 0

        -- Increase the index of the selected fill, with wraparound
        selected_fill_index = selected_fill_index + 1

        if selected_fill_index > SELECTED_FILLS_LENGTH then
          selected_fill_index = 1
        end
      end

      gfxp.set(SELECTED_FILLS[selected_fill_index])
    else
      gfxp.set(RING_FILLS[self.ring.layer])
    end

    gfx.fillPolygon(self.polygon)

  gfx.unlockFocus(self.image)
  self.sprite:markDirty()
end
