-- https://devforum.play.date/t/how-to-get-code-using-require-to-run-on-the-playdate-without-changes/7320
local packages = {}

function require(name)
  return packages[name]
end

packages.constants = import 'constants.lua'

-- Ensure commonly-used math utilities are local for performance
local math_min <const> = math.min
local math_max <const> = math.max
local math_floor <const> = math.floor

function math.clamp(val, low, high)
  return math_min(math_max(val, low), high)
end

function math.mapLinear(fromVal, fromLow, fromHigh, toLow, toHigh)
  local scaling_factor <const> = (toHigh - toLow) / (fromHigh - fromLow)
  local ranged_value <const> = math.clamp(fromVal, fromLow, fromHigh) - fromLow

  return toLow + (ranged_value * scaling_factor)
end

function math.roundWithin(val, places)
  local factor <const> = 10 ^ (places or 0)
  return math_floor((val * factor) + 0.5) / factor
end
