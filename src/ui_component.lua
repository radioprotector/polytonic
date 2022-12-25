import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/ui'
import 'CoreLibs/sprites'

import 'glue'
local C <const> = require 'constants'
local gfx <const> = playdate.graphics
local font <const> = gfx.font
local geo <const> = playdate.geometry

local demo_hex_large = nil
local demo_hex_large_text_rect = nil
local demo_hex_small = nil
local demo_hex_small_text_rect = nil
local demo_hex_line = nil

class('UIComponent').extends()

function UIComponent:init(rings_table)
  UIComponent.super.init(self)
  self.rings_table = rings_table
  self.has_ring_velocity = false
  self.show_help = true

  -- Configure a menu item to toggle help
  local menu <const> = playdate.getSystemMenu()
  menu:addCheckmarkMenuItem('Show Help', self.show_help, function(value)
    self.show_help = value
  end)

  -- Generate hexes for display
  local DEMO_HEX_LARGE_RADIUS <const> = 12
  local DEMO_HEX_SMALL_RADIUS <const> = 6
  local DEMO_HEX_TEXT_BOX_WIDTH <const> = 20
  local DEMO_HEX_TEXT_BOX_HEIGHT <const> = 20
  local DEMO_HEX_TEXT_OFFSET_Y_LARGE <const> = 2
  local DEMO_HEX_TEXT_OFFSET_Y_SMALL <const> = C.SCREEN_HEIGHT - DEMO_HEX_TEXT_BOX_HEIGHT
  local DEMO_HEX_TEXT_OFFSET_X <const> = 2 + (DEMO_HEX_LARGE_RADIUS * 2)

  demo_hex_large = geo.polygon.new(C.POLYGON_VERTICES)
  demo_hex_small = geo.polygon.new(C.POLYGON_VERTICES)

  for i = 1, C.POLYGON_VERTICES do
    local vertex_angle_rad <const> = C.POLYGON_VERTEX_RADIANS[i]
    local x <const> = math.cos(vertex_angle_rad)
    local y <const> = math.sin(vertex_angle_rad)

    demo_hex_large:setPointAt(i, (x * DEMO_HEX_LARGE_RADIUS), (y * DEMO_HEX_LARGE_RADIUS))
    demo_hex_small:setPointAt(i, (x * DEMO_HEX_SMALL_RADIUS), (y * DEMO_HEX_SMALL_RADIUS))

    -- Ensure the last vertex closes the polygon
    if i == 1 then
      demo_hex_large:setPointAt(C.POLYGON_VERTICES + 1, (x * DEMO_HEX_LARGE_RADIUS), (y * DEMO_HEX_LARGE_RADIUS))
      demo_hex_small:setPointAt(C.POLYGON_VERTICES + 1, (x * DEMO_HEX_SMALL_RADIUS), (y * DEMO_HEX_SMALL_RADIUS))
    end
  end

  local center_x_large, center_y_large = DEMO_HEX_LARGE_RADIUS, DEMO_HEX_LARGE_RADIUS
  local center_x_small = DEMO_HEX_SMALL_RADIUS + (DEMO_HEX_LARGE_RADIUS - DEMO_HEX_SMALL_RADIUS)
  local center_y_small = C.SCREEN_HEIGHT - DEMO_HEX_LARGE_RADIUS

  demo_hex_large:close()
  demo_hex_large:translate(center_x_large, center_y_large)
  demo_hex_small:close()
  demo_hex_small:translate(center_x_small, center_y_small)

  demo_hex_line = geo.lineSegment.new(center_x_large, center_y_large, center_x_small, center_y_small)
  demo_hex_large_text_rect = geo.rect.new(DEMO_HEX_TEXT_OFFSET_X, DEMO_HEX_TEXT_OFFSET_Y_LARGE, DEMO_HEX_TEXT_BOX_WIDTH, DEMO_HEX_TEXT_BOX_HEIGHT)
  demo_hex_small_text_rect = geo.rect.new(DEMO_HEX_TEXT_OFFSET_X, DEMO_HEX_TEXT_OFFSET_Y_SMALL, DEMO_HEX_TEXT_BOX_WIDTH, DEMO_HEX_TEXT_BOX_HEIGHT)

  -- Add a crank indicator
  playdate.ui.crankIndicator:start()
  playdate.setCrankSoundsDisabled(true)
end

function UIComponent:update()
  -- Determine whether any of the pairs have velocity
  self.has_ring_velocity = false

  for _, value in pairs(self.rings_table) do
    if value.angle_velocity ~= 0 then
      self.has_ring_velocity = true
      break
    end
  end
end

function UIComponent:draw()
  gfx.setColor(gfx.kColorWhite)
  gfx.setFont(font.kVariantNormal)
  gfx.setLineWidth(2)

  -- See if we are configured to show help
  if self.show_help then
    -- Draw the line connecting the hexes, and then each hex
    gfx.drawLine(demo_hex_line)

    gfx.fillPolygon(demo_hex_large)
    gfx.fillRoundRect(demo_hex_large_text_rect, 2)
    gfx.drawTextInRect('⬆️', demo_hex_large_text_rect, nil, nil, kTextAlignment.center)

    gfx.fillPolygon(demo_hex_small)
    gfx.fillRoundRect(demo_hex_small_text_rect, 2)
    gfx.drawTextInRect('⬇️', demo_hex_small_text_rect, nil, nil, kTextAlignment.center)

    -- This needs to go after all sprites are updated
    if not self.has_ring_velocity and playdate.isCrankDocked() then
      playdate.ui.crankIndicator:update()
    end
  end

  -- Show debug information in the upper-right
  playdate.drawFPS(C.SCREEN_WIDTH - 20, 0)
end
