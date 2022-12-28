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

-- Localize key constants
local RING_COUNT <const> = C.RING_COUNT
local VELOCITY_PUSH_SINGLE_DEG <const> = C.VELOCITY_PUSH_SINGLE_DEG
local VELOCITY_PUSH_GLOBAL_DEG <const> = C.VELOCITY_PUSH_GLOBAL_DEG
local VELOCITY_BRAKE_SINGLE_SCALING <const> = C.VELOCITY_BRAKE_SINGLE_SCALING
local VELOCITY_BRAKE_GLOBAL_SCALING <const> = C.VELOCITY_BRAKE_GLOBAL_SCALING
local CENTER_X <const> = C.CENTER_X

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

  -- Update each ring entity
  for _, value in pairs(RINGS) do
    value:update()
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
end

--- Renders all components and UI elements to screen.
local function drawGame()
  -- Draw the background of the UI component
  UI_COMPONENT:drawBackground()

  -- Ensure all rings are drawn.
  -- Go in reverse order to render the smallest last.
  for i = RING_COUNT, 1, -1 do
    RING_DISPLAY_COMPONENTS[i]:draw()
  end

  -- Render the foreground of the UI component
  UI_COMPONENT:drawForeground()
end

loadGame()

--- The main game loop
function playdate.update()
  updateGame()
  drawGame()

  timer.updateTimers()
end
