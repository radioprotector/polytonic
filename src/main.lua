import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/timer'

import 'glue'
import 'ring'
import 'sprite_component'
import 'sound_component'
import 'ui_component'
local C <const> = require 'constants'

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer

local RINGS <const> = {}
local RING_SPRITES <const> = {}
local RING_SOUNDS <const> = {}
local UI_COMPONENT = nil

local selected_ring = 1
local allow_ring_snapback = false
local up_key_timer = nil
local down_key_timer = nil
local left_key_timer = nil
local right_key_timer = nil
local a_key_timer = nil
local b_key_timer = nil

local function loadGame()
  math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

  -- Generate rings and sprite components for each ring
  for i = 1, C.RING_COUNT do
    RINGS[i] = Ring(i)
    RING_SPRITES[i] = SpriteComponent(RINGS[i])
    RING_SOUNDS[i] = SoundComponent(RINGS[i])
  end

  -- Mark the first ring as selected
  RINGS[selected_ring].selected = true

  -- Initialize the UI component
  UI_COMPONENT = UIComponent(RINGS)
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

function playdate.leftButtonDown()
  local function leftButtonTimerCallback()
    -- Because radians go counter-clockwise, use a positive value to go "backward"
    pushSelectedRing(C.VELOCITY_PUSH_SINGLE_DEG)
  end

  left_key_timer = timer.keyRepeatTimer(leftButtonTimerCallback)
end

function playdate.leftButtonUp()
  left_key_timer:remove()
end

function playdate.rightButtonDown()
  local function rightButtonTimerCallback()
    -- Because radians go counter-clockwise, use a negative value to go "forward"
    pushSelectedRing(-C.VELOCITY_PUSH_SINGLE_DEG)
  end

  right_key_timer = timer.keyRepeatTimer(rightButtonTimerCallback)
end

function playdate.rightButtonUp()
  right_key_timer:remove()
end

function playdate.BButtonDown()
  local function BButtonTimerCallback()
    -- Because radians go counter-clockwise, use a positive value to go "backward"
    pushAllRings(C.VELOCITY_PUSH_GLOBAL_DEG)
  end

  b_key_timer = timer.keyRepeatTimer(BButtonTimerCallback)
end

function playdate.BButtonUp()
  b_key_timer:remove()
end

function playdate.AButtonDown()
  local function AButtonTimerCallback()
    -- Because radians go counter-clockwise, use a negative value to go "forward"
    pushAllRings(-C.VELOCITY_PUSH_GLOBAL_DEG)
  end

  a_key_timer = timer.keyRepeatTimer(AButtonTimerCallback)
end

function playdate.AButtonUp()
  a_key_timer:remove()
end

function playdate.gameWillPause()
  -- Generate a screenshot and and offset it by 1/4, which means we should show the center of the screen
  playdate.setMenuImage(gfx.getDisplayImage(), C.CENTER_X / 2)
end

local function updateGame()
  -- See if the crank will accelerate or decelerate
  local change = playdate.getCrankChange()

  if change ~= 0 and RINGS[selected_ring] then
    -- Invert the change to turn counter-clockwise radians to clockwise motion
    pushSelectedRing(-change)
  end

  -- Update each ring
  for _, value in pairs(RINGS) do
    value:update()
  end

  -- Update the sprite components associated with the rings
  for _, value in pairs(RING_SPRITES) do
    value:update()
  end

  -- Update the sound components associated with the rings
  for _, value in pairs(RING_SOUNDS) do
    value:update()
  end

  -- Update the UI component
  UI_COMPONENT:update()
end

local function drawGame()
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()

  -- Update all other sprites
  gfx.sprite.update()

  -- Render the UI component
  UI_COMPONENT:draw()
end

loadGame()

function playdate.update()
  updateGame()
  drawGame()

  timer.updateTimers()
end
