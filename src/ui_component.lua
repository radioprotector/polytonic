import 'CoreLibs/object'
import 'CoreLibs/graphics'

import 'glue'
import 'app_state'
local C <const> = require 'constants'
local gfx <const> = playdate.graphics

local HELP_TEXT = [[■⬆️   ⬇️▪
←⬅️ □ ➡️→
⇚Ⓑ ▣ Ⓐ⇛]]

local FONT_PATH <const> = 'assets/Asheville-Sans-14-Bold-Polytone'
local TEXT_PADDING <const> = 2

class('UIComponent').extends()

function UIComponent:init(rings_table)
  UIComponent.super.init(self)
  self.rings_table = rings_table
  self.show_help = true
  self.help_font = gfx.font.new(FONT_PATH)

  gfx.setFont(self.help_font)
  local text_width, text_height = gfx.getTextSize(HELP_TEXT)
  text_width = math.ceil(text_width + (2 * TEXT_PADDING))
  text_height = math.ceil(text_height + (3 * TEXT_PADDING))

  self.start_x = C.SCREEN_WIDTH - text_width
  self.start_y = 0

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
  -- Draw the image if enabled
  if POLYTONE_STATE.show_help then
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    self.help_image:draw(self.start_x, self.start_y)
  end
end
