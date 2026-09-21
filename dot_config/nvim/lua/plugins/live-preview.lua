-- File shown by the preview tab that <leader>tp last opened.
local last

-- `LivePreview start` always opens a new browser tab and leaves the previous
-- preview tab behind. When a tab is still connected, send it to the new file
-- instead. The page renders "update" messages as raw HTML, and an <img onerror>
-- is what runs when inserted through innerHTML.
local function start_preview()
	local utils = require("livepreview.utils")
	local server = require("livepreview.server")
	local cfg = require("livepreview.config").config
	local file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
	local rel = utils.supported_filetype(file) and utils.get_relative_path(file, vim.fs.normalize(vim.uv.cwd() or ""))
	if not rel then
		vim.cmd("LivePreview start")
		return
	end
	if last and #server.connecting_clients > 0 then
		local url = ("http://%s:%d/%s"):format(cfg.address, cfg.port, vim.uri_encode(rel))
		local msg = {
			type = "update",
			filepath = last, -- the tab only handles updates for the file it shows
			content = ("<img src=x onerror=\"location.replace('%s')\">"):format(url),
		}
		for _, client in ipairs(server.connecting_clients) do
			server.websocket.send_json(client, msg)
		end
		-- Restart the server once the tab has moved on, so its reconnect
		-- reload lands on the new file rather than the old one.
		vim.defer_fn(function()
			require("livepreview").start(file, cfg.port)
		end, 300)
	else
		vim.cmd("LivePreview start")
	end
	last = file
end

return {
	"brianhuster/live-preview.nvim",
	cmd = "LivePreview",
	main = "livepreview",
	opts = { browser = "browser-here" }, -- ~/.local/bin/browser-here
	keys = {
		{ "<leader>tp", start_preview, desc = "[T]oggle live [P]review (start)" },
		{ "<leader>tP", "<cmd>LivePreview close<cr>", desc = "[T]oggle live [P]review (close)" },
	},
}
