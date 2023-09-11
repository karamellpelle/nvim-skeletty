if vim.g.loaded_skeletty or vim.fn.has('nvim') ~= 1 then
    return 
end

-- make sure we have Snippy
if not pcall( require, 'snippy' ) then
    vim.notify( 'Skeletty depends on plugin dcampos/nvim-snippy which could not be found' )
    return 
end

-- TODO: disable debug
local utils = require("skeletty.utils") utils.start_debug() utils.debug( "debug started!" )


--------------------------------------------------------------------------------
--  Skeletty commands

local command = vim.api.nvim_create_user_command

-- | enable skeletty
command('SkelettyAutoEnable', 
    function( arg ) 

        require('skeletty').setup( { auto = true } )
    end, { 

        desc = "Enable automatic skeleton application",
        nargs = 0
    }
)

-- | disable skeletty
command('SkelettyAutoDisable', 
    function( arg ) 

        require('skeletty').setup( { auto = false } )
    end, { 

        desc = "Disable automatic skeleton application",
        nargs = 0
    }
)


-- | apply skeleton from given filetype (or all if *)
command('Skeletty', 
      function( arg ) 
          require('skeletty').new()

      end, { 
          desc = "Apply skeleton to empty buffer",
          nargs = 0
      }
)

-- | apply skeleton from given filetype (or all if *)
command('SkelettyApply', 
      function( arg ) 

          local filetype = arg.fargs[1]
          if filetype == "*" then filetype = nil end
          require('skeletty').apply( filetype )

      end, { 
          desc = "Apply given skeleton to current buffer",
          nargs = 1
      }
)

--------------------------------------------------------------------------------

vim.g.loaded_skeletty = true
