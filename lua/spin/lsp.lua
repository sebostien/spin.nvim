local config = require("spin.config")
local util = require("spin.util")

local M = {}

---Current objects with information extracted from spin
---@type table<string, string>
M.lsp_objects = {}

M.reset_lsp_object = function()
  M.lsp_objects = {
    ["_pid"] = "Global: process instance number",
    ["_last"] = "Global: process instance number of last executed step",
    ["_nr_pr"] = "Global: number of processes that are currently running"
  }
end

M.reset_lsp_object()

local capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
  hoverProvider = true,
})

local methods = {
  INITIALIZE = "initialize",
  HOVER = "textDocument/hover",
}

local message_id = 0

---@param method string The invoked LSP method
---@param callback fun(err: lsp.ResponseError|nil, result: any) Callback to invoke
---@param notify_reply_callback function|nil Callback to invoke as soon as a request is no longer pending
---@return boolean
---@return integer
local function request(method, _, callback, notify_reply_callback)
  util.debug("LSP request for method " .. method)

  message_id = message_id + 1

  if method == methods.INITIALIZE then
    callback(nil, { capabilities = capabilities })
  elseif method == methods.HOVER then
    -- https://github.com/neovim/neovim/blob/3afbf4745bcc9836c0bc5e383a8e46cc16ea8014/runtime/lua/vim/lsp/handlers.lua#L359C1-L381C4

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = assert(vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1])
    local word = util.extract_indentifier(line, col)

    if word and M.lsp_objects[word] then
      callback(nil, { contents = M.lsp_objects[word] })
    else
      callback(nil)
    end

    if notify_reply_callback then
      notify_reply_callback(word or "NOTHING")
    end
  end

  return true, message_id
end

local function notify(method, params)
  util.debug("LSP notify with method " .. method)
  for _, v in ipairs(params) do
    util.debug(v)
  end
end

local function cmd()
  return {
    request = request,
    notify = notify,
    is_closing = function()
      return false
    end,
    terminate = function()
      -- Nothing to do
    end
  }
end

M.start_client = function()
  util.debug("Starting client")

  vim.lsp.start({
    name = "spin",
    root_dir = vim.fn.getcwd(),
    cmd = cmd,
    filetypes = { "promela" },
    flags = { debounce_text_changes = 250 },
    on_attach = function(client, bufnr)
      util.debug("Running LSP on_attach")
      config.options.on_attach(client, bufnr)
    end,
    on_error = function(err) util.debug("Error: " .. err) end,
    capabilities = capabilities,
  })
end

return M
