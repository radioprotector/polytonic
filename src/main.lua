import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/ui'
import 'CoreLibs/timer'

import 'glue'
import 'ring'
import 'sprite_component'
local C <const> = require 'constants'

local gfx <const> = playdate.graphics
local font <const> = gfx.font
local geo <const> = playdate.geometry
local timer <const> = playdate.timer

local RINGS <const> = {}
local RING_SPRITES <const> = {}

local screen_height <const> = playdate.display.getHeight()
local DEMO_HEX_LARGE_RADIUS <const> = 12
local DEMO_HEX_SMALL_RADIUS <const> = 6
local DEMO_HEX_TEXT_BOX_WIDTH = 20
local DEMO_HEX_TEXT_BOX_HEIGHT = 20
local DEMO_HEX_TEXT_OFFSET_Y_LARGE = 2
local DEMO_HEX_TEXT_OFFSET_Y_SMALL = screen_height - DEMO_HEX_TEXT_BOX_HEIGHT
local DEMO_HEX_TEXT_OFFSET_X <const> = 2 + (DEMO_HEX_LARGE_RADIUS * 2)
local demo_hex_large = nil
local demo_hex_large_text_rect = nil
local demo_hex_small = nil
local demo_hex_small_text_rect = nil
local demo_hex_line = nil

local has_ring_velocity = false
local selected_ring = 1
local allow_ring_snapback = false
local up_key_timer = nil
local down_key_timer = nil

local function loadGame()
  math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

  -- Generate rings and sprite components for each ring
  for i = 1, C.RING_COUNT do
    RINGS[i] = Ring(i)
    RING_SPRITES[i] = SpriteComponent(RINGS[i])
  end

  -- Mark the first ring as selected
  RINGS[selected_ring].selected = true

  -- Generate hexes for display
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
  local center_y_small = screen_height - DEMO_HEX_LARGE_RADIUS

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

local function changeSelectedRing(new_ring)
  -- Allow us to move *one* outside the ring count for a "clean" appearance.
  -- If we try to move further, re-toggle the outermost/innermost ring, so long as we support snapping back
  if new_ring < 0 then
    if not allow_ring_snapback then
      return
    end

    new_ring = 1
  elseif new_ring > C.RING_COUNT + 1 then
    if not allow_ring_snapback then
      return
    end

    new_ring = C.RING_COUNT
  elseif new_ring == 0 or new_ring == C.RING_COUNT + 1 then
    -- Prevent snapping back until we actually let go of the key
    allow_ring_snapback = false
  end

  -- Deselect the old ring, if valid
  if RINGS[selected_ring] then
    RINGS[selected_ring].selected = false
  end

  -- Select the new ring, if valid
  if RINGS[new_ring] then
    RINGS[new_ring].selected = true
  end

  selected_ring = new_ring
end

function playdate.upButtonDown()
  local function upButtonTimerCallback()
    changeSelectedRing(selected_ring + 1)
  end

  up_key_timer = timer.keyRepeatTimer(upButtonTimerCallback)
end

function playdate.upButtonUp()
  up_key_timer:remove()

  -- Allow snapping back now that we've let go of the key
  allow_ring_snapback = true
end

function playdate.downButtonDown()
  local function downButtonTimerCallback()
    changeSelectedRing(selected_ring - 1)
  end

  down_key_timer = timer.keyRepeatTimer(downButtonTimerCallback)
end

function playdate.downButtonUp()
  down_key_timer:remove()

  -- Allow snapping back now that we've let go of the key
  allow_ring_snapback = true
end

local function updateGame()
  -- See if the crank will accelerate or decelerate
  local change, acceleratedChange = playdate.getCrankChange()

  if change ~= 0 and RINGS[selected_ring] then
    -- Invert the change to turn counter-clockwise radians to clockwise motion
    RINGS[selected_ring]:addVelocity(-acceleratedChange)
  end

  -- Update each ring
  has_ring_velocity = false

  for _, value in pairs(RINGS) do
    value:update()

    if value.angle_velocity ~= 0 then
      has_ring_velocity = true
    end
  end

  -- Update the sprite components associated with the rings
  for _, value in pairs(RING_SPRITES) do
    value:update()
  end
end

local function drawGame()
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.setColor(gfx.kColorWhite)
  gfx.setFont(font.kVariantNormal)
  gfx.setLineWidth(2)
  gfx.clear()

  -- Update all other sprites
  gfx.sprite.update()

  -- Draw guidance
  gfx.drawLine(demo_hex_line)

  gfx.fillPolygon(demo_hex_large)
  gfx.fillRoundRect(demo_hex_large_text_rect, 2)
  gfx.drawTextInRect('⬆️', demo_hex_large_text_rect, nil, nil, kTextAlignment.center)

  gfx.fillPolygon(demo_hex_small)
  gfx.fillRoundRect(demo_hex_small_text_rect, 2)
  gfx.drawTextInRect('⬇️', demo_hex_small_text_rect, nil, nil, kTextAlignment.center)

  -- This needs to go after all sprites are updated
  if not has_ring_velocity and playdate.isCrankDocked() then
    playdate.ui.crankIndicator:update()
  end
end

loadGame()

function playdate.update()
  updateGame()
  drawGame()

  timer.updateTimers()
end
