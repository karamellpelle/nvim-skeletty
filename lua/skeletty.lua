--------------------------------------------------------------------------------
--  this code is based on code from dcampos/nvim-snippy (templates)
--

utils = require("skeletty.utils")
config = require("skeletty.config")
find = require("skeletty.find")
apply = require("skeletty.apply")

-- export data
local M = {}



--------------------------------------------------------------------------------
-- | format item for vim.ui.select 
--
local function selecting_formatter(skeleton)

    local line = "" 

    if not skeleton.tag or skeleton.tag == "" then
        
        -- filetype
        line = "(default)"
    else
        -- filetype
        line = skeleton.tag
    end

    -- show overrides
    line = line .. " " .. string.rep( "*", skeleton.overrides )

    -- add column with [L] for local skeletonset
    line = line .. string.rep(" ", 16 - #line)
    if skeleton.scope == "localdir" then line = line .. " [L]" end

    -- show 'home'
    line = line .. string.rep(" ", 24 - #line)
    line = line .. "@ " .. skeleton.home

    return line

end



--------------------------------------------------------------------------------
-- | select and expand skeleton (or cancel)
--
local function select_skeleton( skeletonset )

    -- show menu
    local formatter = selecting_formatter
    local kinder = skeletonset.kind
    local prompter = "Select " .. skeletonset.name .. " Skeleton"
                     if skeletonset.ignores ~= 0 then prompter = prompter .. " (hiding " .. skeletonset.ignores .. " by override)" end
                     if skeletonset.exclusive then prompter = prompter .. " (LOCALDIR EXCLUSIVE)" end

    local opts = { prompt = prompter, format_item = formatter, kind = kinder }
    
    -- select skeleton or cancel
    vim.ui.select( skeletonset.skeletons, opts, function( skeleton, ix ) 

            if skeleton then apply.skeleton( skeleton ) end 
        end)

end


--------------------------------------------------------------------------------
--  autocmd callbacks
-- 
-- for args meaning, see :h nvim_crate_autocmd
--
--
local id_bufnewfile = nil

local function bufnewfile_callback(args)

--utils.debug( "bufnewfile ", args )
    local filetype = vim.bo[ args.buf ].filetype

    -- we will not run autocmd if filetype is empty, this is to prevent overloading
    -- the user for every new buffer
    if not filetype or filetype == "" then

        vim.notify( "Could not deduce filetype for " .. args.match .. ", skeleton aborted", vim.log.levels.WARN )
        return
    end

--utils.debug( "filetype ", filetype )

    -- find skeletons (using args
    skeletonset = find.skeletons( nil, filetype )

    if #skeletonset.skeletons ~= 0 then

        -- select from skeletons, use Telescope if available
        if pcall( require, "telescope" ) then

            -- Telescope
            require("skeletty.telescope").pick_skeleton( skeletonset )
        else
            
            -- vim native
            select_skeleton( skeletonset )
        end
    end

end



--------------------------------------------------------------------------------
--  configure


local function skeletty_setup( params )

    config.set(  params  )

    -- enable or disable automatic application of skeletons for _new files_
    if config.settings.enabled then

        if not id_bufnewfile then

            local group = vim.api.nvim_create_augroup("Skeletty", { clear = true })
            id_bufnewfile = vim.api.nvim_create_autocmd( "BufNewFile", {
                group = group,
                pattern = '*.*',
                callback = bufnewfile_callback, 
                desc = "Apply skeleton on new buffer based on its filetype"
            })
        end
    else

        -- delete autocommand. 
        -- TODO: deleting autocommand group is better (when we have more autocommands)
        if id_bufnewfile then nvim_del_autocmd( id_bufnewfile ) end
        id_bufnewfile = nil
    end

end

--------------------------------------------------------------------------------
--  module skeletty where

M.setup = skeletty_setup

return M



