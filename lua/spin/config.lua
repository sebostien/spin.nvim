local M = {}

M.namespace = vim.api.nvim_create_namespace("Spin")

---@class SpinOptions
local defaults = {
  ---Show debug messages
  ---@type boolean|nil
  debug = false,
  ---Run check on file save
  ---@type boolean|nil
  check_on_save = true,
  ---Run check when leaving insert mode
  ---@type boolean|nil
  check_on_insert_leave = false,
  ---Command to validate syntax
  ---Only tested with this default
  ---@type string|nil
  check_command = "spin -d",
  ---Command to generate verifier
  ---@type string|nil
  generate_command = "spin -a",
  ---Command to compile verifier
  ---@type string|nil
  gcc_command = "gcc -o pan pan.c",
  ---Executed once when spin is started for the first time.
  ---@param client number LSP client namespace
  ---@param bufnr  number The buffer number
  ---@diagnostic disable-next-line
  on_attach = function(client, bufnr) end,
}

---@type SpinOptions
M.options = {}

---Apply defaults and custom options
---@param options SpinOptions|nil
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
