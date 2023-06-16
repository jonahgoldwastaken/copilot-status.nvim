local Status = require "copilot_status.status"
local config = require "copilot_status.config"
local util = require "copilot_status.util"

local M = {
  __has_setup_run = false,
}

---@type table<number, copilot_status.status>
local buf_status_map = {}

local function on_buf_enter(event)
  local bufnr = event.buf
  if buf_status_map[bufnr] then return end

  local client = nil
  local cp_client_ok, cp_client = pcall(require, "copilot.client")
  if cp_client_ok then client = cp_client.get() end
  local status = Status:new(client)
  buf_status_map[bufnr] = status
end

local function on_buf_leave(event)
  local bufnr = event.buf
  buf_status_map[bufnr] = nil
end

---@parm cfg copilot_status.config|nil
function M.setup(cfg)
  config.setup(cfg)

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = on_buf_enter,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    callback = on_buf_leave,
  })

  M.__has_setup_run = true
end

function M.enabled() return M.__has_setup_run end

function M.status()
  if not M.__has_setup_run then M.setup() end
  local bufnr = vim.api.nvim_get_current_buf()
  local status = buf_status_map[bufnr]
  if not status then return { status = "offline", message = nil } end
  return { status = status.status, message = status.message }
end

function M.status_string()
  if not M.__has_setup_run then M.setup() end
  local status = M.status()
  local message = status.message
  local icon = util.status_to_icon(status.status)
  if message ~= nil then return icon .. " " .. message end
  return "" .. icon
end

return M
