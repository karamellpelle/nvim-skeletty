--------------------------------------------------------------------------------
--  this code is based on code from dcampos/nvim-snippy (templates)
--

utils = require("skeletty.utils")
config = require("skeletty.config")
find = require("skeletty.find")
--apply = require("skeletty.apply")

-- export data
local M = {}



--------------------------------------------------------------------------------
-- | use Snippy to insert skeleton and populate snippet fields
-- 
local function expand_skeleton(tpl_file)

    local file = io.open(tpl_file)
    local text = file:read('*a')
    text = text:gsub('\n$', "")
    local body = vim.split(text, '\n')
    local snip = {
        kind = "snipmate",
        prefix = "",
        description = "",
        body = body
    }

    local ok, snippy = pcall(require, "snippy")
    if not ok then 

        vim.notify( "Skeletty: could not expand Skeleton, Snippy not found", vim.log.levels.ERROR )
        return
    end

    -- call Snippy! 
    return snippy.expand_snippet( snip, "" )
end



--------------------------------------------------------------------------------
-- | format item for vim.ui.select 
--
local function format_select_item(item)

    local line = "" 

    if not item.tag or item.tag == "" then
        
        -- filetype
        line = "(default)"
    else
        -- filetype
        line = item.tag
    end

    -- show overrides
    line = line .. " " .. string.rep( "*", item.overrides )

    -- add column with [L] for local skeletonset
    line = line .. string.rep(" ", 16 - #line)
    if item.scope == "local" then line = line .. " [L]" end

    -- show 'home'
    line = line .. string.rep(" ", 24 - #line)
    line = line .. "@ " .. item.home

    return line

end



--------------------------------------------------------------------------------
-- | select and expand skeleton (or cancel)
--
local function select_skeleton( skeletonset )

    -- show menu
    local formatter = format_select_item
    local kinder = skeletonset.kind
    local prompter = "Select " .. skeletonset.name .. " Skeleton"
                     if skeletonset.ignores ~= 0 then prompter = prompter .. " (hiding " .. skeletonset.ignores .. " by override)" end
                     if skeletonset.exclusive then prompter = prompter .. " (LOCALDIR EXCLUSIVE)" end

    local opts = { prompt = prompter, format_item = formatter, kind = kinder }
    
    -- select skeleton or cancel
    vim.ui.select( skeletonset.skeletons, opts, function( item, ix ) 

            if item then expand_skeleton( item.filepath ) end 
            --if item then expand_skeleton( item.filepath ) end 
        end)

end
 
--------------------------------------------------------------------------------
-- | handle new buffer
--
local function expand()


    if config.get().enabled then

        local skeletonset = find.skeletons()

        if #skeletonset.skeletons ~= 0 then

            -- select between candidates and expand skeleton into new buffer
            select_skeleton( skeletonset )
        end
    end
end



--------------------------------------------------------------------------------
--  autocmd callbacks
-- 
-- for args meaning, see :h nvim_crate_autocmd
--
--
local id_bufnewfile = nil

local function bufnewfile_callback(args)

    utils.debug( "bufnewfile " .. vim.inspect( args ) )
    -- autocmd will not run if empty filetype, this is to prevent overloading
    -- the user for every new buffer
    local filetype = vim.bo[ args.buf ].filetype
    if not filetype or filetype == "" then

        vim.notify( "Could not deduce filetype for " .. args.match .. ", skeleton aborted", vim.log.levels.WARN )
        return
    end

    utils.debug( "filetype" .. vim.inspect( filetype ) )

    -- find skeletons (using args
    skeletonset = find.skeletons( nil, filetype )
    utils.debug( "skeltonset" .. vim.inspect( skeletonset ) )

    -- TODO: choose selector (native, telescope)
    --if telescope then
    --select_skeleton( skeletonset )

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
                callback = bufnewfile_callback, -- FIXME: wrap in function() as lua-guide.txt?
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
M.apply = expand

return M



