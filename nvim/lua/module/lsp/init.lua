local util = require('util')

local M = {}

M.pkg = {
    'neovim/nvim-lspconfig',
    'williamboman/nvim-lsp-installer',
}

function M.setup()
    lsp_init()
    M.keymap()
end

function M.keymap()
end

function lsp_init()
    local ok, _ = pcall(require, 'lspconfig')
    if not ok then
        vim.notify('lsp not found!')
        return
    end

    local lsp_installer = require('nvim-lsp-installer')
    local cap = vim.lsp.protocol.make_client_capabilities()

    local ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
    if not ok then
        vim.notify('cmp_nvim_lsp not found!')
    else
        cap = cmp_nvim_lsp.update_capabilities(cap)
    end

    lsp_installer.on_server_ready(function(server)
        local opts = {
            on_attach = on_attach,
            capabilities = cap,
        }
        
        if server.name == "sumneko_lua" then
            local lsp_opts = require("module.lsp.setting.sumneko_lua")
            opts = vim.tbl_deep_extend("force", lsp_opts, opts)
        end

        server:setup(opts)
    end)
end

function on_attach(client, bufnr)
    local f_keymap = function(key, cmd)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', key, cmd, { noremap = true, silent = true })
    end
    f_keymap("gdc", "<cmd>lua vim.lsp.buf.declaration()<CR>")
    f_keymap("gdf", "<cmd>lua vim.lsp.buf.definition()<CR>")
    f_keymap("gh", "<cmd>lua vim.lsp.buf.hover()<CR>")
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    f_keymap("<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>u", "<cmd>lua vim.lsp.buf.references()<CR>", opts) fkmap(bufnr, "n", "<A-cr>", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
    -- fkmap(bufnr, "n", "<leader>dj", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
    -- fkmap(bufnr, "n", "<leader>dk", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
    -- fkmap(bufnr, "n", "gl", '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    -- fkmap(bufnr, "n", "<leader>dq", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
    vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
end

return M
