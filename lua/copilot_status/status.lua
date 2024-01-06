local config = require "copilot_status.config"

---@alias copilot_status.state "loading" | "idle" | "error" | "offline" | "warning"

---@class copilot_status.status
---@field status copilot_status.state
---@field message string|nil
---@field client any
local Status = {}

function Status:check_status()
  local cp_client_ok, cp_client = pcall(require, "copilot.client")
  if not cp_client_ok then
    self.status = "offline"
    return
  end

  local cp_api = require "copilot.api"

  if not self.client then
    local client = cp_client.get()
    if not client then
      self.status = "offline"
      return
    end
    self.client = client
  end
  cp_api.check_status(self.client, {}, function(cserr, status)
    if cserr then
      self.status = "error"
      self.message = cserr
      return
    end

    if not status.user then
      self.status = "error"
      self.message = "Not authenticated. Run ':Copilot auth'"
      return
    elseif status.status == "NoTelemetryConsent" then
      self.status = "error"
      self.message = "Telemetry terms not accepted"
      return
    elseif status.status == "NotAuthorized" then
      self.status = "error"
      self.message = "Not authorized"
      return
    end

    local attached = cp_client.buf_is_attached(0)
    if not attached then
      self.status = "offline"
      return
    end
    self.status = "idle"
  end)
end

function Status:handle_status_notification()
  ---@param data { status: string, message: string }
  return function(data)
    data.status = string.lower(data.status)
    self.message = nil
    if data.status == "error" then
      self.message = data.message
      self.status = "error"
      return
    elseif data.status == "normal" then
      self.status = "idle"
    elseif data.status == "inprogress" then
      self.status = "loading"
    elseif data.status == "warning" then
      self.status = "warning"
    elseif data.status == "" then
      self.status = "offline"
    elseif config.config.debug then
      vim.notify("Unhandled status notification: " .. vim.inspect(data), vim.log.levels.DEBUG)
    end
  end
end

function Status:new(client)
  local o = setmetatable({}, self)
  self.__index = self
  self.buf = vim.api.nvim_get_current_buf()
  self.client = client
  self.status = "loading"
  self.message = nil
  self.handler_registered = false

  local status_cb = o:handle_status_notification()

  local cp_api_ok = pcall(require, "copilot.api")
  if not cp_api_ok then return o end

  vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertEnter", "WinEnter" }, {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      if o.client ~= nil and not o.handler_registered then
        local cp_api = require "copilot.api"
        cp_api.register_status_notification_handler(status_cb)
        o.handler_registered = true
      elseif o.client == nil then
        local cp_client_ok, cp_client = pcall(require, "copilot.client")
        if not cp_client_ok then return end
        o.client = cp_client.get()
      end
      o:check_status()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      if o.client ~= nil and o.handler_registered then
        local cp_api = require "copilot.api"
        cp_api.unregister_status_notification_handler(status_cb)
        o.handler_registered = false
      elseif o.client == nil then
        local cp_client_ok, cp_client = pcall(require, "copilot.client")
        if not cp_client_ok then return end
        o.client = cp_client.get()
      end
    end,
  })

  self:check_status()

  return o
end

return Status
