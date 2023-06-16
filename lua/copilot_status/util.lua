local M = {}

---@param state copilot_status.state
---@return string
function M.status_to_icon(state)
  local config = require("copilot_status.config").config
  if state == "loading" then
    return config.icons.loading
  elseif state == "warning" then
    return config.icons.warning
  elseif state == "error" then
    return config.icons.error
  elseif state == "offline" then
    return config.icons.offline
  else
    return config.icons.idle
  end
end

return M
