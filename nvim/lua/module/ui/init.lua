local util = require('util')

local M = {}

M.pkg = {
    "folke/tokyonight.nvim",
    "kyazdani42/nvim-web-devicons",
    'lukas-reineke/indent-blankline.nvim',
    {
        'akinsho/bufferline.nvim',
        tag = "v2.*"
    },
    'nvim-lualine/lualine.nvim',

    'kyazdani42/nvim-tree.lua',
    'nvim-telescope/telescope.nvim',
--    use "rcarriga/nvim-notify",
}

function M.setup()
    require('indent_blankline').setup({})

    require('nvim-autopairs').setup({})
    require('Comment').setup()
    require('bufferline').setup({})
    require('lualine').setup({
        options = {
            theme = 'ayu_mirage',
        },
    })
    require('nvim-tree').setup({})
    require('telescope').setup({})

    vim.cmd[[colorscheme tokyonight]]
    M.keymap()
end

function M.keymap()
    -- bufferline
    util.keymap('n', '<leader>bn', ':BufferLineCycleNext<CR>')
    util.keymap('n', '<leader>bp', ':BufferLineCyclePrev<CR>')
    util.keymap('n', '<leader>bs', ':BufferLineSortByDirectory<CR>')
    util.keymap('n', '<leader>1', ':BufferLineGoToBuffer 1<CR>')
    util.keymap('n', '<leader>2', ':BufferLineGoToBuffer 2<CR>')
    util.keymap('n', '<leader>3', ':BufferLineGoToBuffer 3<CR>')

    -- nvimtree
    util.keymap('n', '<leader>tt', ':NvimTreeToggle<CR>')
    util.keymap('n', '<leader>tr', ':NvimTreeRefresh<CR>')

    -- telescope
    util.keymap('n', '<leader>ff', ':Telescope find_files<CR>')
    util.keymap('n', '<leader>fb', ':Telescope buffers<CR>')
    util.keymap('n', '<leader>fs', ':Telescope grep_string<CR>')
end

return M
