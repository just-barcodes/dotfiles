return {
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", opts = {} },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			-- Distinct color for K (hover) and signature-help popups so they
			-- stand out from the editor background. Scoped to popups opened
			-- via vim.lsp.util.open_floating_preview — Snacks pickers,
			-- completion menus, etc. are untouched.
			local function set_hover_hl()
				vim.api.nvim_set_hl(0, "LspHoverNormal", { bg = "#2a1a3a", fg = "#ece3cc" })
				vim.api.nvim_set_hl(0, "LspHoverBorder", { bg = "#2a1a3a", fg = "#dbb32d" })
			end
			set_hover_hl()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("lsp-hover-hl", { clear = true }),
				callback = set_hover_hl,
			})

			local orig_open_preview = vim.lsp.util.open_floating_preview
			---@diagnostic disable-next-line: duplicate-set-field
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts = opts or {}
				opts.border = opts.border or "rounded"
				opts.max_width = opts.max_width or 140
				local bufnr, winid = orig_open_preview(contents, syntax, opts, ...)
				if winid and vim.api.nvim_win_is_valid(winid) then
					vim.wo[winid].winhighlight = table.concat({
						"Normal:LspHoverNormal",
						"NormalFloat:LspHoverNormal",
						"FloatBorder:LspHoverBorder",
					}, ",")
				end
				return bufnr, winid
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("grr", function()
						Snacks.picker.lsp_references()
					end, "[G]oto [R]eferences")
					map("gri", function()
						Snacks.picker.lsp_implementations()
					end, "[G]oto [I]mplementation")
					map("grd", function()
						Snacks.picker.lsp_definitions()
					end, "[G]oto [D]efinition")
					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					map("gO", function()
						Snacks.picker.lsp_symbols()
					end, "Open Document Symbols")
					map("gW", function()
						Snacks.picker.lsp_workspace_symbols()
					end, "Open Workspace Symbols")
					map("grt", function()
						Snacks.picker.lsp_type_definitions()
					end, "[G]oto [T]ype Definition")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if
						client
						and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
					then
						local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					if
						client
						and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
				},
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- LSP server name (lspconfig) → mason package name (when different).
			-- Anything not in this map shares its name across both systems.
			local mason_name = {
				bashls = "bash-language-server",
				jsonls = "json-lsp",
				yamlls = "yaml-language-server",
				lua_ls = "lua-language-server",
			}

			local servers = {
				vtsls = {},
				basedpyright = {},
				bashls = {},
				ruff = {},
				gopls = {},
				hyprls = {},
				taplo = {},
				yamlls = {},
				jsonls = {},
				marksman = {},
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
						},
					},
				},
			}

			vim.lsp.config("*", { capabilities = capabilities })
			for name, opts in pairs(servers) do
				vim.lsp.config(name, opts)
			end
			vim.lsp.enable(vim.tbl_keys(servers))

			local ensure_installed = {}
			for name in pairs(servers) do
				table.insert(ensure_installed, mason_name[name] or name)
			end
			vim.list_extend(ensure_installed, { "stylua", "prettierd", "shfmt" })
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
		end,
	},
}
