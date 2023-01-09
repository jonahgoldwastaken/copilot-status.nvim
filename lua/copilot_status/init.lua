local M = {
	__has_setup_run = false,
}

---@param data {status: string, message: string}
local function on_status_update(data) vim.pretty_print(data) end

function M.setup()
	local cp_ok = pcall(require, "copilot")
	if not cp_ok then
		vim.notify("copilot.lua not found while running setup", vim.log.levels.ERROR)
		return
	end
	local cp_api = require "copilot.api"
	cp_api.register_status_notification_handler(on_status_update)

	M.__has_setup_run = true
end

return M
