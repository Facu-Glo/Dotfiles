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
local TARGET_MATCH = "state:overlay_parent"
local HIST_NS = vim.api.nvim_create_namespace("scratch_hist_ns")
local HIST_MAX_ITEMS = 200
local MAX_READ_BYTES = 64 * 1024

local hostname = uv.os_gethostname()
local prompt_pattern = string.format(
    [[^\s*[a-zA-Z0-9_.-]\+@%s]],
    vim.fn.escape(hostname, [[^$.*~[]\]])
)

local function kitty_cmd(args, stdin)
    return vim.system({ "kitten", "@", unpack(args) }, { text = true, stdin = stdin }):wait()
end

local function has_overlay_parent()
    local res = kitty_cmd({ "ls", "--match", TARGET_MATCH })
    if res.code ~= 0 then return false, "kitten @ ls falló" end
    local ok, tree = pcall(vim.json.decode, res.stdout or "")
    if not ok or type(tree) ~= "table" then return false, "JSON inválido" end
    for _, os_win in ipairs(tree) do
        if #(os_win.tabs or {}) > 0 then return true, nil end
    end
    return false, "no hay ventana padre"
end

local function dispatch_to_prompt(lines, execute)
    local pre = kitty_cmd({ "send-text", "--match", TARGET_MATCH, "\x01\x0b" })
    if pre.code ~= 0 then
        vim.notify("Pager: error al limpiar", vim.log.levels.ERROR)
        return
    end

    local payload = table.concat(lines, "\n") .. (execute and "\r" or "")
    local res = kitty_cmd({
        "send-text",
        "--match", TARGET_MATCH,
        "--bracketed-paste=" .. (execute and "disable" or "enable"),
        "--stdin",
    }, payload)

    if res.code == 0 then
        vim.cmd("qa!")
    else
        vim.notify("Pager: error al enviar", vim.log.levels.ERROR)
    end
end

