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

local function apply_( scope, filetype ) 

    if not filetype or filetype == "" then
         
        filetype = vim.bo.filetype
    end

    -- if we do not have a filetype at all (i.e. a new, unwritten buffer), choose
    -- between all skeletosn
    if filetype == "" then filetype = nil end

    -- search every directory, ignore 'localdir_exclusive' etc)
    skeletonset = find.skeletons( scope, filetype )

    if #skeletonset.skeletons ~= 0 then

        -- select from skeletons, use Telescope if available
    
        if pcall( require, "telescope" ) and config.settings.selector_native_force ~= true then

            -- Telescope
            require("skeletty.telescope").pick_skeleton( skeletonset )
        else
            
            -- vim native
            select_skeleton( skeletonset )
        end
    end
end

-- | look in every directory for 'filetype' (can be all filetypes)
local function skeletty_apply( filetype ) 

    local scope = { localdir = true, userdir = true, runtimepath = true }
    apply_( scope, filetype )
end


-- | append to an empty buffer
local function skeletty_new()
    
    -- is current buffer empty?
    local lines = vim.fn.getline(1, "$")
    local is_empty = #lines <= 1 and lines[ 1 ] == "" or false

    if not is_empty then 
        vim.cmd.tabnew()

    end
    
    apply_( nil, nil )
end

--------------------------------------------------------------------------------
--  autocmd callbacks
-- 
-- for args meaning, see :h nvim_crate_autocmd
--
--
local id_bufnewfile = nil

local function bufnewfile_callback(args)

    local filetype = vim.bo[ args.buf ].filetype

    -- we will not apply a skeleton if filetype is empty, to prevent 
    -- automatic skeleton on every new buffer
    if not filetype or filetype == "" then

        return
    end

    skeletty_apply( filetype )

end



--------------------------------------------------------------------------------
--  configure


local function skeletty_setup( params )

    config.set(  params  )

    -- enable or disable automatic application of skeletons for _new files_
    -- FIXME: only if CWD is in localdir/project if localdir_exclusive
    if config.settings.auto then

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
        if id_bufnewfile then vim.api.nvim_del_autocmd( id_bufnewfile ) end
        id_bufnewfile = nil
    end

end

--------------------------------------------------------------------------------
--  module skeletty where

M.setup = skeletty_setup
M.apply = skeletty_apply
M.new = skeletty_new

return M



