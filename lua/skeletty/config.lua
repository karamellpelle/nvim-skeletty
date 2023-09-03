utils = require("skeletty.utils")

-- export data
local M = {}


--------------------------------------------------------------------------------
-- Config
--      enabled            :: Bool                               -- ^ toggle Skeletty (AutoCmd: apply skeleton (from filetype) upon new buffer)
--      dirs               :: Maybe( [FilePath] | CSV-String )   -- ^ list of directories with .snippet files, otherwise
--                                                               --   look at runtimepath for 'skeletons/' folders 
--      override           :: Bool                               -- ^ override hiercially if same template filetype and tag
--      localdir           :: Maybe FilePath                     -- ^ directory path relative to current
--      localdir_project   :: Bool                               -- ^ localdir is relative to parent VCS project (i.e. git)
--      localdir_exclusive :: Bool                               -- ^ only use localdir if there are skeletons there 
--
-- | default configuration
local default_config = {
    enabled            = true,
    dirs               = nil,
    override           = false,
    localdir           = ".skeletons",
    localdir_project   = false,
    localdir_exclusive = false,
}


M.settings = vim.tbl_extend( "force", {}, default_config )


--------------------------------------------------------------------------------
-- | write parameters directly or modified into settings 
--   TODO: make sure we don't write 'nil' to wrong fields
local function set(params)

    -- make sure we have a dictionary
    vim.validate({ params = { params, "table" }, })

    -- update 'params.dirs' as a list of valid directories
    -- 'param.dirs' can be a CSV string
    if params.dirs then
        local dirs = params.dirs
        local dir_list = type(dirs) == "table" and dirs or vim.split(dirs, ',')
        for k, dir in ipairs(dir_list) do
            local dir_expanded = vim.fn.expand( dir )

            if vim.fn.isdirectory( dir_expanded ) == 0 then
                vim.notify( 'Skeletty: skeleton_dir = ' .. dir_expanded .. " does not exists", vim.log.levels.WARN )
            end
            -- warn if skeleton folder inside given folder
            if vim.fn.isdirectory( dir_expanded .. '/skeletonset') == 1 then
                vim.notify( "Skeletty: skeleton_dir = " .. dir_expanded .. " contains a \"skeletons\" child folder which will be ignored", vim.log.levels.WARN )
            end

            dir_list[k] = dir_expanded
        end

        params.dirs = dir_list
    end

    -- insert updated and original values directly into config
    M.settings = vim.tbl_extend( "force", M.settings, params )

end




--------------------------------------------------------------------------------
--  module skeletty where

M.set = set

M.get = function() return M.settings end

return M



