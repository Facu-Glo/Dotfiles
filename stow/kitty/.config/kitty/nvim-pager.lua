vim.opt.termguicolors = true
vim.opt.laststatus = 0
vim.opt.clipboard:append("unnamedplus")
vim.bo.modified = false

vim.cmd.hi("Normal ctermbg=NONE guibg=NONE")
vim.cmd.hi("NonText ctermbg=NONE guibg=NONE")
vim.cmd.hi("LineNr ctermbg=NONE guibg=NONE")

vim.api.nvim_open_term(0, {})

vim.opt.number = true
vim.opt.relativenumber = true

vim.keymap.set("n", "q", ":qa!<CR>")
vim.keymap.set("v", "q", "<Esc>:qa!<CR>")
vim.keymap.set("v", "y", '"+y:qa!<CR>')

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "q", [[<C-\><C-n>:qa!<CR>]], { silent = true })
