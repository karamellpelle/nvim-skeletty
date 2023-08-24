if vim.g.loaded_skeletty or vim.fn.has('nvim') ~= 1 then
  return 
end

-- FIXME: this may not work, make sure snippy _plugin_ is loaded before
if not vim.g.loaded_snippy then
  vim.notify( 'skeletty depends on snippy which is not loaded', vim.log.levels.WARN )
  return
end

local skeletty = require('skeletty')

--------------------------------------------------------------------------------
--  create commands

local command = vim.api.nvim_create_user_command

-- | disable skeletty
command('SkelettyOff', function() vim.g.skeletty_enabled = false end, {})

-- | enable skeletty
command('SkelettyOn', function() vim.g.skeletty_enabled = true end, {})

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
