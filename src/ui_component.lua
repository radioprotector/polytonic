--- The component for displaying UI elements.
--- @class UIComponent
--- @field rings_table table<integer, Ring> The rings in use by the application.
--- @field crank_active boolean Indicates whether or not the crank is in use.
--- @field update fun(self: UIComponent) Updates the state of relevant UI elements based on the rings' state.
--- @field drawBackground fun(self: UIComponent) Renders background UI elements to the screen as appropriate.
--- @field drawForeground fun(self: UIComponent) Renders foreground UI elements to the screen as appropriate.
import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'lib/gfxp'

import 'glue'
import 'app_state'

-- Localize key modules/functions
local C <const> = require 'constants'
local gfx <const> = playdate.graphics
local gfxp <const> = GFXP

local math_floor <const> = math.floor
local math_fmod <const> = math.fmod
local math_mapLinear <const> = math.mapLinear

-- Localize key constants
local RING_COUNT <const> = C.RING_COUNT
local SCREEN_WIDTH <const> = C.SCREEN_WIDTH
local SCREEN_HEIGHT <const> = C.SCREEN_HEIGHT
local THIRD_PI <const> = C.THIRD_PI
local SIXTH_PI <const> = C.SIXTH_PI

--- The button pattern for braking actions.
local BRAKE_BUTTON <const> = playdate.kButtonA | playdate.kButtonB

--- The button pattern for clockwise rotation of all rings.
local ALL_CLOCKWISE_BUTTON <const> = playdate.kButtonA

--- The button pattern for counter-clockwise rotation of all rings.
local ALL_COUNTERCLOCKWISE_BUTTON <const> = playdate.kButtonB

--- The button pattern for clockwise rotation of the selected ring.
local SINGLE_CLOCKWISE_BUTTON <const> = playdate.kButtonRight

--- The button pattern for counter-clockwise rotation of the selected ring.
local SINGLE_COUNTERCLOCKWISE_BUTTON <const> = playdate.kButtonLeft

--- The icon to use for actions affecting the selected ring.
local SINGLE_RING_ICON <const> = '◼'

--- The icon to use for actions affecting all rings.
local ALL_RINGS_ICON <const> = '▣'

--- The icon to use for cranking actions.
local CRANK_ICON <const> = '🎣'

--- The icon to use for counter-clockwise rotation actions.
local COUNTERCLOCKWISE_ICON <const> = '⏪'

--- The icon to use for clockwise rotation actions.
local CLOCKWISE_ICON <const> = '⏩'

--- The icon to use for braking actions.
local BRAKE_ICON <const> = '⏹'

--- The path to the custom font, including any necessary icon implementations
local FONT_PATH <const> = 'assets/Asheville-Sans-14-Bold-Polytonic'

--- The padding in pixels to apply around text.
local TEXT_PADDING <const> = 2

--- The help text that is rendered on screen.
local HELP_TEXT <const> = [[■⬆️   ⬇️▪
⏪⬅️ ▢ ➡️⏩
⏪Ⓑ ▣ Ⓐ⏩]]

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
local MAX_ALIGNMENT <const> = SIXTH_PI * RING_COUNT

class('UIComponent').extends()

--- Creates a new instance of the UIComponent class.
--- @param rings_table table<integer, Ring> The ring entities in use by the application.
function UIComponent:init(rings_table)
  UIComponent.super.init(self)
  self.rings_table = rings_table

  -- Update background-related properties
  self.total_alignment = nil
  self.total_alignment_pct = nil
  self.background_fill = nil
  self.background_fill_frames = BACKGROUND_UPDATE_FRAMES

  -- Load a font and calculate the dimensions of the help text
  self.help_font = gfx.font.new(FONT_PATH)

  gfx.setFont(self.help_font)
  local text_width, text_height = gfx.getTextSize(HELP_TEXT)
  text_width = math.ceil(text_width + (2 * TEXT_PADDING))
  text_height = math.ceil(text_height + (3 * TEXT_PADDING))

  self.help_start_x = SCREEN_WIDTH - text_width
  self.help_start_y = 0

  -- Create a pre-rendered image with help info
  self.help_image = gfx.image.new(text_width, text_height)
  gfx.lockFocus(self.help_image)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(0, 0, text_width, text_height, 2)

    gfx.setColor(gfx.kColorBlack)
    gfx.setFont(self.help_font)
    gfx.drawTextAligned(HELP_TEXT, text_width / 2, TEXT_PADDING, kTextAlignment.center, TEXT_PADDING)
  gfx.unlockFocus(self.help_image)
end

