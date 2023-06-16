local cp_api = require "copilot.api"
local cp_client = require "copilot.client"
local config = require "copilot_status.config"

---@alias copilot_status.state "loading" | "idle" | "error" | "offline" | "warning"

---@class copilot_status.status
---@field status copilot_status.state
---@field message string|nil
---@field client any
local Status = {}

function Status:check_status()
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
    elseif config.config.debug then
      vim.notify("Unhandled status notification: " .. data.status, vim.log.levels.DEBUG)
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

  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      o:check_status()
      if o.client and not o.handler_registered then
        cp_api.register_status_notification_handler(status_cb)
        o.handler_registered = true
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      if o.client and o.handler_registered then
        cp_api.unregister_status_notification_handler(status_cb)
        o.handler_registered = false
      end
    end,
  })

  self:check_status()

  return o
end

return Status
