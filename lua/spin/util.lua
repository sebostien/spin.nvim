local config = require("spin.config")
local M = {}

local IDENT_PATTERN = "[_%d%w]+"

---@param msg string
M.debug = function(msg)
  if config.options.debug then
    vim.notify(msg, vim.log.levels.WARN, { title = "Spin" })
    return
  end
end

---Extract the identifier under the cursor
---@param line string The entire line
---@param col  number Current cursor column
---@return string|nil
M.extract_indentifier = function(line, col)
  local word_start = 0
  local word_end = col - 1
  local i = 0
  for c in line:gmatch(".") do
    -- Check if valid identifier char
    if not c:match(IDENT_PATTERN) then
      if i <= col then
        word_start = i + 2
      else
        word_end = i
        break
      end
    end
    i = i + 1
  end

  if word_start > word_end then
    return nil
  else
    return line:sub(word_start, word_end)
  end
end

---Parse definition generated from "spin -d"
---@param line string
---@return string|nil name
---@return string|nil params
M.parse_spin_definition = function(line)
  if not line or #line == 0 then
    return nil, nil
  end
  -- # Example definitions:
  -- type      name   ?    scope       kind        ?
  -- -----------------------------------------------------------
  -- byte      i      0    <:init:>    <variable>  {scope _2_3_}
  -- byte      a[5]   0    <:global:>  <array>     {scope _}
  -- proctype  P      0    <:global:>  <variable>  {scope _}
  -- label     end1   17   <P>                     {scope _1_}

  local words = vim.split(line, "%s+", { trimempty = true })

  if #words >= 4 then
    local t = words[1]
    local name = words[2]
    local scope = words[4]
    local def = name:match(IDENT_PATTERN)

    -- TODO: Handle types for struct-fields
    if scope == "<:struct-field:>" then
      return nil, nil
    end

    if def then
      return def, (t .. " " .. name .. " " .. scope)
    end
  end

  return nil, nil
end

---Run a job and send stdout to temporary buffer
---@param cmd string Job to run
---@return integer exit_code
M.run_job = function(cmd)
  local prev_buf = vim.fn.bufnr()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)

  local errors = {}

  local job = vim.fn.jobstart(cmd, {
    pty = false,
    stdout_buffered = false,
    on_stdout = function(_, lines)
      vim.api.nvim_buf_set_lines(buf, -1, -1, true, lines)
    end,
    on_stderr = function(_, lines)
      for _, line in ipairs(lines) do
        if #line > 0 then
          table.insert(errors, line)
        end
      end
    end
  })
  vim.fn.chanclose(job, "stdin")

  local function close_temp_buf()
    vim.fn.jobstop(job)
    vim.api.nvim_set_current_buf(prev_buf)
    vim.api.nvim_buf_delete(buf, { unload = true })
  end

  vim.keymap.set("n", "<Esc>", close_temp_buf, { buffer = buf, noremap = true })
  vim.keymap.set("n", "q", close_temp_buf, { buffer = buf, noremap = true })

  local success = vim.fn.jobwait({ job })[1]
  if success ~= 0 then
    vim.notify(vim.fn.join(errors, "\n"), vim.log.levels.ERROR)
  end
  return success
end

M.check_on_save = function()
  if config.options.check_on_save then
    require("spin").check()
  end
end

M.check_on_insert_leave = function()
  if config.options.check_on_insert_leave then
    require("spin").check()
  end
end

return M
