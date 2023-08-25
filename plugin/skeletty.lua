if vim.g.loaded_skeletty or vim.fn.has('nvim') ~= 1 then
  return 
end


-- make sure we have snippy
if not pcall( require, 'snippy' ) then
  vim.notify( 'skeletty depends on plugin dcampos/nvim-snippy which could not be found' )
  return 
end

local skeletty = require('skeletty')

--------------------------------------------------------------------------------
--  create commands

local command = vim.api.nvim_create_user_command

-- | disable skeletty
command('SkelettyEnable', function(b) require('skeletty').setup( { enabled = b } ) end, {})

-- | enable skeletty
command('SkelettyAuto', function(a) require('skeletty').setup( { auto = b } ) end, {})


--------------------------------------------------------------------------------
--  populate a new file using matching skeleton (if available)

local group = vim.api.nvim_create_augroup('Skeletty', {})

vim.api.nvim_create_autocmd('BufNewFile', {
    group = group,
    pattern = '*.*',
    callback = function() require 'skeletty'.expand() end
})


--------------------------------------------------------------------------------
--  

vim.g.loaded_skeletty = true
