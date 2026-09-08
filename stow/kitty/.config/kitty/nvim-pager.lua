vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.laststatus = 2
vim.opt.clipboard:append("unnamedplus")
vim.bo.modified = false

vim.opt.pumheight = 8
vim.opt.pumwidth = 25
vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.cmd([[
  highlight Normal ctermbg=NONE guibg=NONE
  highlight NonText ctermbg=NONE guibg=NONE
  highlight LineNr ctermbg=NONE guibg=NONE
  highlight NormalFloat ctermbg=NONE guibg=NONE
  highlight FloatBorder guifg=#89b4fa guibg=NONE
  highlight FloatTitle guifg=#cdd6f4 gui=bold guibg=NONE
  highlight FloatFooter guifg=#a6adc8 gui=italic guibg=NONE

  highlight Pmenu guibg=#181825 guifg=#cdd6f4
  highlight PmenuSel guibg=#89b4fa guifg=#11111b gui=bold
  highlight PmenuSbar guibg=#313244
  highlight PmenuThumb guibg=#89b4fa

  highlight HistActive guibg=#313244 guifg=#89b4fa gui=bold
]])

vim.api.nvim_open_term(0, {})

local uv = vim.uv or vim.loop

local hostname = uv.os_gethostname()
local prompt_pattern = string.format(
    [[^\s*[a-zA-Z0-9_.-]\+@%s]],
    vim.fn.escape(hostname, [[^$.*~[]\]])
)

local function get_last_non_empty_line()
    local total = vim.api.nvim_buf_line_count(0)
    for i = total, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if line and line:match("%S") then
            return i
        end
    end
    return total
end

local function toggle_numbering(mode)
    if mode == "rel" then
        local state = vim.wo.relativenumber
        vim.wo.number = not state
        vim.wo.relativenumber = not state
    elseif mode == "abs" then
        local state = vim.wo.number and not vim.wo.relativenumber
        vim.wo.number = not state
        vim.wo.relativenumber = false
    end
end

vim.keymap.set({ "n", "v" }, "<C-k>", function()
    vim.fn.search(prompt_pattern, "bW")
end, { desc = "Prompt anterior (hostname)", silent = true })

vim.keymap.set({ "n", "v" }, "<C-j>", function()
    vim.fn.search(prompt_pattern, "W")
end, { desc = "Prompt siguiente (hostname)", silent = true })

vim.keymap.set({ "n", "v" }, "G", function()
    vim.cmd(tostring(get_last_non_empty_line()))
end, { desc = "Ir a la última línea con texto", silent = true })

vim.keymap.set({ "n", "v" }, "<leader>r", function() toggle_numbering("rel") end, { desc = "Toggle lineas relativas" })
vim.keymap.set({ "n", "v" }, "<leader>n", function() toggle_numbering("abs") end, { desc = "Toggle lineas absolutas" })

vim.keymap.set({ "n", "v" }, "q", ":qa!<CR>", { silent = true })
vim.keymap.set("v", "y", '"+y:qa!<CR>', { silent = true })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set({ "t", "n" }, "<M-e>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "q", [[<C-\><C-n>:qa!<CR>]], { silent = true })
