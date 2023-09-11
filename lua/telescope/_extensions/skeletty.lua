local find = require("skeletty.find")
local skeletty_telescope = require("skeletty.telescope")


-- | apply skeleton to current buffer
local function apply_(opts, scope, filetype)

    opts = opts or {  }
    
    if not filetype or filetype == "" then
         
        filetype = vim.bo.filetype
    end

    -- if we do not have a filetype at all (i.e. a new, unwritten buffer), choose
    -- between all skeletosn
    if filetype == "" then filetype = nil end

    skeletonset = find.skeletons( scope, filetype )

    if #skeletonset.skeletons ~= 0 then

        opts.prompt_title = opts.prompt_title or "Append skeleton"

        skeletty_telescope.make_skeletty_picker( opts, skeletonset )
    end

end

local function apply(opts, filetype)

    -- TODO: retrieve arg from Telescope command line
    filetype = "*"

    -- look in every directory
    local scope = { localdir = true, userdir = true, runtimepath = true }
    apply_( opts, scope, filetype )
end


-- | apply skeleton to new buffer
local function new(opts)

    opts = opts or {  }

    -- is current buffer empty?
    local lines = vim.fn.getline(1, "$")
    local is_empty = #lines <= 1 and lines[ 1 ] == "" or false

    if not is_empty then 

        vim.cmd.tabnew()
    end
    
    opts.prompt_title = "New file from"

    apply_( opts, nil, nil )
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
        -- default command
        skeletty = new,

        -- apply on empty buffer
        new = new,

        -- apply on current buffer
        apply = apply, 


    },
}

