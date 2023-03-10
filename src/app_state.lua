--- Contains consolidated application state and functionality for saving/loading it from disk.

local datastore <const> = playdate.datastore
local FILE_NAME <const> = 'app_state'

--- The global persisted state for the application.
POLYTONIC_STATE = {
  --- Whether or not help information should be shown.
  show_help = true,
  --- Whether or not the background should be filled dynamically.
  background_fill_enabled = true,
  --- Whether or not debugging information should be rendered.
  debug = false,
  --- Whether or not actions should always be rendered to the UI
  always_show_action = true
}

--- Loads the application state from JSON.
function loadAppState()
  local file_state = datastore.read(FILE_NAME)

  if file_state then
    -- Do not read the debug or "always show action" flags from the data store.
    POLYTONIC_STATE.show_help = file_state.show_help
    POLYTONIC_STATE.background_fill_enabled = file_state.background_fill_enabled
  end
end

--- Saves the application state to JSON.
function saveAppState()
  datastore.write(POLYTONIC_STATE, FILE_NAME)
end
