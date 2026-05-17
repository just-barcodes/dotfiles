return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Disable "format_on_save lsp_fallback" for languages that don't
			-- have a well standardized coding style. You can add additional
			-- languages here or re-enable it for the disabled ones.
			local disable_filetypes = { c = true, cpp = true }
			if disable_filetypes[vim.bo[bufnr].filetype] then
				return nil
			else
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format", "ruff_organize_imports" },
			javascript = { "prettierd", stop_after_first = true },
			javascriptreact = { "prettierd", stop_after_first = true },
			typescript = { "prettierd", stop_after_first = true },
			typescriptreact = { "prettierd", stop_after_first = true },
			json = { "prettierd", stop_after_first = true },
			yaml = { "prettierd", stop_after_first = true },
			markdown = { "prettierd", stop_after_first = true },
			sh = { "shfmt" },
		},
	},
}
