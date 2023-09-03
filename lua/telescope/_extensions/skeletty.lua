local find = require("skeletty.find")
local skeletty_telescope = require("skeletty.telescope")


local function apply(opts)

    -- do we have a filetype of current buffer?
    local filetype = vim.bo.filetype
    if filetype == "" then filetype = nil end

    -- this will find all skeleton files, regardless of Skeletty config
    local scope = { localdir = true, userdir = true, runtimepath = true } 
    local skeletonset = find.skeletons( scope, filetype )

    make_skeletty_picker( opts, skeletonset )
end

local function new(opts)
    vim.cmd.tabnew()
    apply( opts )
end


return require("telescope").register_extension {

    -- see     telescope.nvim/lua/telescope/_extensions/init.lua
    setup = function(ext_config, config)
        -- 'ext_config' : Extension opts
        -- 'config'     : Telescope opts

        -- access extension config and user config
        -- (read/write)
    end,

    exports = {

        apply = apply
        -- ^ find and apply:
        --     no filetype (i.e. filename) => select * >>= apply 
        --     filename                    => select filetype >>= apply 

        new = new
        -- ^ create new buf (no filename) >>= select * >>= apply

    },
}
