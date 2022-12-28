--- The component for displaying UI elements.
--- @class UIComponent
--- @field rings_table table<integer, Ring> The rings in use by the application.
--- @field crank_active boolean Indicates whether or not the crank is in use.
--- @field update fun(self: UIComponent) Updates the state of relevant UI elements based on the rings' state.
--- @field draw fun(self: UIComponent) Renders UI elements to the screen as appropriate.
import 'CoreLibs/object'
import 'CoreLibs/graphics'

import 'glue'
import 'app_state'
local C <const> = require 'constants'
local gfx <const> = playdate.graphics

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

local FONT_PATH <const> = 'assets/Asheville-Sans-14-Bold-Polytonic'
local TEXT_PADDING <const> = 2
local HELP_TEXT = [[■⬆️   ⬇️▪
⏪⬅️ ▢ ➡️⏩
⏪Ⓑ ▣ Ⓐ⏩]]

class('UIComponent').extends()

--- Creates a new instance of the UIComponent class.
--- @param rings_table table<integer, Ring> The ring entities in use by the application.
function UIComponent:init(rings_table)
  UIComponent.super.init(self)
  self.rings_table = rings_table
  self.help_font = gfx.font.new(FONT_PATH)

  gfx.setFont(self.help_font)
  local text_width, text_height = gfx.getTextSize(HELP_TEXT)
  text_width = math.ceil(text_width + (2 * TEXT_PADDING))
  text_height = math.ceil(text_height + (3 * TEXT_PADDING))

  self.help_start_x = C.SCREEN_WIDTH - text_width
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
  -- Determine whether any of the rings have velocity.
  -- Also determine if any of the rings are selected.
  self.has_ring_velocity = false
  self.has_ring_selected = false

  for _, value in pairs(self.rings_table) do
    if value.angle_velocity ~= 0 then
      self.has_ring_velocity = true
    end

    if value.selected then
      self.has_ring_selected = true
    end
  end
end

function UIComponent:draw()
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
