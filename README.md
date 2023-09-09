# spin.nvim

A plugin for interacting with the verification tool [spin].

## Features

- Validates [promela] syntax and sends reports using the diagnostics framework.
- Hover capabilities using LSP (currently lacks support for structs/typedef).
- Execute spin commands, see [Usage](#usage).

## Requirements

- The [spin] tool itself
- gcc (optional)

Run `:checkhealth spin` to ensure that the plugin is working correctly.

## Installation

Install with your package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "sebostien/spin.nvim",
  ft = { "promela" },
  opts = {
    -- Your configuration or empty to use the default settings
  }
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "sebostien/spin.nvim",
  config = function()
    require("spin").setup({
      -- Your configuration or empty to use the default settings
    })
  end
}
```

## Configuration

The default settings are listed below:

```lua
{
  check_on_save = true,             -- Run check on file save
  check_on_insert_leave = false,    -- Run check when leaving insert mode
  generate_command = "spin -a",     -- Command to generate verifier
  trail_command = "spin -t -p -l",  -- Command to follow simulation trail
  gcc_command = "gcc -o pan pan.c", -- Command to compile verifier
  on_attach = function(client, bufnr)
    -- Set keybindings, etc. here
    -- bind `K` to hover
    -- vim.keymap.set("n", "K", vim.lsp.buf.hover)
  end,
}
```

## Usage

### Commands

- `:SpinCheck`    Check syntax in the current buffer.
- `:SpinGenerate` Generate verifier for current buffer.
- `:SpinVerify`   Generate and run verifier for current buffer.
                  Opens output in a new buffer (exit with `q` or `<Esc>`).
- `:SpinTrail`    Follow trail from a failed verification of the current buffer.


[promela]: https://en.wikipedia.org/wiki/Promela
[spin]: https://spinroot.com/spin/whatispin.html
