local gfx <const> = playdate.graphics

local function loadGame()
  math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random
end

local function updateGame()
end

local function drawGame()
  gfx.clear()
end

loadGame()

function playdate.update()
  updateGame()
  drawGame()
  playdate.drawFPS(0, 0)
end
