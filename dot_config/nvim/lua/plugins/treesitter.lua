return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ensure_installed = {
				"bash",
				"c",
				"css",
				"diff",
				"go",
				"html",
				"hyprlang",
				"json",
				"lua",
				"luadoc",
				"make",
				"markdown",
				"markdown_inline",
				"qmljs",
				"query",
				"toml",
				"vim",
				"vimdoc",
				"yaml",
			}
			require("nvim-treesitter").install(ensure_installed)

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ev)
					local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
					if lang and pcall(vim.treesitter.start, ev.buf, lang) then
						vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.wo.foldmethod = "expr"
						vim.wo.foldlevel = 99
					end
				end,
			})
		end,
	},

	-- Sticky header showing current function/class scope.
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = { max_lines = 3 },
	},
}
