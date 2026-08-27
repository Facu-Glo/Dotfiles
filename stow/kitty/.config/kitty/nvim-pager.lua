vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.laststatus = 2
vim.opt.clipboard:append("unnamedplus")
vim.bo.modified = false

vim.cmd([[
  highlight Normal ctermbg=NONE guibg=NONE
  highlight NonText ctermbg=NONE guibg=NONE
  highlight LineNr ctermbg=NONE guibg=NONE
  highlight NormalFloat ctermbg=NONE guibg=NONE
  highlight FloatBorder guifg=#89b4fa guibg=NONE
  highlight FloatTitle guifg=#cdd6f4 gui=bold guibg=NONE
  highlight FloatFooter guifg=#a6adc8 gui=italic guibg=NONE
]])

vim.api.nvim_open_term(0, {})

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

local function get_line_at(row)
    return vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
end

local function trim_blank_edges(lines)
    while #lines > 0 and lines[1]:match("^%s*$") do table.remove(lines, 1) end
    while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
    return lines
end

local function strip_trailing_spaces(lines)
    local cleaned = {}
    for _, l in ipairs(lines) do
        table.insert(cleaned, (l:gsub("%s+$", "")))
    end
    return cleaned
end

local hostname = (vim.uv or vim.loop).os_gethostname()
local prompt_pattern = string.format([[^\s*[a-zA-Z0-9_.-]\+@%s]], vim.fn.escape(hostname, [[^$.*~[]\]]))
local GLYPHS = { "❯", "➜", "$", "%", "#", ">", "⟩", "›" }

local function find_glyph(line, from)
    local best_start, best_end
    for _, g in ipairs(GLYPHS) do
        local s, e = line:find(g, from, true)
        if s and (not best_start or s < best_start) then
            best_start, best_end = s, e
        end
    end
    return best_start, best_end
end

