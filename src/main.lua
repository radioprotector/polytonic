import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'lib/gfxp'

import 'glue'
import 'app_state'
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
local VELOCITY_BRAKE_SINGLE_SCALING <const> = C.VELOCITY_BRAKE_SINGLE_SCALING
local VELOCITY_BRAKE_GLOBAL_SCALING <const> = C.VELOCITY_BRAKE_GLOBAL_SCALING
local SCREEN_WIDTH <const> = C.SCREEN_WIDTH
local SCREEN_HEIGHT <const> = C.SCREEN_HEIGHT
local CENTER_X <const> = C.CENTER_X
local THIRD_PI <const> = C.THIRD_PI
local SIXTH_PI <const> = C.SIXTH_PI

--- The background fills to use based on the calculated alignment level.
-- Alignment of 0 means that everything is a flat-top polygon.
-- Alignment of 100 means that everything is a pointy-top polygon.
-- Alignment of 50 means that there's no harmony.
local ALIGNMENT_FILL_LEVELS <const> = {
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

--- The number of available background fills.
---@diagnostic disable-next-line: undefined-field
local ALIGNMENT_FILL_COUNT <const> = table.getsize(ALIGNMENT_FILL_LEVELS)

--- The number of frames to wait before changing the background fill.
local BACKGROUND_UPDATE_FRAMES <const> = 15

--- The maximum amount of possible alignment between ring angles.
local MAX_ALIGNMENT = SIXTH_PI * RING_COUNT

-- ====================================
-- Game state
-- ====================================

--- The ring entities in the game.
--- @type table<integer, Ring>
local RINGS <const> = {}
--- The display components for ring entities in the game.
--- @type table<integer, RingDisplayComponent>
local RING_DISPLAY_COMPONENTS <const> = {}
--- The sound components for ring entities in the game.
--- @type table<integer, RingSoundComponent>
local RING_SOUND_COMPONENTS <const> = {}
--- The UI component in the game.
--- @type UIComponent
local UI_COMPONENT = nil

--- The layer number of the currently selected ring. Can be outside [1, RING_COUNT] to select no ring.
local selected_ring = 1

--- Indicates whether navigating with no selected ring can "snap back" to the innermost/outermost ring.
-- Used to prevent continuously toggling between no selection and an extreme if the button is held down.
local allow_ring_snapback = false

--- Debounce timer for the up key.
local up_key_timer = nil

--- Debounce timer for the down key.
local down_key_timer = nil

--- Debounce timer for the left key.
local left_key_timer = nil

--- Debounce timer for the right key.
local right_key_timer = nil

--- Debounce timer for the A button.
local a_key_timer = nil

--- Debounce timer for the B button.
local b_key_timer = nil

--- The total amount of calculated alignment.
local total_alignment = nil

--- The percentage of possible alignment.
local total_alignment_pct = nil

--- The current background fill pattern to use.
local background_fill = nil

--- The number of frames the current background fill pattern has been in use.
local background_fill_frames = BACKGROUND_UPDATE_FRAMES

--- Initializes the game state, core components and entities, and menus.
local function loadGame()
  math.randomseed(playdate.getSecondsSinceEpoch())

  -- Initialize game state
  loadAppState()

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

  -- Configure menu items to toggle background animation and help
  local menu <const> = playdate.getSystemMenu()
  menu:addCheckmarkMenuItem('Animate BG', POLYTONIC_STATE.background_fill_enabled, function(value)
    POLYTONIC_STATE.background_fill_enabled = value
  end)

  menu:addCheckmarkMenuItem('Show Help', POLYTONIC_STATE.show_help, function(value)
    POLYTONIC_STATE.show_help = value
  end)

  -- Disable crank sounds
  playdate.setCrankSoundsDisabled(true)
end

--- Adds velocity to the currently-selected ring.
--- @param change_deg number The amount of angular velocity to add, in degrees.
local function pushSelectedRing(change_deg)
  if change_deg ~= 0 and RINGS[selected_ring] then
    RINGS[selected_ring]:addVelocity(change_deg)
  end
end

--- Decelerates the currently-selected ring.
local function decelerateSelectedRing()
  if RINGS[selected_ring] then
    local braked_velocity = RINGS[selected_ring].angle_velocity * VELOCITY_BRAKE_SINGLE_SCALING
    RINGS[selected_ring].angle_velocity = braked_velocity
  end
end

--- Adds velocity to all rings.
--- @param change_deg number The amount of angular velocity to add, in degrees.
local function pushAllRings(change_deg)
  if change_deg ~= 0 then
    for _, value in pairs(RINGS) do
      value:addVelocity(change_deg)
    end
  end
end

--- Decelerates all rings.
local function decelerateAllRings()
  for _, value in pairs(RINGS) do
    local braked_velocity = value.angle_velocity * VELOCITY_BRAKE_GLOBAL_SCALING
    value.angle_velocity = braked_velocity
  end
end

--- Changes the currently-selected ring.
--- @param new_ring number The layer number of the new ring.
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
  up_key_timer = nil

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
  down_key_timer = nil

  -- Allow snapping back now that we've let go of the key
  allow_ring_snapback = true
end

function playdate.leftButtonDown()
  local function leftButtonTimerCallback()
    -- Ensure we aren't pressing A/B buttons
    if not playdate.buttonIsPressed(playdate.kButtonA) and not playdate.buttonIsPressed(playdate.kButtonB) then
      -- Because radians go counter-clockwise, use a positive value to go "backward"
      pushSelectedRing(VELOCITY_PUSH_SINGLE_DEG)
    end
  end

  left_key_timer = timer.keyRepeatTimer(leftButtonTimerCallback)
end

function playdate.leftButtonUp()
  left_key_timer:remove()
  left_key_timer = nil
end

function playdate.rightButtonDown()
  local function rightButtonTimerCallback()
    -- Ensure we aren't pressing A/B buttons
    if not playdate.buttonIsPressed(playdate.kButtonA) and not playdate.buttonIsPressed(playdate.kButtonB) then
      -- Because radians go counter-clockwise, use a negative value to go "forward"
      pushSelectedRing(-VELOCITY_PUSH_SINGLE_DEG)
    end
  end

  right_key_timer = timer.keyRepeatTimer(rightButtonTimerCallback)
end

function playdate.rightButtonUp()
  right_key_timer:remove()
  right_key_timer = nil
end

function playdate.BButtonDown()
  local function BButtonTimerCallback()

    -- Make sure we don't have the A button held as well.
    -- If so, don't try to push/pull.
    if not playdate.buttonIsPressed(playdate.kButtonA) then
      -- Because radians go counter-clockwise, use a positive value to go "backward"
      pushAllRings(VELOCITY_PUSH_GLOBAL_DEG)
    end

  end

  b_key_timer = timer.keyRepeatTimer(BButtonTimerCallback)
end

function playdate.BButtonUp()
  b_key_timer:remove()
  b_key_timer = nil
end

function playdate.AButtonDown()
  local function AButtonTimerCallback()
    -- First, see if the B button is also being held
    if playdate.buttonIsPressed(playdate.kButtonB) then

      -- Treat simultaneous A+B as a brake.
      -- See if we have a selected ring. If so, brake only that ring.
      -- Otherwise, brake all rings.
      if RINGS[selected_ring] then
        decelerateSelectedRing()
      else
        decelerateAllRings()
      end

    else
      -- Treat as a normal A push, which is global
      -- Because radians go counter-clockwise, use a negative value to go "forward"
      pushAllRings(-VELOCITY_PUSH_GLOBAL_DEG)
    end

  end

  a_key_timer = timer.keyRepeatTimer(AButtonTimerCallback)
end

function playdate.AButtonUp()
  a_key_timer:remove()
  a_key_timer = nil
end

--- Generates a menu image when the game will pause.
function playdate.gameWillPause()
  -- Generate a screenshot and and offset it by 1/4, which means we should show the center of the screen
  playdate.setMenuImage(gfx.getDisplayImage(), CENTER_X / 2)
end

--- Saves the application state when the application will close.
function playdate.gameWillTerminate()
  saveAppState()
end

--- Saves the application state when the device will sleep.
function playdate.deviceWillSleep()
  saveAppState()
end

--- Reads from the crank and updates the state of all entities and components.
local function updateGame()
  -- See if the crank will accelerate or decelerate
  local change = playdate.getCrankChange()

  if change ~= 0
    and RINGS[selected_ring]
    and not playdate.buttonIsPressed(playdate.kButtonA)
    and not playdate.buttonIsPressed(playdate.kButtonB) then

    -- Invert the change to turn counter-clockwise motion to clockwise degrees
    pushSelectedRing(-change)
    UI_COMPONENT.crank_active = true
  else
    UI_COMPONENT.crank_active = false
  end

  -- Update each ring, and calculate total alignment by measuring
  -- variance from a 0/60/120/180/240/300/360-degree position,
  -- since everything appears the same at 60-degree intervals
  total_alignment = 0
  total_alignment_pct = 0

  for _, value in pairs(RINGS) do
    value:update()

    -- Calculate alignment.
    -- If we're more than 30 degrees, we're actually closer to the next angle,
    -- so we want to factor in distance from the next angle instead
    local ring_alignment = math_fmod(value.angle_rad, THIRD_PI)
    if ring_alignment > SIXTH_PI then
      total_alignment += (THIRD_PI - ring_alignment)
    else
      total_alignment += ring_alignment
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

  -- Calculate the total alignment percentile
  total_alignment_pct = total_alignment / MAX_ALIGNMENT

  -- Increment the number of background fill frames
  background_fill_frames += 1

  -- Calculate the background fill if it is time
  if background_fill_frames > BACKGROUND_UPDATE_FRAMES then
    local alignment_level <const> = math_floor(math_mapLinear(total_alignment_pct, 0.0, 1.0, 0, ALIGNMENT_FILL_COUNT - 1)) + 1

    background_fill = ALIGNMENT_FILL_LEVELS[alignment_level]
    background_fill_frames = 0
  end
end

--- Renders all components and UI elements to screen.
local function drawGame()
  -- Start with a background fill.
  -- If supported, use the animated background fill.
  if POLYTONIC_STATE.background_fill_enabled then
    gfxp.set(background_fill)
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

  -- DEBUG: Show FPS in the lower-right
  playdate.drawFPS(C.SCREEN_WIDTH - 20, C.SCREEN_HEIGHT - 20)

  -- -- DEBUG: Ring angles and total alignment
  -- gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

  -- for i = RING_COUNT, 1, -1 do
  --   gfx.drawText(string.format('%.0f', math.deg(RINGS[i].angle_rad)), 0, SCREEN_HEIGHT - (20 * (i + 1)))
  -- end

  -- gfx.drawText('Align ' .. string.format('%.0f', math.deg(total_alignment)) ..
  --   ' (' .. string.format('%.0f', total_alignment_pct * 100) .. '%)' , 0, SCREEN_HEIGHT - 20)
end

loadGame()

--- The main game loop
function playdate.update()
  updateGame()
  drawGame()

  timer.updateTimers()
end
