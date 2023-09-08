if vim.g.loaded_skeletty or vim.fn.has('nvim') ~= 1 then
    return 
end

-- make sure we have Snippy
if not pcall( require, 'snippy' ) then
    vim.notify( 'Skeletty depends on plugin dcampos/nvim-snippy which could not be found' )
    return 
end

-- TMP: enable debug
local utils = require("skeletty.utils")
utils.start_debug()
utils.debug( "debug started!" )




--------------------------------------------------------------------------------
--  Skeletty commands

local command = vim.api.nvim_create_user_command

-- | enable skeletty
command('SkelettyAutoApplyEnable', 
    function( arg ) 

        require('skeletty').setup( { apply_auto = true } )
    end, { 

        desc = "Enable automatic skeleton application",
        nargs = 0
    }
)

-- | disable skeletty
command('SkelettyAutoApplyDisable', 
    function( arg ) 

        require('skeletty').setup( { apply_auto = false } )
    end, { 

        desc = "Disable automatic skeleton application",
        nargs = 0
    }
)


-- | enable/disable skeletty
command('SkelettyApply', 
        function(maybe_filetype) require('skeletty').apply( maybe_filetype ) end, 
        { desc = "Apply skeleton to current buffer" }
        )

--------------------------------------------------------------------------------

vim.g.loaded_skeletty = true
