local M = {}

M.packer = require('core/packer')
M.pkg = {
}

M.module = {}

function M.add_module(m)
    table.insert(M.module, m)

    for _, p in pairs(m.pkg) do
        table.insert(M.pkg, p)
    end
end

function M.setup()
    M.packer.startup(function ()
        for _, p in pairs(M.pkg) do
            use(p)
        end
    end)

    for _, m in pairs(M.module) do
        m.setup()
    end
end

return M
