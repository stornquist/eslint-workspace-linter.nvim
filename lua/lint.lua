local M = {}

---@alias ListOptions "quickfix"|"trouble"

---@class PluginOptions
---@field auto_open? boolean
---@field list? ListOptions
---@field srcDir? string

---@type PluginOptions
local default_options = {
	auto_open = true,
	list = "quickfix",
	srcDir = "src",
}

---@param opts PluginOptions
M.setup = function(opts)
	local status, lspconfig = pcall(require, "lspconfig")
	if not status then
		print("lspconfig not found")
	end

	if not lspconfig["eslint"] then
		print("make sure eslint is installed and setup before loading eslint-workspace-lint")
	else
		local options = vim.tbl_deep_extend("force", default_options, opts or {})

		lspconfig["eslint"].setup({
			on_attach = function(client, bufnr)
				local original = lspconfig["eslint"].manager.config.capabilities.on_attach
				vim.api.nvim_buf_create_user_command(0, "Lint", function()
					-- local workspace =
					-- 	vim.lsp.get_active_clients({ bufnr = bufnr, name = "eslint" })[1].config.settings.workspaceFolder.uri
					local workspace = ""
					local eslintFiles = {
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.yaml",
						".eslintrc.yml",
						".eslintrc.json",
						".eslintrc",
						"package.json",
					}
					for _, file in ipairs(eslintFiles) do
						local res = vim.fn.findfile(file, ".;")
						if #res > 0 then
							if options.debug then
								print("Found eslint config: " .. res)
							end
							workspace = vim.fn.getcwd() .. "/" .. res:gsub("/.eslintrc.*", "")
							break
						end
					end

					if not workspace then
						print("No eslint config found")
						return
					end

					vim.api.nvim_command(
						":set errorformat=%f:%l:%c:%m | setlocal makeprg=npx\\ eslint\\ -f\\ unix\\ '"
							.. workspace
							.. "/"
							.. options.srcDir
							.. "/**/*.{js,ts,jsx,tsx}'"
					)
					vim.api.nvim_command(":make")

					local quickfixEntries = vim.fn.getqflist()
					if #quickfixEntries == 0 then
						print("No linting errors found")
						return
					end

					if not options.auto_open then
						return
					end

					-- clean up quickfix list and remove invalid entries
					for i = #quickfixEntries, 1, -1 do
						if quickfixEntries[i].valid == 0 then
							table.remove(quickfixEntries, i)
						end
					end

					vim.fn.setqflist(quickfixEntries)

					if options.list == "quickfix" then
						vim.api.nvim_command(":copen")
					end

					if options.list == "trouble" and require("trouble") then
						require("trouble").open({ mode = "quickfix" })
					end
				end, { nargs = 0 })

				if original then
					original(client, bufnr)
				end
			end,
		})
	end
end

return M
