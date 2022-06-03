local fn, uv, api = vim.fn, vim.loop, vim.api

local packer_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
local packer = nil

function ensure_packer() 
    local empty = fn.empty(fn.glob(packer_path))
    if empty > 0 then 
        local cmd = "!git clone --depth 1 https://github.com/wbthomason/packer.nvim " .. packer_path
        api.nvim_command(cmd)
    end
end

function load_packer()
    ensure_packer()
    api.nvim_command("packadd packer.nvim")
    packer = require("packer")
end

load_packer()

return packer