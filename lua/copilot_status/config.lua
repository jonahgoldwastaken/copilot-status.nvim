local M = {}

---@class copilot_status.config
local defaults = {
  icons = {
    idle = " ",
    error = " ",
    offline = " ",
    warning = "𥉉 ",
    loading = " ",
  },
  debug = false,
}

M.config = defaults

function M.setup(cfg) M.config = vim.tbl_deep_extend("force", defaults, cfg or {}) end

return M
