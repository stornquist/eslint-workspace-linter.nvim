Enables the `:Lint` command in buffers where eslint has attached.

The command runs eslint in the root_dir of eslint LSP and appends any result to the quickfix list.

Using Lazy:

```lua
{
    "stornquist/eslint-workspace-linter.nvim",
    event = "VeryLazy",
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {},
}
```
