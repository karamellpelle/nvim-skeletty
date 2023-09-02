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
    text = text:gsub('\n$', '')
    local body = vim.split(text, '\n')
    local snip = {
        kind = 'snipmate',
        prefix = '',
        description = '',
        body = body
    }

    local ok, snippy = pcall(require, 'snippy')
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
    if item.scope == 'local' then line = line .. " [L]" end

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
--  module skeletty where

M.setup = config.set
M.apply = expand

return M



