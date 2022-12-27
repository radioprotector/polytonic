import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/ui'
import 'CoreLibs/sprites'

import 'glue'
local C <const> = require 'constants'
local gfx <const> = playdate.graphics

-- local HELP_TEXT <const> = [[⬆️/⬇️ Move Ring
-- ⬅️/➡️/🎣 Push Ring
-- Ⓑ/Ⓐ Push All]]
local HELP_TEXT = [[■⬆️   ⬇️▪
←⬅️  □  ➡️→
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

  self.help_image = gfx.image.new(text_width, text_height)
  gfx.lockFocus(self.help_image)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(0, 0, text_width, text_height, 2)

    gfx.setColor(gfx.kColorBlack)
    gfx.setFont(self.help_font)
    gfx.drawTextAligned(HELP_TEXT, text_width / 2, TEXT_PADDING, kTextAlignment.center, TEXT_PADDING)
  gfx.unlockFocus(self.help_image)

  self.help_sprite = gfx.sprite.new(self.help_image)
  self.help_sprite:setCenter(0, 0)
  self.help_sprite:setZIndex(2000)
  self.help_sprite:moveTo(C.SCREEN_WIDTH - text_width, 0)
  self.help_sprite:setVisible(self.show_help)
  self.help_sprite:add()

  -- Configure a menu item to toggle help
  local menu <const> = playdate.getSystemMenu()
  menu:addCheckmarkMenuItem('Show Help', self.show_help, function(value)
    self.show_help = value
  end)

  -- Disable crank sounds
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
  -- Cascade help visibility to the sprite
  self.help_sprite:setVisible(self.show_help)

  -- Show debug information in the lower-right
  playdate.drawFPS(C.SCREEN_WIDTH - 20, C.SCREEN_HEIGHT - 20)
end
