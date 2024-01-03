local M = {}

M.setup = function(opts)
	local status, lspconfig = pcall(require, "lspconfig")
	if not status then
		print("lspconfig not found")
	end

	if not lspconfig["eslint"] then
		print("make sure eslint is installed and setup before loading eslint-workspace-lint")
	else
		lspconfig["eslint"].setup({
			on_attach = function(client, bufnr)
				local original = lspconfig["eslint"].manager.config.capabilities.on_attach
				vim.api.nvim_buf_create_user_command(0, "Lint", function()
					local workspace =
						vim.lsp.get_active_clients({ bufnr = bufnr, name = "eslint" })[1].config.settings.workspaceFolder.uri
					vim.api.nvim_command(
						":set makeprg=npx\\ eslint\\ -f\\ unix\\ '" .. workspace .. "/src/**/*.{js,ts,jsx,tsx}'"
					)
					vim.api.nvim_command(":make")
					local len = vim.api.nvim_exec2("echo len(getqflist())", { output = true }).output
					if tonumber(len) > 0 then
						vim.api.nvim_command(":copen")
					else
						print("No linting errors found")
					end
				end, { nargs = 0 })
				original(client, bufnr)
			end,
		})
	end
end

return M
