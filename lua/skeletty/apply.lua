utils = require("skeletty.utils")
config = require("skeletty.config")

-- export data
local M = {}

--------------------------------------------------------------------------------
-- skeleton_apply :: Skeleton -> IO ()
-- 
-- ^ use Snippy to insert skeleton and populate snippet fields
-- FIXME: append at top
local function skeleton_apply(skeleton )

    -- insert above line 
    if config.get().apply_at_top == true then

        vim.cmd( "normal ggO" )
        --vim.api.nvim_win_set_cursor( 0, { 1,0 } )
    else

        vim.cmd( "normal O" )
    end

    local file = io.open( skeleton.filepath )
    local text = file:read( "*a" )
    text = text:gsub( "\n$", "" )
    local body = vim.split( text, "\n" )
    local snip = {
        kind = "snipmate",
        prefix = "",
        description = "",
        body = body
    }

    local ok, snippy = pcall( require, "snippy" )
    if not ok then 

        vim.notify( "Skeletty: could not apply skeleton, Snippy not found", vim.log.levels.ERROR )
        return
    end

    -- should we apply syntax highlight if buffer have no filetype
    if config.get().apply_syntax == true then
        
        if vim.bo.filetype == "" or not vim.bo.filetype then

            vim.api.nvim_buf_set_option( 0, "syntax", skeleton.filetype )
        end
    end

    -- call Snippy! 
    local ret =snippy.expand_snippet( snip, "" )

    -- back to normal mode
    vim.cmd( "stopinsert" ) -- FIXME: this does not work for some reason :(

    return ret

end


--------------------------------------------------------------------------------
--  module skeletty.apply where


M.skeleton = skeleton_apply

return M



