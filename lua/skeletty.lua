--------------------------------------------------------------------------------
--  this code is based on code from dcampos/nvim-snippy (templates)
--

local utils = require("skeletty.utils")
local config = require("skeletty.config")
local find = require("skeletty.find")
local apply = require("skeletty.apply")

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

local function notify_empty_skeletons( source, filetype )

    local has_filetype = filetype and filetype ~= ""
    local message = nil

    if source == "skeletty_new" then

        message = ":Skeletty : "
        if has_filetype then

            message = message .. "No skeleton found for filetype " .. filetype
        else

            message = message .. "No skeletons found at all"
        end

        if config.get().localdir_exclusive then

            message = message .. " ('localdir_exclusive' is enabled)"
        end
    end 
    if source == "skeletty_apply" then
        
        message = ":SkelettyApply : "
        if has_filetype then

            message = message .. "No skeleton found for filetype " .. filetype
        else

            message = message .. "No skeletons found at all (!)" 
        end
    end

    -- ignore source == "callback_BufNewFile" 

    if message then

        vim.notify( message, vim.log.levels.WARN )
    end
end

local function apply_( scope, filetype, source ) 

    if not filetype or filetype == "" then
         
        filetype = vim.bo.filetype
    end

    -- if we do not have a filetype at all (i.e. a new, unwritten buffer), choose
    -- between all skeletosn
    if filetype == "" then filetype = nil end

    -- search in configured directories 
    skeletonset = find.skeletons( scope, filetype )

    -- group skeletons after filetypes (each group's internal order is correct)
    local comp = function( s0, s1 )
        return s0.filetype < s1.filetype
    end
    table.sort( skeletonset.skeletons, comp )

    if #skeletonset.skeletons ~= 0 then

        if config.settings.auto_single and #skeletonset.skeletons == 1 then

            -- apply without selection prompt since we have only 1 candidate
            apply.skeleton( ix( skeletonset.skeletons, 0 ) )

        else
            -- select from skeletons, use Telescope if available
            if pcall( require, "telescope" ) and config.settings.selector_native_force ~= true then

                -- Telescope
                require("skeletty.telescope").pick_skeleton( skeletonset )
            else
                
                -- vim native
                select_skeleton( skeletonset )
            end
        end

    else

        -- notify 
        notify_empty_skeletons( source, filetype )
    end


end

-- | look in every directory for skeletons for 'filetype'
local function skeletty_apply( filetype ) 

    local scope = { localdir = true, userdir = true, runtimepath = true }
    apply_( scope, filetype, "skeletty_apply")
end


local function skeletty_apply_empty( source )
    -- is current buffer empty?
    local lines = vim.fn.getline(1, "$")
    local is_empty = #lines <= 1 and lines[ 1 ] == "" or false

    if not is_empty then 

        vim.cmd.tabnew()
    end
    
    apply_( nil, nil, source )

end

-- | append to an empty buffer
local function skeletty_new()
    
    skeletty_apply_empty( "skeletty_new" )
end

--------------------------------------------------------------------------------
--  configure


local function skeletty_setup( params )

    -- update settings
    config.set(  params  )

    local create_auto = function()

        local callback_BufNewFile = function(args)
            -- for args meaning, see :h nvim_crate_autocmd

            local filetype = vim.bo[ args.buf ].filetype

            -- we will not apply a skeleton if filetype is empty, to prevent 
            -- automatic skeleton on every new buffer
            if not filetype or filetype == "" then

                return
            end

            skeletty_apply_empty( "callback_BufNewFile" )
        end

        local group = vim.api.nvim_create_augroup("Skeletty", { clear = true })
        vim.api.nvim_create_autocmd( "BufNewFile", {
            group = group,
            pattern = '*.*',
            callback = callback_BufNewFile, 
            desc = "Apply skeleton on new buffer based on its filetype"
        })
    end


    -- enable/disable automatic skeletons for _new_ files
    if config.settings.auto == true then

        if config.get().localdir_exclusive then

            -- only add autocommand if we are inside a project with a localdir. 
            if find.localdir() then

                create_auto()
            end
        else

            create_auto()
        end

    else

        -- delete all Skeletty autocommands
        --vim.api.nvim_clear_autocmds( { group = "Skeletty" } ) -- does not work if Skeletty not existing
        vim.api.nvim_create_augroup("Skeletty", { clear = true })
    end

end

--------------------------------------------------------------------------------
--  module skeletty where

M.setup = skeletty_setup
M.apply = skeletty_apply
M.new = skeletty_new

return M



