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


local skeletty = require('skeletty')

local group = vim.api.nvim_create_augroup('Skeletty', {})

vim.api.nvim_create_autocmd('BufNewFile', {
    group = group,
    pattern = '*.*',
    callback = function() require 'skeletty'.expand() end
})



--------------------------------------------------------------------------------
--  Skeletty commands

local command = vim.api.nvim_create_user_command

-- | enable/disable skeletty
command('SkelettyEnable', function(b) require('skeletty').setup( { enabled = b } ) end, {})

--------------------------------------------------------------------------------

vim.g.loaded_skeletty = true
