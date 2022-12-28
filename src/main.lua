import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'lib/gfxp'

import 'glue'
import 'ring'
import 'ring_display_component'
import 'ring_sound_component'
import 'ui_component'

-- Localize key modules/functions
local C <const> = require 'constants'
local gfx <const> = playdate.graphics
local timer <const> = playdate.timer
local gfxp <const> = GFXP

local math_floor <const> = math.floor
local math_fmod <const> = math.fmod
local math_mapLinear <const> = math.mapLinear

-- Localize key constants
local RING_COUNT <const> = C.RING_COUNT
local VELOCITY_PUSH_SINGLE_DEG <const> = C.VELOCITY_PUSH_SINGLE_DEG
local VELOCITY_PUSH_GLOBAL_DEG <const> = C.VELOCITY_PUSH_GLOBAL_DEG
local SCREEN_WIDTH <const> = C.SCREEN_WIDTH
local SCREEN_HEIGHT <const> = C.SCREEN_HEIGHT
local CENTER_X <const> = C.CENTER_X
local THIRD_PI <const> = C.THIRD_PI
local SIXTH_PI <const> = math.pi / 6

-- Dissonance of 0 means that everything is a flat-top polygon.
-- Dissonance of 100 means that everything is a pointy-top polygon.
-- Dissonance of 50 means that there's no consistent harmony.
local DISSONANCE_FILL_LEVELS <const> = {
  'gray',
  {0xAA, 0x99, 0xAA, 0x66, 0xAA, 0x99, 0xAA, 0x66},
  {0xAA, 0x22, 0xAA, 0x88, 0xAA, 0x22, 0xAA, 0x88},
  {0x22, 0x22, 0x88, 0x88, 0x22, 0x22, 0x88, 0x88},
  'darkgray',
  {0x0, 0x22, 0x0, 0x0, 0x0, 0x22, 0x0, 0x0},
  {0x0, 0x20, 0x0, 0x0, 0x0, 0x2, 0x0, 0x0},
  {0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0},
  'black',
  {0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0},
  {0x0, 0x20, 0x0, 0x0, 0x0, 0x2, 0x0, 0x0},
  {0x0, 0x22, 0x0, 0x0, 0x0, 0x22, 0x0, 0x0},
  'darkgray',
  {0x22, 0x22, 0x88, 0x88, 0x22, 0x22, 0x88, 0x88},
  {0xAA, 0x22, 0xAA, 0x88, 0xAA, 0x22, 0xAA, 0x88},
  {0xAA, 0x99, 0xAA, 0x66, 0xAA, 0x99, 0xAA, 0x66},
  'gray'
}

---@diagnostic disable-next-line: undefined-field
local DISSONANCE_FILL_COUNT <const> = table.getsize(DISSONANCE_FILL_LEVELS)
local DISSONANCE_UPDATE_FRAMES <const> = 15
local MAX_DISSONANCE = SIXTH_PI * RING_COUNT

-- ====================================
-- Game state
-- ====================================
local RINGS <const> = {}
local RING_DISPLAY_COMPONENTS <const> = {}
local RING_SOUND_COMPONENTS <const> = {}
local UI_COMPONENT = nil

local selected_ring = 1
local allow_ring_snapback = false
local up_key_timer = nil
local down_key_timer = nil
local left_key_timer = nil
local right_key_timer = nil
local a_key_timer = nil
local b_key_timer = nil
local total_dissonance = nil
local total_dissonance_percentile = nil
local dissonance_fill = nil
local dissonance_fill_frames = DISSONANCE_UPDATE_FRAMES
local dissonance_fill_enabled = true

local function loadGame()
  math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

  -- Generate ring entities and components for each ring
  for i = 1, RING_COUNT do
    RINGS[i] = Ring(i)
    RING_DISPLAY_COMPONENTS[i] = RingDisplayComponent(RINGS[i])
    RING_SOUND_COMPONENTS[i] = RingSoundComponent(RINGS[i])
  end

  -- Mark the first ring as selected
  RINGS[selected_ring].selected = true

  -- Initialize the UI component
  UI_COMPONENT = UIComponent(RINGS)

  -- Configure a menu item to toggle help
  local menu <const> = playdate.getSystemMenu()
  menu:addCheckmarkMenuItem('Plain BG', not dissonance_fill_enabled, function(value)
    dissonance_fill_enabled = not value
  end)
end

local function pushSelectedRing(change_deg)
  if change_deg ~= 0 and RINGS[selected_ring] then
    RINGS[selected_ring]:addVelocity(change_deg)
  end
end

local function pushAllRings(change_deg)
  if change_deg ~= 0 then
    for _, value in pairs(RINGS) do
      value:addVelocity(change_deg)
    end
  end
end

local function changeSelectedRing(new_ring)
  -- Allow us to move *one* outside the ring count for a "clean" appearance.
  -- If we try to move further, re-toggle the outermost/innermost ring, so long as we support snapping back
  if new_ring < 0 then
    if not allow_ring_snapback then
      return
    end

    new_ring = 1
  elseif new_ring > RING_COUNT + 1 then
    if not allow_ring_snapback then
      return
    end

    new_ring = RING_COUNT
  elseif new_ring == 0 or new_ring == RING_COUNT + 1 then
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

