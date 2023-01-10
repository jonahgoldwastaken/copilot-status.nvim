# copilot-status.nvim

A [copilot.lua][copilot] status indicator for Neovim.

## Requirements

- Neovim 0.8+
- [copilot.lua][copilot]
- A [patched font] or a font like [Nonicons][nonicons] (wich I recommend)
- A place where you can show the status indicator, like [lualine][lualine]

## (Minimal) installation

### lazy.nvim

```lua
{
	"jonahgoldwastaken/copilot-status.nvim",
	dependencies = { "copilot.lua" } -- or "zbirenbaum/copilot.lua"
	lazy = true,
	event = "BufReadPost",
}
```

### packer.nvim

```lua
use({
	"jonahgoldwastaken/copilot-status.nvim",
	after = { "zbirenbaum/copilot.lua" },
	event = "BufReadPost",
})
```

### vim-plug

```vim
Plug "jonahgoldwastaken/copilot-status.nvim", { "branch": "main" }
```

## Usage

`copilot-status` keeps track of two fields:

- **status** which is one of
	- "offline"
	- "loading"
	- "idle"
	- "warning"
	- "error"
- **message** which is only populated when an error occurs

You can get these values with `.status()` and manipulate them yourself, or use the provided `.status_string()` function, which turns the status into an icon and appends the optional "message" if it exists. You can [configure](#configuration) the icons yourself.

### Example with lualine

```lua
require('lualine').setup {
	sections = {
		lualine_x = {
			require('copilot-status').status_string,
		}
	}
}
```

## Configuration

`copilot-status` has little settings to adjust at the moment. Here are the defaults:

```lua
require('copilot-status').setup({
	icons = {
		idle = " ",
		error = " ",
		offline = " ",
		warning = "𥉉 ",
		loading = " ",
	},
	debug = false,
})
```

> Make sure `.setup()`` is run before `.string()` or `.status_string()`, otherwise the plugin will just ignore your configuration.

## Acknowledgements

- [copilot.lua][copilot] for creating an incredibly easy API to work with
- [Nonicons][nonicons] for providing great icons for this plugin

[nonicons]: https://github.com/yamatsum/nonicons
[copilot]: https://github.com/zbirenbaum/copilot.lua
[lualine]: https://github.com/nvim-lualine/lualine.nvim
[octicons]: https://github.com/ryanoasis/nerd-fonts/tree/gh-pages 

