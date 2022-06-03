local util = require('util')

local M = {}

M.pkg = {
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
}

function M.setup()
    local cmp = require('cmp')
    cmp.setup({
          window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
          },
          sources = {
            { name = "path" },
            { name = "buffer" },
            { name = "calc" },
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-n>"] = cmp.mapping.select_next_item(),
            ["<C-p>"] = cmp.mapping.select_prev_item(),
            ["<C-b>"] = cmp.mapping.scroll_docs(4),
            ["<C-f>"] = cmp.mapping.scroll_docs(-4),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
          })
    })
    cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = 'buffer' }
        }
    })
    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = 'path' }
        }, {
            { name = 'cmdline' }
        })
    })
    M.keymap()
end

function M.keymap()
end

return M