function playdate.leftButtonDown()
  local function leftButtonTimerCallback()
    -- Because radians go counter-clockwise, use a positive value to go "backward"
    pushSelectedRing(VELOCITY_PUSH_SINGLE_DEG)
  end

  left_key_timer = timer.keyRepeatTimer(leftButtonTimerCallback)
end

function playdate.leftButtonUp()
  left_key_timer:remove()
end

function playdate.rightButtonDown()
  local function rightButtonTimerCallback()
    -- Because radians go counter-clockwise, use a negative value to go "forward"
    pushSelectedRing(-VELOCITY_PUSH_SINGLE_DEG)
  end

  right_key_timer = timer.keyRepeatTimer(rightButtonTimerCallback)
end

function playdate.rightButtonUp()
  right_key_timer:remove()
end

function playdate.BButtonDown()
  local function BButtonTimerCallback()
    -- Because radians go counter-clockwise, use a positive value to go "backward"
    pushAllRings(VELOCITY_PUSH_GLOBAL_DEG)
  end

  b_key_timer = timer.keyRepeatTimer(BButtonTimerCallback)
end

function playdate.BButtonUp()
  b_key_timer:remove()
end

function playdate.AButtonDown()
  local function AButtonTimerCallback()
    -- Because radians go counter-clockwise, use a negative value to go "forward"
    pushAllRings(-VELOCITY_PUSH_GLOBAL_DEG)
  end

  a_key_timer = timer.keyRepeatTimer(AButtonTimerCallback)
end

function playdate.AButtonUp()
  a_key_timer:remove()
end

function playdate.gameWillPause()
  -- Generate a screenshot and and offset it by 1/4, which means we should show the center of the screen
  playdate.setMenuImage(gfx.getDisplayImage(), CENTER_X / 2)
end

local function updateGame()
  -- See if the crank will accelerate or decelerate
  local change = playdate.getCrankChange()

  if change ~= 0 and RINGS[selected_ring] then
    -- Invert the change to turn counter-clockwise radians to clockwise motion
    pushSelectedRing(-change)
  end

  -- Update each ring, and calculate total dissonance by measuring
  -- variance from a 0/60/120/180/240/300/360-degree position,
  -- since all of those appear the same
  total_dissonance = 0
  total_dissonance_percentile = 0

  for _, value in pairs(RINGS) do
    value:update()

    -- Calculate dissonance
    -- If we're more than 30 degrees, we're actually closer to the next angle
    local ring_dissonance = math_fmod(value.angle_rad, THIRD_PI)
    if ring_dissonance > SIXTH_PI then
      total_dissonance += (THIRD_PI - ring_dissonance)
    else
      total_dissonance += ring_dissonance
    end
  end

  -- Update the display components associated with the rings
  for _, value in pairs(RING_DISPLAY_COMPONENTS) do
    value:update()
  end

  -- Update the sound components associated with the rings
  for _, value in pairs(RING_SOUND_COMPONENTS) do
    value:update()
  end

  -- Update the UI component
  UI_COMPONENT:update()

  -- Calculate the total dissonance percentile
  total_dissonance_percentile = total_dissonance / MAX_DISSONANCE

  -- Increment the number of dissonance fill frames
  dissonance_fill_frames += 1

  -- Calculate the dissonance fill if we have time
  if dissonance_fill_frames > DISSONANCE_UPDATE_FRAMES then
    local dissonance_level <const> = math_floor(math_mapLinear(total_dissonance_percentile, 0.0, 1.0, 0, DISSONANCE_FILL_COUNT - 1)) + 1

    dissonance_fill = DISSONANCE_FILL_LEVELS[dissonance_level]
    dissonance_fill_frames = 0
  end
end

local function drawGame()
  -- Start with a background fill
  if dissonance_fill_enabled then
    gfxp.set(dissonance_fill)
  else
    gfx.setColor(gfx.kColorBlack)
  end

  gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

  -- Ensure all rings are drawn.
  -- Go in reverse order to render the smallest last.
  for i = RING_COUNT, 1, -1 do
    RING_DISPLAY_COMPONENTS[i]:draw()
  end

  -- Render the UI component
  UI_COMPONENT:draw()

  -- -- DEBUG TEXT
  -- gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

  -- for i = RING_COUNT, 1, -1 do
  --   gfx.drawText(string.format('%.0f', math.deg(RINGS[i].angle_rad)), 0, SCREEN_HEIGHT - (20 * (i + 1)))
  -- end

  -- gfx.drawText(string.format('%.0f', math.deg(total_dissonance)) ..
  --   ' dis (' .. string.format('%.0f', total_dissonance_percentile * 100) .. '%)' , 0, SCREEN_HEIGHT - 20)
end

loadGame()

function playdate.update()
  updateGame()
  drawGame()

  timer.updateTimers()
end
