import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'lib/gfxp'

import 'glue'
local C <const> = require 'constants'
local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry
local gfxp <const> = GFXP

local BASE_SPRITE_ZINDEX <const> = 1000
local RING_FILLS <const> = {
  'dot-2',
  {0xFF, 0xDD, 0xFF, 0xFF, 0xFF, 0xDD, 0xFF, 0xFF},
  'lightgray',
  'lightgray-1',
  'gray',
  'darkgray-1',
  'darkgray',
  {0x0, 0x22, 0x0, 0x0, 0x0, 0x22, 0x0, 0x0}
}

local selected_fill_index = 1
local selected_fill_frame_timer = 0
local SELECTED_FILLS_LENGTH <const> = 10
local SELECTED_FILLS_CYCLE_FRAMES <const> = 9
local SELECTED_FILLS <const> = {
  'white',
  'lightgray',
  'gray',
  'darkgray',
  'black',
  'black',
  'darkgray',
  'gray',
  'lightgray',
  'white'
}

class('SpriteComponent').extends()

function SpriteComponent:init(ring)
  SpriteComponent.super.init(self)
  self.ring = ring
  self.radius = C.POLYGON_RADII[ring.layer]

  if not self.radius then
    print("invalid ring! layer #" .. ring.layer)
    return
  end

  -- Create a polygon and an image to draw it to.
  self.polygon = geo.polygon.new(C.POLYGON_VERTICES)
  self.image = gfx.image.new(self.radius * 2, self.radius * 2)

  -- Initialize a sprite to use this image.
  -- Assign a z-index that decreases as the layer increases
  self.sprite = gfx.sprite.new(self.image)
  self.sprite:setCenter(0, 0)
  self.sprite:setZIndex(BASE_SPRITE_ZINDEX - ((self.ring.layer - 1) * 100))
  self.sprite:moveTo(C.CENTER_X - self.radius, C.CENTER_Y - self.radius)
  self.sprite:add()
end

function SpriteComponent:update()
  if not self.sprite or not self.image then
    return
  end

  local base_angle_rad <const> = self.ring.angle_rad

  for i = 1, C.POLYGON_VERTICES do
    -- Map each vertex to its coordinates on the unit circle.
    -- Ensure the y-coordinate is flipped so the vertices are ordered counter-clockwise around the unit circle.
    -- To center the vertices within the bounding box, ensure that each point is translated by the radius.
    local vertex_angle_rad = base_angle_rad + C.POLYGON_VERTEX_RADIANS[i]
    local x = math.floor((self.radius * math.cos(vertex_angle_rad)) + self.radius)
    local y = math.floor((-self.radius * math.sin(vertex_angle_rad)) + self.radius)

    self.polygon:setPointAt(i, x, y)
  end

  -- Ensure the polygon is closed
  self.polygon:close()

  -- Now render the image
  gfx.lockFocus(self.image)
    self.image:clear(gfx.kColorClear)

    -- First stroke the polygon
    if self.ring.selected then
      gfx.setLineWidth(4)
      gfx.setColor(gfx.kColorWhite)
    else
      gfx.setLineWidth(2)
      gfx.setColor(gfx.kColorBlack)
    end

    gfx.setStrokeLocation(gfx.kStrokeInside)
    gfx.drawPolygon(self.polygon)

    -- Then fill the polygon with a pattern.
    -- By default, each ring has its own fill style, but we have special handling
    -- for the currently-selected ring.
    local poly_fill = RING_FILLS[self.ring.layer]

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

      poly_fill = SELECTED_FILLS[selected_fill_index]
    end

    -- If this is a string value, interpret it as a GFXP string.
    -- Otherwise, assume it's a table
    if type(poly_fill) == "string" then
      gfxp.set(poly_fill)
    else
      gfx.setPattern(poly_fill)
    end

    gfx.fillPolygon(self.polygon)

  gfx.unlockFocus(self.image)
  self.sprite:markDirty()
end
