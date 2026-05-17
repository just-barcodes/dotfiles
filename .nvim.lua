-- Strip .tmpl suffix and detect filetype from the remaining extension
vim.filetype.add({
	extension = {
		tmpl = function(path)
			local inner = path:match("^(.+)%.tmpl$")
			if inner then
				return vim.filetype.match({ filename = inner })
			end
		end,
	},
})
