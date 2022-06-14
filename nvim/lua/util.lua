local opts = { noremap = true, silent = true }

return {
    keymap = function (mode, key, cmd)
        vim.api.nvim_set_keymap(mode, key, cmd, opts)
    end,
    req = function (pkg)
        local ok, p = pcall(require, pkg)
        if not ok then
            vim.notify(pkg .. ' not found!')
        end
        return ok, p
    end
}


-- keymap("i", "<C-n>", "<Esc>ji", opts)
-- keymap("i", "<C-p>", "<Esc>ki", opts)
-- keymap("i", "<C-f>", "<Esc>li", opts)
-- keymap("i", "<C-b>", "<Esc>hi", opts)
-- keymap("i", "<C-k>", "<Esc>ddi", opts)
-- keymap("i", "<C-a>", "<Esc>0i", opts)
-- keymap("i", "<C-e>", "<Esc>$i", opts)
