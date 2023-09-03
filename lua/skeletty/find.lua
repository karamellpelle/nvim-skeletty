utils = require("skeletty.utils")
config = require("skeletty.config")


-- export data
local M = {}


--------------------------------------------------------------------------------
--| FilePath -> IO Skeleton
--
--   Skeleton
--      filepath  :: FilePath                               -- ^ file
--      scope     :: String ( local | user | runtimepath )  -- ^ scope
--      filetype  :: String              -- ^ filetype 
--      tag       :: Maybe String                           -- ^ filetype tag 
--      home      :: FilePath                               -- ^ location of file
--      overrides :: UInt                                   -- ^ number of overrides from higher priority skeletons
--
local function wrap_filepath(ft, filepath)

    local skeleton = { 
        filepath = filepath
      , scope = ""
      , home = ""
      , filetype = ""
      , tag = ""
      , overrides = 0
    }

    -- non-tagged skeleton file?
    local regexA = [[(.*)]] ..  [[(]] .. ft .. [[)]] .. [[\.]] .. [[(snippet)]] .. [[$]]
    --               home               filetype                          ext

    local home, filetype, ext = utils.regex_pick( filepath, regexA )     
    if home and filetype and ext then
        skeleton.filetype = filetype
        skeleton.home = home
        return skeleton
    end

    -- tagged?
    regexBC = [[(.*)]] .. [[(]] .. ft .. [[)]] .. [[(/|-)]] .. [[(\w+)]] .. [[\.]] .. [[(snippet)]] .. [[$]]
    --          home              filetype              / or -        tag                       ext 
    
    local home, filetype, sep, tag, ext = utils.regex_pick( filepath, regexBC )
    if home and filetype and sep and tag and ext then
        skeleton.home = home
        skeleton.filetype = filetype
        skeleton.tag  = tag
        return skeleton
    end

    vim.notify( "Could not match filepath " .. filepath, vim.log.levels.ERROR )
    return skeleton
end




--------------------------------------------------------------------------------
-- | append all skeleton files inside given directories
--   metadata added: filepath, filetype, tag
--
local function skeletonset_append_dirs(skeletonset, ft, dirs, sub, meta)

    -- flatten table into comma separated list and convert to fullpath from globs
    local paths = table.concat( dirs, ',' )
    for k, expr in ipairs({
        sub .. ft .. '.snippet',     -- [filetype]
        sub .. ft .. '-*.snippet',   -- [filetype]-[tag]
        sub .. ft .. '/*.snippet',   -- [filetype]/[tag]
    }) do
        -- add all files matching globs above, for each directory in 'paths' (comma separated)
        -- TODO: find search order (depth first?) to know the priority of skeletons
        local skeletons = vim.fn.globpath( paths, expr, false, true)

        -- convert filepath to skeleton item 
        utils.forM( skeletons, 
            function(fpath)
                return vim.tbl_extend( "force", wrap_filepath( ft, fpath ), meta )
            end
        )

        -- add skeletons to the end (lower priority)
        vim.list_extend( skeletonset.skeletons, skeletons )
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
-- | find_skeletons() :: IO SkeletonSet
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
    local filetype = typename or "*"

    -- if scope is defined, we are we specific about scope 
    local use_config = not scope

    -- scope: either specific, or, if 'nil', depend on config setting
    local scope = scope or { localdir = nil, userdir = nil, runtimepath = nil }

    skeletonset.name = filetype

    -- priority A (local skeletons):
    local find_localdir = use_config or scope.localdir == true
    if find_localdir then

        -- add local directory and expand to full path,
        -- relative to current folder, or project folder if 'localdir_project'
        local localdir = expand_localdir( config.get().localdir )
        if localdir then

          if vim.fn.isdirectory( localdir ) then

              skeletonset_append_dirs( skeletonset, filetype, { localdir }, "", { scope = "localdir" } )
          else

              vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
          end
        end
    end

    -- scope: if specific (userdir og runtimepath), otherwise look at config

    -- config: priority B (userdir skeletons) or C (runtimepath skeletons)
    if use_config then

        if config.get().localdir_exclusive == false or #skeletonset.skeletons == 0 then

            -- turned out we aren't exclusive at all
            skeletonset.exclusive = false

            local dirs = config.get().dirs
            if dirs and #dirs ~= 0 then 

                skeletonset_append_dirs( skeletonset, filetype, dirs, "", { scope = "userdir" } )
            else

                local dirs = vim.split( vim.o.rtp, '\n' )
                skeletonset_append_dirs( skeletonset, filetype, dirs, "skeletons/", { scope = "runtimepath" })
            end
        end 

    else

        skeletonset.exclusive = false

        if find_userdir == true then
            
            skeletonset_append_dirs( skeletonset, filetype, dirs, "", { scope = "userdir" } )
        end

        if scope.runtimepath == true then

            local dirs = vim.split( vim.o.rtp, '\n' )
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



