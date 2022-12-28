--- The component for visually displaying each ring.
--- @class RingDisplayComponent
--- @field ring Ring The ring represented by this instance.
--- @field update fun(self: RingDisplayComponent) Updates this instance's polygon based on the current state of its associated ring.
--- @field draw fun(self: RingDisplayComponent) Renders this instance's polygon to the screen.
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'lib/gfxp'

import 'glue'
local C <const> = require 'constants'
local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry
local gfxp <const> = GFXP

-- Ensure commonly-used math utilities are local for performance
local math_sin <const> = math.sin
local math_cos <const> = math.cos
local math_floor <const> = math.floor

-- Similarly localize key constants
local POLYGON_VERTEX_RADIANS <const> = C.POLYGON_VERTEX_RADIANS
local POLYGON_VERTICES <const> = C.POLYGON_VERTICES
local CENTER_X <const> = C.CENTER_X
local CENTER_Y <const> = C.CENTER_Y

--- The fills to use for each ring, keyed by ring layer.
local RING_FILLS <const> = {
  'dot-2',
  {0xFF, 0xDD, 0xFF, 0xFF, 0xFF, 0xDD, 0xFF, 0xFF},
  'lightgray',
  'lightgray-1',
  'gray',
  {0x44, 0xAA, 0x11, 0xAA, 0x44, 0xAA, 0x11, 0xAA},
  'darkgray-1',
  'darkgray'
}

--- The index of the current fill to use for the selected ring.
local selected_fill_index = 1

--- The number of frames the current selected ring fill has been in use.
local selected_fill_frame_timer = 0

--- The number of frames to stay on each selected ring fill.
local SELECTED_FILLS_CYCLE_FRAMES <const> = 9

--- The fills to cycle through for the selected ring.
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

--- The number of available selected ring fills.
---@diagnostic disable-next-line: undefined-field
local SELECTED_FILLS_LENGTH <const> = table.getsize(SELECTED_FILLS)

class('RingDisplayComponent').extends()

--- Creates a new instance of the RingDisplayComponent class.
--- @param ring Ring The ring entity represented by this instance.
function RingDisplayComponent:init(ring)
  RingDisplayComponent.super.init(self)
  self.ring = ring
  self.radius = C.POLYGON_RADII[ring.layer]

  if not self.radius then
    print("invalid ring! layer #" .. ring.layer)
    return
  end

  -- Create a polygon to track this ring
  self.polygon = geo.polygon.new(POLYGON_VERTICES)
end

function RingDisplayComponent:update()
  if not self.polygon then
    return
  end

  local base_angle_rad <const> = self.ring.angle_rad

  for i = 1, POLYGON_VERTICES do
    -- Map each vertex to its coordinates on the unit circle.
    -- Ensure the y-coordinate is flipped so the vertices are ordered counter-clockwise around the unit circle.
    -- To center the vertices within the bounding box, ensure that each point is translated by the radius.
    local vertex_angle_rad = base_angle_rad + POLYGON_VERTEX_RADIANS[i]
    local x = math_floor(self.radius * math_cos(vertex_angle_rad)) + CENTER_X
    local y = math_floor(-self.radius * math_sin(vertex_angle_rad)) + CENTER_Y

    self.polygon:setPointAt(i, x, y)
  end

  -- Ensure the polygon is closed
  self.polygon:close()
end

function RingDisplayComponent:draw()
  -- First stroke the polygon
  if self.ring.selected then
    gfx.setLineWidth(4)
    gfx.setColor(gfx.kColorWhite)
  else
    gfx.setLineWidth(2)
    gfx.setColor(gfx.kColorBlack)
  end

  gfx.setStrokeLocation(gfx.kStrokeCentered)
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

  gfxp.set(poly_fill)
  gfx.fillPolygon(self.polygon)
end
