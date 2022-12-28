
local datastore <const> = playdate.datastore
local FILE_NAME <const> = 'app_state'

POLYTONE_STATE = {
  show_help = true,
  dissonance_fill_enabled = true
}

function loadAppState()
  local file_state = datastore.read(FILE_NAME)

  if file_state then
    POLYTONE_STATE.show_help = file_state.show_help
    POLYTONE_STATE.dissonance_fill_enabled = file_state.dissonance_fill_enabled
  end
end

function saveAppState()
  datastore.write(POLYTONE_STATE, FILE_NAME)
end
