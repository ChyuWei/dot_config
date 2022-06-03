local M = {}

M.pkg = {
    "windwp/nvim-autopairs",
    'numToStr/Comment.nvim',
    "tpope/vim-surround",

    -- 'phaazon/hop.nvim',
    -- 'andymass/vim-matchup',
}

function M.keymap()
end

function M.setup()
    require('nvim-autopairs').setup({})
    require('Comment').setup()
end

return M
