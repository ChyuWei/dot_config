local options = {
    -- 展示相关
    termguicolors = true,
    cursorline = true,
    cursorcolumn = true,
    ruler = true,

    number = true,
    relativenumber = false,
    -- numberwidth = 4, -- default 4
    signcolumn = "yes", 
    wrap = false,

    -- 编辑
    mouse = "a",
    shiftwidth = 4,
    tabstop = 4,
    expandtab = true,
    smarttab = true,
    smartindent = true,
    
    -- 中间文件
    backup = false, 
    writebackup = false,
    swapfile = false, 
    undofile = true,

    -- 其他
    smartcase = true,
    fileencoding = "utf-8",
}

for k, v in pairs(options) do 
    vim.o[k] = v
end
