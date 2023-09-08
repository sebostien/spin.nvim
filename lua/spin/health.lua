local config = require("spin.config")

local M = {}

M.check = function()
  vim.health.start("spin.nvim")

  -- Check spin executable
  if vim.fn.executable("spin") then
    local version = vim.fn.system("spin -V"):match("(Spin Version %d%.%d%.%d)")

    -- Match should include "Spin Version"
    if type(version) == "string" and version:len() > 15 then
      vim.health.ok(version)
      M.check_commands()
    else
      vim.health.warn("Could not detect spin version",
        "Try running 'spin -V' to verify that spin is installed correctly.")
    end
  else
    vim.health.error("Could not find spin executable", "Install spin: https://spinroot.com/spin/Man/README.html")
  end
end

M.check_commands = function()
  local test_file = debug.getinfo(1).source:sub(2, -20) .. "test.pml"

  local _ = vim.fn.system(config.options.check_command .. " " .. test_file)
  if vim.v.shell_error ~= 0 then
    vim.health.error("Could not run check command: '" .. config.options.check_command .. "'",
      "Verify that the provided command exits successfully.")
  else
    vim.health.ok("Successfully ran check on test file")
  end

  if config.options.gcc_command then
    if vim.fn.executable("gcc") then
      local result = vim.fn.system("gcc --version")
      local lines = vim.split(result, "\n")
      vim.health.ok(lines[1])
    else
      vim.health.error("Could not find gcc")
    end
  else
    vim.health.info("No gcc command")
  end
end

return M
