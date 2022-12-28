--- Contains glue code shared throughout the app.

-- https://devforum.play.date/t/how-to-get-code-using-require-to-run-on-the-playdate-without-changes/7320
local packages = {}

--- Provides require syntax compatible with the Playdate SDK.
--- @param name string The package to include.
function require(name)
  return packages[name]
end

packages.constants = import 'constants.lua'

-- Ensure commonly-used math utilities are local for performance
local math_min <const> = math.min
local math_max <const> = math.max

--- Clamps a value within a specific range.
--- @param val number The value to clamp.
--- @param low number The lower bound.
--- @param high number The upper bound.
--- @return number # The clamped value.
function math.clamp(val, low, high)
  return math_min(math_max(val, low), high)
end

--- Maps a value within one range to another range.
--- @param fromVal number The value to map.
--- @param fromLow number The lower bound of the source range.
--- @param fromHigh number The upper bound of the source range.
--- @param toLow number The lower bound of the destination range.
--- @param toHigh number The upper bound of the destination range.
--- @return number # The mapped value within the destination range.
function math.mapLinear(fromVal, fromLow, fromHigh, toLow, toHigh)
  local scaling_factor <const> = (toHigh - toLow) / (fromHigh - fromLow)
  local ranged_value <const> = math.clamp(fromVal, fromLow, fromHigh) - fromLow

  return toLow + (ranged_value * scaling_factor)
end
