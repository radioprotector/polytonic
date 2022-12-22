import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
import 'CoreLibs/ui'
import 'CoreLibs/timer'

import 'ring'
import 'sprite_component'

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer

local RING_COUNT <const> = 8
local RINGS <const> = {}
local RING_SPRITES <const> = {}

local selected_ring = 1
local upDirectionKeyTimer = nil
local downDirectionKeyTimer = nil

local function loadGame()
  math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

  -- Generate rings and sprite components for each ring
  for i = 1, RING_COUNT do
    RINGS[i] = Ring(i)
    RING_SPRITES[i] = SpriteComponent(RINGS[i])
  end

  -- Mark the first ring as selected
  RINGS[selected_ring].selected = true

  -- Add a crank indicator
  playdate.ui.crankIndicator:start()
  playdate.setCrankSoundsDisabled(true)
end

local function changeSelectedRing(new_ring)
  if new_ring < 1 or new_ring > RING_COUNT then
    return
  end

  RINGS[selected_ring].selected = false
  RINGS[new_ring].selected = true
  selected_ring = new_ring
end

function playdate.upButtonDown()
  local function upButtonTimerCallback()
    changeSelectedRing(selected_ring + 1)
  end

  upDirectionKeyTimer = timer.keyRepeatTimer(upButtonTimerCallback)
end

function playdate.upButtonUp()
  upDirectionKeyTimer:remove()
end

function playdate.downButtonDown()
  local function downButtonTimerCallback()
    changeSelectedRing(selected_ring - 1)
  end

  downDirectionKeyTimer = timer.keyRepeatTimer(downButtonTimerCallback)
end

function playdate.downButtonUp()
  downDirectionKeyTimer:remove()
end

local function updateGame()
  -- See if the crank will accelerate or decelerate
  local change, acceleratedChange = playdate.getCrankChange()

  if change ~= 0 then
    RINGS[selected_ring]:addVelocity(acceleratedChange)
  end

  -- Update each ring
  for _, value in pairs(RINGS) do
    value:update()
  end

  -- Update the sprite components associated with the rings
  for _, value in pairs(RING_SPRITES) do
    value:update()
  end
end

local function drawGame()
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()

  if playdate.isCrankDocked() then
    playdate.ui.crankIndicator:update()
  end
end

loadGame()

function playdate.update()
  updateGame()
  drawGame()

  gfx.sprite.update()
  timer.updateTimers()
end