local function is_prompt_line(line)
    local lead = line:match("^%s*") or ""
    if #line <= #lead then return false end
    local gs = find_glyph(line, #lead + 1)
    return gs == #lead + 1
end

local function strip_prompt_prefix(line)
    if not line then return "" end
    line = line:gsub("\27%[[0-9;]*[a-zA-Z]", ""):gsub("\27%][^\7]*\7", "")

    local host_prefix = line:match("^%s*[a-zA-Z0-9_.%-]+@[^%s:]+:")
    if host_prefix then
        local _, ge = find_glyph(line, #host_prefix + 1)
        if ge then line = line:sub(ge + 1) end
    else
        local lead = line:match("^%s*") or ""
        local gs, ge = find_glyph(line, #lead + 1)
        if gs == #lead + 1 then line = line:sub(ge + 1) end
    end

    return line:gsub("^[\128-\191]+", ""):gsub("^%s+", "")
end

local function search_prompt_line(from, to, step)
    for row = from, to, step do
        local l = get_line_at(row)
        if is_prompt_line(l) then return l end
    end
    return nil
end

local function find_current_command()
    local total = vim.api.nvim_buf_line_count(0)
    local start_row = math.min(vim.fn.line("."), total)
    return search_prompt_line(start_row, 1, -1) or search_prompt_line(total, start_row + 1, -1)
end

local TARGET_MATCH = "state:overlay_parent"

local function kitty_cmd(args, stdin)
    local cmd = { "kitten", "@", unpack(args) }
    return vim.system(cmd, { text = true, stdin = stdin }):wait()
end

local function has_overlay_parent()
    local res = kitty_cmd({ "ls", "--match", TARGET_MATCH })
    if res.code ~= 0 then
        local detail = vim.trim(res.stderr or "")
        return false, "kitten @ ls falló (" .. (detail ~= "" and detail or "remote control inactivo?") .. ")"
    end
    local ok, tree = pcall(vim.json.decode, res.stdout or "")
    if not ok or type(tree) ~= "table" then
        return false, "respuesta inválida de kitten @ ls"
    end
    for _, os_window in ipairs(tree) do
        if #(os_window.tabs or {}) > 0 then return true, nil end
    end
    return false, "no hay ventana padre de este overlay"
end

local function dispatch_to_prompt(lines, execute)
    local pre = kitty_cmd({ "send-text", "--match", TARGET_MATCH, "\x01\x0b" })
    if pre.code ~= 0 then
        vim.notify("Pager->prompt: no se pudo limpiar (" .. (pre.stderr or "sin detalle") .. ")", vim.log.levels.ERROR)
        return
    end

    local payload = table.concat(lines, "\n") .. (execute and "\r" or "")
    local res = kitty_cmd({
        "send-text",
        "--match", TARGET_MATCH,
        "--bracketed-paste=" .. (execute and "disable" or "enable"),
        "--stdin",
    }, payload)

    vim.schedule(function()
        if res.code == 0 then
            vim.cmd("qa!")
        else
            vim.notify("Pager->prompt: error al enviar (" .. (res.stderr or "sin detalle") .. ")", vim.log.levels.ERROR)
        end
    end)
end

local function open_scratch(lines)
    lines = strip_trailing_spaces(lines)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "sh"

    local width = math.floor(vim.o.columns * 0.80)
    local height = math.max(math.floor(vim.o.lines * 0.35), #lines + 3)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = " Editar Comando ",
        title_pos = "center",
        footer = " <CR>: Pegar | <Space><CR>: Ejecutar | <Esc>/<M-e>: Cancelar ",
        footer_pos = "center",
    })

    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].wrap = true
    vim.wo[win].signcolumn = "no"
    vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false

    local function send_from_scratch(execute_now)
        local edited = trim_blank_edges(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
        if #edited == 0 then
            vim.notify("Pager->prompt: nada que enviar", vim.log.levels.WARN)
            return
        end
        vim.api.nvim_win_close(win, true)
        dispatch_to_prompt(edited, execute_now)
    end

    local function close_scratch()
        vim.api.nvim_win_close(win, true)
    end

    local opts = { buffer = buf, silent = true }
    vim.keymap.set({ "n", "v" }, "<CR>", function() send_from_scratch(false) end,
        vim.tbl_extend("force", opts, { desc = "Pegar en el prompt" }))
    vim.keymap.set({ "n", "v" }, "<leader><CR>", function() send_from_scratch(true) end,
        vim.tbl_extend("force", opts, { desc = "Enviar y ejecutar" }))
    vim.keymap.set("i", "<M-e>", "<Esc>", vim.tbl_extend("force", opts, { desc = "Salir a modo normal", nowait = true }))
    vim.keymap.set("n", "<Esc>", close_scratch, vim.tbl_extend("force", opts, { desc = "Cancelar" }))
    vim.keymap.set("n", "<M-e>", close_scratch, vim.tbl_extend("force", opts, { desc = "Cancelar" }))
end

local function with_visual_selection(callback)
    local mode = vim.fn.mode()
    local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

    vim.schedule(function()
        local lines = trim_blank_edges(region)
        if #lines > 0 then
            if is_prompt_line(lines[1]) then
                lines[1] = strip_prompt_prefix(lines[1])
            end
            callback(lines)
        end
    end)
end

vim.keymap.set({ "n", "v" }, "<C-k>", function() vim.fn.search(prompt_pattern, "bW") end,
    { desc = "Prompt anterior", silent = true })
vim.keymap.set({ "n", "v" }, "<C-j>", function() vim.fn.search(prompt_pattern, "W") end,
    { desc = "Prompt siguiente", silent = true })
vim.keymap.set({ "n", "v" }, "G", function() vim.cmd(tostring(get_last_non_empty_line())) end,
    { desc = "Ir al último prompt", silent = true })

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

vim.keymap.set({ "n", "v" }, "<leader>r", function() toggle_numbering("rel") end,
    { desc = "Toggle relative line numbers" })
vim.keymap.set({ "n", "v" }, "<leader>n", function() toggle_numbering("abs") end,
    { desc = "Toggle absolute line numbers" })

vim.keymap.set({ "n", "v" }, "q", ":qa!<CR>", { silent = true })
vim.keymap.set("v", "y", '"+y:qa!<CR>', { silent = true })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "<M-e>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "q", [[<C-\><C-n>:qa!<CR>]], { silent = true })

vim.keymap.set("v", "<CR>", function()
    with_visual_selection(function(lines) dispatch_to_prompt(lines, false) end)
end, { desc = "Pegar selección en el prompt", silent = true })

vim.keymap.set("v", "<leader><CR>", function()
    with_visual_selection(function(lines) dispatch_to_prompt(lines, true) end)
end, { desc = "Enviar selección al prompt y ejecutar", silent = true })

vim.keymap.set("n", "<leader>e", function()
    local ok, err = has_overlay_parent()
    if not ok then
        vim.notify("Pager->prompt: " .. err, vim.log.levels.ERROR)
        return
    end
    local line = find_current_command()
    open_scratch({ line and strip_prompt_prefix(line) or "" })
end, { desc = "Editar comando actual" })

vim.keymap.set("v", "<leader>e", function()
    with_visual_selection(open_scratch)
end, { desc = "Editar selección en scratch" })
