utils = require("skeletty.utils")

-- export data
local M = {}


--------------------------------------------------------------------------------
-- Config
--      dirs               :: Maybe( [FilePath] | CSV-String )   -- ^ list of directories with .snippet files, otherwise
--                                                               --   look at runtimepath for 'skeletons/' folders 
--      override               :: Bool                           -- ^ override hiercially if same template filetype and tag
--      localdir               :: Maybe FilePath                 -- ^ directory path relative to current
--      localdir_project       :: Bool                           -- ^ localdir is relative to parent VCS project (i.e. git)
--      localdir_exclusive     :: Bool                           -- ^ only use localdir if there are skeletons there (otherwise look at userdir or runtimepath)
--      auto                   :: Bool                           -- ^ toggle Skeletty AutoCmd: apply skeleton (from filetype) when new buffer
--      apply_at_top           :: Bool                           -- ^ apply skeleton at top line, otherwise cursor line
--      apply_syntax           :: Bool                           -- ^ apply syntax if buffer have no filetype
--      natitve_selector_force :: Bool                           -- ^ use native selector even if Telescope is available (you probably don't want this)
--      telescope              :: Telescope                      -- ^ settings for Telescope 
--
-- | default configuration
local default_config = {
    dirs               = nil,
    override           = false,
    localdir           = ".skeletons",
    localdir_project   = false,
    localdir_exclusive = false,
    auto               = false,
    auto_single        = false,
    apply_at_top       = false,
    apply_syntax       = true,

    native_selector_force = false,

    -- FIXME: take these out of "telescope' in order define display
    --        settings for native selector also?
    telescope          = {
        -- display settings. TDOD: make toogleable by mappings
        skeletty_display_path               = true,  
        skeletty_display_overrides          = true,
        skeletty_display_localdir_exclusive = false,
        skeletty_hl_group                   = "SkelettyPlaceholder"
    }
}


M.settings = vim.tbl_extend( "force", {}, default_config )


--------------------------------------------------------------------------------
-- | urite parameters directly or modified into settings 
--   TODO: make sure we don't write 'nil' to wrong fields
local function set(params)

    -- make sure we have a dictionary
    vim.validate({ params = { params, "table" }, })

    -- convert to list of expanded filepaths if 'params.dirs' is a CSV string 
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
    
    -- save telescope
    local telescope = M.settings.telescope
    local telescope_params = params.telescope or {  }
    vim.tbl_extend( "force", telescope, telescope_params )

    -- insert updated new values directly into config
    M.settings = vim.tbl_extend( "force", M.settings, params )

    -- write back telescope 
    M.settings.telescope = telescope

end




--------------------------------------------------------------------------------
--  module skeletty.config where

M.set = set

M.get = function() return M.settings end

return M



