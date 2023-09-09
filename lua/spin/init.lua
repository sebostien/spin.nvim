local config = require("spin.config")
local util = require("spin.util")
local lsp = require("spin.lsp")

local Spin = {}

---Plugin setup
---@param options SpinOptions Config table.
---
---@usage `require('spin').setup({})`
Spin.setup = function(options)
  config.setup(options)
  lsp.start_client()
end

---Check syntax in the current buffer or file if provided
---@param file_path string|nil
--
---@usage `require('spin').check()`
Spin.check = function(file_path)
  local bufnr = vim.fn.bufnr()

  file_path = file_path or vim.fn.expand("%:p")
  local checked = vim.fn.system(config.options.check_command .. " " .. file_path)

  local errors = {}

  for line in checked:gmatch("([^\n]*)\n?") do
    -- Example of error:
    --    spin: /test.pml:9, Error: undeclared variable: i saw 'operator: ='
    if line:sub(0, 5) == "spin:" then
      local line_number = line:match(":(%d+),") or ""
      local severity = vim.diagnostic.severity.ERROR
      local message = line:match(":%d+, [^:]+: ([^\n]+)") -- Match after "Error: " in example above

      table.insert(errors, {
        severity = severity,
        lnum = tonumber(line_number) or 0,
        col = 0,
        message = message,
      })
    else
      -- Try to parse as definitions
      local name, params = util.parse_spin_definition(line)
      if name and params then
        lsp.lsp_objects[name] = params
      end
    end
  end

  -- Send diagnostics
  vim.diagnostic.set(config.namespace, bufnr, errors)
end

---Generate verifier for current buffer or file if provided
---@param file_path string|nil
---@return boolean success
---
---@usage `require('spin').generate()`
Spin.generate = function(file_path)
  file_path    = file_path or vim.fn.expand("%:p")
  local result = vim.fn.system(config.options.generate_command .. " " .. file_path)

  if vim.v.shell_error ~= 0 then
    vim.notify("Error while generating verifier:\n" .. result, vim.log.levels.ERROR)
    return false
  end

  util.debug("Generated pan.c")
  if config.options.gcc_command then
    local gcc_result = vim.fn.system(config.options.gcc_command)
    if vim.v.shell_error ~= 0 then
      vim.notify("Error while compiling verifier with gcc:\n" .. gcc_result, vim.log.levels.ERROR)
      return false
    end

    util.debug("Compiled verifier with GCC")
    return true
  end
  return true
end

---Generate and run verifier for current buffer or file if provided
---@param file_path string|nil
---@return boolean success
---
---@usage `require('spin').verify()`
Spin.verify = function(file_path)
  file_path = file_path or vim.fn.expand("%:p")
  local success = Spin.generate(file_path)
  if success then
    return util.run_job("./pan") == 0
  end
  return false
end

---Follow a trail file from a failed verification of the current buffer or file if provided
---@param file_path string|nil
---@return boolean success
---
---@usage `require('spin').trail()`
Spin.trail = function(file_path)
  file_path = file_path or vim.fn.expand("%:p")

  return util.run_job(config.options.trail_command .. " " .. file_path) == 0
end

return Spin