function UIComponent:update()

  -- Calculate:
  -- * Whether any of the rings have velocity
  -- * Whether any of the rings is currently selected
  -- * Overall alignment of the rings, measuring against 0/60/120/.../360 (since 60 degree rotation has no visible effect)
  self.has_ring_velocity = false
  self.has_ring_selected = false
  self.total_alignment = 0
  self.total_alignment_pct = 0

  for _, value in pairs(self.rings_table) do
    if value.angle_velocity ~= 0 then
      self.has_ring_velocity = true
    end

    if value.selected then
      self.has_ring_selected = true
    end

    -- Calculate alignment.
    -- If we're more than 30 degrees, we're actually closer to the next angle,
    -- so we want to factor in distance from the next angle instead
    local ring_alignment = math_fmod(value.angle_rad, THIRD_PI)
    if ring_alignment > SIXTH_PI then
      self.total_alignment += (THIRD_PI - ring_alignment)
    else
      self.total_alignment += ring_alignment
    end
  end

  -- Calculate the total alignment percentile
  self.total_alignment_pct = self.total_alignment / MAX_ALIGNMENT

  -- Increment the number of background fill frames
  self.background_fill_frames += 1

  -- Calculate the background fill if it is time
  if self.background_fill_frames > BACKGROUND_UPDATE_FRAMES then
    local alignment_level <const> = math_floor(math_mapLinear(self.total_alignment_pct, 0.0, 1.0, 0, ALIGNMENT_FILL_COUNT - 1)) + 1

    self.background_fill = ALIGNMENT_FILL_LEVELS[alignment_level]
    self.background_fill_frames = 0
  end
end

function UIComponent:drawBackground()
  -- Start with a background fill.
  -- If supported, use the animated background fill.
  if POLYTONIC_STATE.background_fill_enabled then
    gfxp.set(self.background_fill)
  else
    gfx.setColor(gfx.kColorBlack)
  end

  gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

function UIComponent:drawForeground()
  if POLYTONIC_STATE.show_help then
    -- Draw the help image if enabled
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    self.help_image:draw(self.help_start_x, self.help_start_y)

    -- See what action is being performed
    local action_icon, scope_icon = self:getCurrentActionIconText()

    -- If we have both a scope and action, draw an icon representing what's being performed
    if scope_icon and action_icon then
      gfx.setFont(self.help_font)
      gfx.setImageDrawMode(gfx.kDrawModeInverted)
      gfx.drawText(scope_icon .. action_icon, 0, 0)
    end
  end

  -- See if we are including debug information
  if POLYTONIC_STATE.debug then
    -- Show FPS in the lower-right
    playdate.drawFPS(SCREEN_WIDTH - 20, SCREEN_HEIGHT - 20)

    -- Show ring angles and total alignment
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    for i = RING_COUNT, 1, -1 do
      gfx.drawText(string.format('%.0f', math.deg(self.rings_table[i].angle_rad)), 0, SCREEN_HEIGHT - (20 * (i + 1)))
    end

    gfx.drawText('Align ' .. string.format('%.0f', math.deg(self.total_alignment)) ..
      ' (' .. string.format('%.0f', self.total_alignment_pct * 100) .. '%)' , 0, SCREEN_HEIGHT - 20)
  end
end

--- Returns the icon text for the action being performed and its scope.
function UIComponent:getCurrentActionIconText()
  local buttons_pressed = playdate.getButtonState()
  local scope_icon = nil
  local action_icon = nil
  gfx.setFont(self.help_font)

  -- See what action is being performed
  if (buttons_pressed & BRAKE_BUTTON) == BRAKE_BUTTON  then
    -- A + B pressed, meaning we're braking - see if we're braking one or all
    action_icon = BRAKE_ICON
    if self.has_ring_selected then
      scope_icon = SINGLE_RING_ICON
    else
      scope_icon = ALL_RINGS_ICON
    end
  elseif (buttons_pressed & ALL_CLOCKWISE_BUTTON) == ALL_CLOCKWISE_BUTTON then
    action_icon = CLOCKWISE_ICON
    scope_icon = ALL_RINGS_ICON
  elseif (buttons_pressed & ALL_COUNTERCLOCKWISE_BUTTON) == ALL_COUNTERCLOCKWISE_BUTTON then
    action_icon = COUNTERCLOCKWISE_ICON
    scope_icon = ALL_RINGS_ICON
  elseif self.has_ring_selected then
    -- Here on out there are only selected ring actions.
    scope_icon = SINGLE_RING_ICON

    -- If no buttons are pressed, also support checking whether the crank is active
    if (buttons_pressed & SINGLE_CLOCKWISE_BUTTON) == SINGLE_CLOCKWISE_BUTTON then
      action_icon = CLOCKWISE_ICON
    elseif (buttons_pressed & SINGLE_COUNTERCLOCKWISE_BUTTON) == SINGLE_COUNTERCLOCKWISE_BUTTON then
      action_icon = COUNTERCLOCKWISE_ICON
    elseif self.crank_active then
      action_icon = CRANK_ICON
    end
  end

  return action_icon, scope_icon
end
