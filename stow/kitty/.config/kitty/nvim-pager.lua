vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.laststatus = 2
vim.opt.clipboard:append("unnamedplus")
vim.bo.modified = false

vim.cmd.hi("Normal ctermbg=NONE guibg=NONE")
vim.cmd.hi("NonText ctermbg=NONE guibg=NONE")
vim.cmd.hi("LineNr ctermbg=NONE guibg=NONE")

vim.api.nvim_open_term(0, {})

local function get_last_non_empty_line()
    local total = vim.api.nvim_buf_line_count(0)
    for i = total, 1, -1 do
        local line_content = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if line_content and line_content:match("%S") then
            return i
        end
    end
    return total
end

vim.keymap.set({ "n", "v" }, "G", function()
    local target = get_last_non_empty_line()
    vim.cmd(tostring(target))
end, { desc = "Ir a la última línea con texto (prompt)", silent = true })

vim.keymap.set("n", "<leader>r", function()
    if vim.wo.relativenumber then
        vim.wo.relativenumber = false
        vim.wo.number = false
    else
        vim.wo.number = true
        vim.wo.relativenumber = true
    end
end, { desc = "Toggle relative line numbers" })

vim.keymap.set("n", "<leader>n", function()
    if vim.wo.number and not vim.wo.relativenumber then
        vim.wo.number = false
    else
        vim.wo.number = true
        vim.wo.relativenumber = false
    end
end, { desc = "Toggle absolute line numbers" })

vim.keymap.set("n", "q", ":qa!<CR>", { silent = true })
vim.keymap.set("v", "q", "<Esc>:qa!<CR>", { silent = true })
vim.keymap.set("v", "y", '"+y:qa!<CR>', { silent = true })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "q", [[<C-\><C-n>:qa!<CR>]], { silent = true })
