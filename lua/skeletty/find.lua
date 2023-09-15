utils = require("skeletty.utils")
config = require("skeletty.config")


-- export data
local M = {}


--------------------------------------------------------------------------------
--| FilePath -> FilePath -> IO Skeleton
--
--   Skeleton
--      filepath  :: FilePath                               -- ^ file
--      scope     :: String ( local | user | runtimepath )  -- ^ scope
--      filetype  :: String              -- ^ filetype 
--      tag       :: Maybe String                           -- ^ filetype tag 
--      home      :: FilePath                               -- ^ location of file
--      overrides :: UInt                                   -- ^ number of overrides from higher priority skeletons
--
-- TODO: return nil if error
local function wrap_filepath(dir, ft, filepath)

    local skeleton = { 
        filepath = filepath
      , scope = ""
      , home = dir
      , filetype = ""
      , tag = ""
      , overrides = 0
    }
  
    if ft == "" or ft == "*" or ft == nil then
        ft = "[A-Za-z0-9_]+"
    end
   
    -- remove trailing /
    dir = string.gsub( dir, [[%/$]], [[]] )

    -- escape punktuation characters
    dir = string.gsub( dir, "%p", "%%%1" )

    -- non-tagged skeleton file?
    local regexA = dir .. "/" ..  "(" .. ft .. ")" .. "%.snippet$"
    --             home                      filetype            ext

    local filetype = string.match( filepath, regexA )
    if filetype then
        skeleton.filetype = filetype

        return skeleton
    end

    -- tagged?
    regexBC = dir .. "/" .. "(" .. ft .. ")" .. "[%-/]" .. "([A-Za-z0-9_]+)" .. "%.snippet$"
    --        home                       filetype         / or -          tag                 ext 
  
    local filetype, tag = string.match( filepath, regexBC )
    if filetype and tag then
        skeleton.filetype = filetype
        skeleton.tag  = tag

        return skeleton
    end
    vim.notify( "Could not match filepath " .. filepath, vim.log.levels.ERROR )
    skeleton.filetype = "ERROR"
    skeleton.tag = "REGEX"
utils.debug("wrap_filepath: dir ", dir)
utils.debug("wrap_filepath: filepath ", filepath)
utils.debug("wrap_filepath: regexA ", regexA)
utils.debug("wrap_filepath: regexBC ", regexBC)
utils.debug("wrap_filepath: ret ", skeleton)
    return skeleton

end




--------------------------------------------------------------------------------
-- | append all skeleton files inside given directories
--   metadata added: filepath, filetype, tag
--
local function skeletonset_append_dirs(skeletonset, ft, dirs, sub, meta)

    -- flatten table into comma separated list and convert to fullpath from globs
    for _, dir in ipairs( dirs ) do

        for _, expr in ipairs( {

            ft .. '.snippet',     -- [filetype]
            ft .. '-*.snippet',   -- [filetype]-[tag]
            ft .. '/*.snippet',   -- [filetype]/[tag]
        }) do

            -- add all files matching globs above, for each directory in 'dirs' 
            local skeletons = vim.fn.globpath( dir .. sub, expr, false, true)

            -- convert filepath to skeleton item 
            -- TODO: custom loop and compare nil from wrap_filepath
            utils.forM( skeletons, 
                function(fpath)
                    return vim.tbl_extend( "force", wrap_filepath( dir, ft, fpath ), meta )
                end
            )

            -- add skeletons to the end (lower priority)
            vim.list_extend( skeletonset.skeletons, skeletons )
        end
    end
end



--------------------------------------------------------------------------------
-- | returns expanded local folder (relative to project, if 'localdir_project' is true)
--
local function expand_localdir(localdir)

    if not localdir or localdir == "" then return nil end

    -- shall we use project folder as parent folder for 'localdir'?
    if config.get().localdir_project == true then

        local project_dir = vim.fn.finddir( '.git/..', vim.fn.fnamemodify( vim.fn.getcwd(), ':p:h' ) .. ';' )
        return project_dir .. '/' .. localdir
    else

        return vim.fn.fnamemodify( localdir, ':p' )
    end
end




