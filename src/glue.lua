-- https://devforum.play.date/t/how-to-get-code-using-require-to-run-on-the-playdate-without-changes/7320
local packages = {}

function require(name)
  return packages[name]
end

packages.constants = import 'constants.lua'
