utils = require("skeletty.utils")

-- export data
local M = {}

--------------------------------------------------------------------------------
-- skeleton_apply :: Skeleton -> IO ()
-- 
-- ^ use Snippy to insert skeleton and populate snippet fields
--
--local function skeleton_apply(skeleton )
--
--    local file = io.open( skeleton.filepath )
--    local text = file:read('*a')
--    text = text:gsub('\n$', '')
--    local body = vim.split(text, '\n')
--    local snip = {
--        kind = 'snipmate',
--        prefix = '',
--        description = '',
--        body = body
--    }
--
--    local ok, snippy = pcall(require, 'snippy')
--    if not ok then 
--
--        vim.notify( "Skeletty: could not apply Skeleton, Snippy not found", vim.log.levels.ERROR )
--        return
--    end
--
--    -- call Snippy! 
--    return snippy.expand_snippet( snip, "" )
--
--end


--------------------------------------------------------------------------------
--  module skeletty.apply where


M.apply = skeleton_apply

return M