--------------------------------------------------------------------------------
-- | count overrides (and remove them if config.get().override)
--
local function skeletonset_overrides( skeletonset, remove )

    local len = #skeletonset.skeletons
    for i, a in ipairs( skeletonset.skeletons ) do

        local item_i = a

        local j = i + 1
        while j ~= len + 1 do

            local item_j = skeletonset.skeletons[ j ]

            -- equals item with lower priorty?
            if item_i.filetype == item_j.filetype and item_i.tag == item_j.tag then

                -- increase override of item with lower priority
                skeletonset.skeletons[ j ].overrides = skeletonset.skeletons[ j ].overrides + 1
            end
            
            j = j + 1
        end

    end

    -- remove overrides
    skeletonset.ignores = 0
    if remove then 

        local i = 0
        local len= #skeletonset.skeletons
        while i ~= len do

            if skeletonset.skeletons[ (i + 1) ].overrides ~= 0 then

                -- shift elements down
                local j = i
                while j + 1 ~= len do

                    skeletonset.skeletons[ (j + 1) ] = skeletonset.skeletons[ (j + 1 ) + 1 ]

                    j = j + 1
                end

                -- erase last element (nil-terminated list) 
                skeletonset.skeletons[ (j + 1) ] = nil

                skeletonset.ignores = skeletonset.ignores + 1

                len = len - 1
            else

                i = i + 1
            end
        end
    end

end



--------------------------------------------------------------------------------
-- | find_skeletons() :: Maybe Scope -> Maybe FileType -> IO SkeletonSet
--
--   find skeleton files from filetype of current buffer
--
--   SkeletonSet
--      name      :: String             -- ^ name of this collection
--      skeletons :: [Skeleton]         -- ^ set of Skeleton's
--      ignores   :: UInt               -- ^ number of overridden skeleton files
--      exclusive :: Bool               -- ^ did we exclude non-local skeletonset?
--
local function find_skeletons(scope, filetype)

    local skeletonset = {}

    -- metadata
    skeletonset.name = ""
    skeletonset.skeletons = {}
    skeletonset.ignores = 0
    skeletonset.exclusive = config.get().localdir_exclusive

       
    -- filetype: either specific, or all if 'nil'
    local filetype = filetype or "*"

    skeletonset.name = filetype

    -- if scope is defined, we are we specific about scope 
    local use_config = not scope

    -- scope: either specific, or, if 'nil', depend on config setting
    --local scope = scope or { localdir = nil, userdir = nil, runtimepath = nil }
    --local scope = scope or { localdir = true, userdir = nil, runtimepath = nil }


    -- priority A (local skeletons):
    local find_localdir = use_config or scope.localdir == true
    local has_localdir = false
    if find_localdir then

        -- add local directory and expand to full path,
        -- relative to current folder, or project folder if 'localdir_project'
        local localdir = expand_localdir( config.get().localdir )
        if localdir then

          if vim.fn.isdirectory( localdir ) then

              has_localdir = true
              skeletonset_append_dirs( skeletonset, filetype, { localdir }, "", { scope = "localdir" } )
          else

              vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
          end
        end
    end

    -- scope: if specific (userdir og runtimepath), otherwise look at config

    -- config: priority B (userdir skeletons) or C (runtimepath skeletons)
    if use_config then

        if config.get().localdir_exclusive == false then

            -- turned out we aren't exclusive at all
            skeletonset.exclusive = false

            local dirs = config.get().dirs
            if dirs and #dirs ~= 0 then 

                skeletonset_append_dirs( skeletonset, filetype, dirs, "", { scope = "userdir" } )
            else

                local dirs = vim.split( vim.o.rtp, "," )

                skeletonset_append_dirs( skeletonset, filetype, dirs, "skeletons/", { scope = "runtimepath" })
            end
        end 

    else

        skeletonset.exclusive = false

        if scope.userdir == true then
            
            local dirs = config.get().dirs
            if dirs and #dirs ~= 0 then 
                skeletonset_append_dirs( skeletonset, filetype, dirs, "", { scope = "userdir" } )
            end
        end

        if scope.runtimepath == true then

            local dirs = vim.split( vim.o.rtp, "," )
            skeletonset_append_dirs( skeletonset, filetype, dirs, "skeletons/", { scope = "runtimepath" })
        end
    end


    -- compute overrides (and remove if 'config.get().override) 
    local remove = use_config and config.get().override == true 
    skeletonset_overrides( skeletonset, remove )

    return skeletonset
end





--------------------------------------------------------------------------------
--  module skeletty where

M.skeletons = find_skeletons

return M