local function get_shell_history()
    local path = vim.fn.expand("~/.zsh_history")
    local fd = uv.fs_open(path, "r", 438)
    if not fd then
        path = vim.fn.expand("~/.bash_history")
        fd = uv.fs_open(path, "r", 438)
        if not fd then return {} end
    end

    local stat = uv.fs_fstat(fd)
    if not stat or stat.size == 0 then
        uv.fs_close(fd)
        return {}
    end

    local read_size = math.min(stat.size, MAX_READ_BYTES)
    local offset = math.max(0, stat.size - read_size)
    local chunk = uv.fs_read(fd, read_size, offset)
    uv.fs_close(fd)

    if not chunk then return {} end

    local history, seen = {}, {}
    local lines = vim.split(chunk, "\n", { plain = true, trimempty = true })

    for i = #lines, 1, -1 do
        local l = lines[i]
        local cmd = l:match("^: %d+:%d+;(.*)") or l
        cmd = vim.trim(cmd)

        if cmd ~= "" and not seen[cmd] then
            seen[cmd] = true
            history[#history + 1] = cmd
            if #history >= HIST_MAX_ITEMS then break end
        end
    end
    return history
end

local function open_scratch(initial_lines)
    local history = get_shell_history()
    local hist_idx = 0
    local saved_draft = ""

    local lines = initial_lines or {}
    if #lines == 0 and #history > 0 then
        lines = { history[1] }
        hist_idx = 1
    end

    local buf = vim.api.nvim_create_buf(false, true)
    local h_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype, vim.bo[h_buf].buftype = "nofile", "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[h_buf].bufhidden = "hide"
    vim.bo[buf].filetype, vim.bo[h_buf].filetype = "sh", "sh"

    vim.bo[buf].completefunc = "v:lua.history_complete"
    _G.history_complete = function(findstart, base)
        if findstart == 1 then return 0 end
        local matches = {}
        local max_len = math.floor(vim.o.columns * 0.40)

        local escaped = base:lower():gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        local pattern = ".*" .. escaped:gsub(".", "%1.*")

        for i = 1, #history do
            local item = history[i]
            local item_lower = item:lower()

            if item_lower:match(pattern) then
                matches[#matches + 1] = {
                    word = item,
                    abbr = #item > max_len and (item:sub(1, max_len - 3) .. "...") or item,
                    menu = "[hist]",
                }
            end
        end
        return matches
    end

    local cols, rows = vim.o.columns, vim.o.lines
    local total_width = math.floor(cols * 0.85)
    local height = math.max(math.floor(rows * 0.40), #lines + 5)
    local row = math.floor((rows - height) / 2)
    local start_col = math.floor((cols - total_width) / 2)
    local editor_width = math.floor(total_width * 0.58)
    local hist_width = total_width - editor_width - 2

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = row,
        col = start_col,
        width = total_width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = " Comando ",
        title_pos = "center",
        footer =
        " <C-j>/<C-k>: Historial | <C-Space>: Autocompletado | <leader>h: Panel | <CR>: Pegar | <leader><CR>: Ejecutar ",
        footer_pos = "center",
    })

    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
    vim.wo[win].wrap = true

    local hist_visible = false
    local hist_width_saved = hist_width
    local h_win = nil

    local display_history = {}
    for i = 1, #history do
        display_history[i] = string.format(" %2d. %s", i, (history[i]:gsub("\n", " ")))
    end
    vim.api.nvim_buf_set_lines(h_buf, 0, -1, false, display_history)
    vim.bo[h_buf].modifiable = false

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local function update_hist_highlight()
        vim.api.nvim_buf_clear_namespace(h_buf, HIST_NS, 0, -1)
        if hist_idx > 0 and hist_idx <= #history then
            vim.api.nvim_buf_set_extmark(h_buf, HIST_NS, hist_idx - 1, 0, {
                line_hl_group = "HistActive",
            })
            if hist_visible and h_win and vim.api.nvim_win_is_valid(h_win) then
                vim.api.nvim_win_set_cursor(h_win, { hist_idx, 0 })
            end
        end
    end
    update_hist_highlight()

    local function navigate_history(dir)
        if #history == 0 then return end
        if hist_idx == 0 then
            saved_draft = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
        end

        local n_idx = math.max(0, math.min(#history, hist_idx + dir))
        if n_idx == hist_idx then return end
        hist_idx = n_idx

        local target = (hist_idx == 0) and saved_draft or history[hist_idx]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(target, "\n", { plain = true }))
        vim.api.nvim_win_set_cursor(win, { 1, #target })
        update_hist_highlight()
    end

    local function close_all()
        if h_win and vim.api.nvim_win_is_valid(h_win) then vim.api.nvim_win_close(h_win, true) end
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end

    local function send_from_scratch(exec_now)
        local raw = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        while #raw > 0 and raw[1]:match("^%s*$") do table.remove(raw, 1) end
        while #raw > 0 and raw[#raw]:match("^%s*$") do table.remove(raw) end
        if #raw == 0 then return end

        close_all()
        dispatch_to_prompt(raw, exec_now)
    end

    local opts = { buffer = buf, silent = true }
    _G.__scratch_nav = navigate_history

    vim.keymap.set("n", "<C-j>", function() navigate_history(1) end, opts)
    vim.keymap.set("n", "<C-k>", function() navigate_history(-1) end, opts)
    vim.keymap.set("i", "<C-j>",
        function() return vim.fn.pumvisible() == 1 and "<C-n>" or "<Cmd>lua _G.__scratch_nav(1)<CR>" end,
        { buffer = buf, expr = true, silent = true })
    vim.keymap.set("i", "<C-k>",
        function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<Cmd>lua _G.__scratch_nav(-1)<CR>" end,
        { buffer = buf, expr = true, silent = true })

    local completion_active = false

    vim.keymap.set("i", "<C-Space>", function()
        completion_active = true
        return "<C-x><C-u>"
    end, { buffer = buf, expr = true, silent = true })
    vim.keymap.set("i", "<C-@>", function()
        completion_active = true
        return "<C-x><C-u>"
    end, { buffer = buf, expr = true, silent = true })

    vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = buf,
        callback = function()
            if completion_active and vim.fn.pumvisible() == 0 then
                vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-u>", true, false, true), "n")
            end
        end,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        buffer = buf,
        callback = function() completion_active = false end,
    })

    -- Toggle panel de historial
    local function toggle_history()
        if hist_visible and h_win then
            vim.api.nvim_win_close(h_win, true)
            vim.api.nvim_win_set_config(win, {
                relative = "editor",
                row = row,
                col = start_col,
                width = total_width,
                height = height,
            })
            hist_visible = false
        else
            h_win = vim.api.nvim_open_win(h_buf, false, {
                relative = "editor",
                row = row,
                col = start_col + editor_width + 2,
                width = hist_width_saved,
                height = height,
                style = "minimal",
                border = "rounded",
                title = " Historial ",
                title_pos = "center",
                footer = string.format(" %d comandos ", #history),
                footer_pos = "center",
            })
            vim.wo[h_win].cursorline = true
            vim.wo[h_win].number = false
            vim.wo[h_win].relativenumber = false
            vim.wo[h_win].signcolumn = "no"
            vim.wo[h_win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
            vim.wo[h_win].wrap = false
            update_hist_highlight()
            vim.api.nvim_win_set_config(win, {
                relative = "editor",
                row = row,
                col = start_col,
                width = editor_width,
                height = height,
            })
            hist_visible = true
        end
    end

    vim.keymap.set("n", "<leader>h", toggle_history, { desc = "Toggle panel de historial" })

    vim.keymap.set("i", "<Tab>", function() return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>" end,
        { buffer = buf, expr = true, silent = true })
    vim.keymap.set("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end,
        { buffer = buf, expr = true, silent = true })
    vim.keymap.set({ "n", "v" }, "<CR>", function() send_from_scratch(false) end, opts)
    vim.keymap.set({ "n", "v" }, "<leader><CR>", function() send_from_scratch(true) end, opts)
    vim.keymap.set("i", "<M-e>", "<Esc>", vim.tbl_extend("force", opts, { nowait = true }))
    vim.keymap.set("n", "<Esc>", close_all, opts)
    vim.keymap.set("n", "<M-e>", close_all, opts)
end

local function with_visual_selection(callback)
    local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
    vim.schedule(function()
        while #region > 0 and region[1]:match("^%s*$") do table.remove(region, 1) end
        while #region > 0 and region[#region]:match("^%s*$") do table.remove(region) end
        if #region > 0 then callback(region) end
    end)
end

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
vim.keymap.set("t", "<M-e>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "q", [[<C-\><C-n>:qa!<CR>]], { silent = true })

vim.keymap.set("n", "<leader>e", function()
    local ok, err = has_overlay_parent()
    if not ok then
        vim.notify("Pager: " .. err, vim.log.levels.ERROR)
        return
    end
    open_scratch()
end, { desc = "Editor de comandos con historial" })

vim.keymap.set("v", "<leader>e", function() with_visual_selection(open_scratch) end, { desc = "Editar selección" })
vim.keymap.set("v", "<CR>", function() with_visual_selection(function(l) dispatch_to_prompt(l, false) end) end,
    { silent = true })
vim.keymap.set("v", "<leader><CR>", function() with_visual_selection(function(l) dispatch_to_prompt(l, true) end) end,
    { silent = true })
