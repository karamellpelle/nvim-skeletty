--------------------------------------------------------------------------------
--  this code is based on code from dcampos/nvim-snippy (templates)
--

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

    local ret = { 
        filepath = filepath
      , scope = ''
      , home = ''
      , filetype = ''
      , tag = ''
      , overrides = 0
    }

    -- non-tagged skeleton file?
    local regexA = [[(.*)]] ..  [[(]] .. ft .. [[)]] .. [[\.]] .. [[(snippet)]] .. [[$]]
    --               home               filetype                          ext

    local home, filetype, ext = utils.regex_pick( filepath, regexA )     
    if home and filetype and ext then
        ret.filetype = filetype
        ret.home = home
        return ret
    end

    -- tagged?
    regexBC = [[(.*)]] .. [[(]] .. ft .. [[)]] .. [[(/|-)]] .. [[(\w+)]] .. [[\.]] .. [[(snippet)]] .. [[$]]
    --          home              filetype              / or -        tag                       ext 
    
    local home, filetype, sep, tag, ext = utils.regex_pick( filepath, regexBC )
    if home and filetype and sep and tag and ext then
        ret.home = home
        ret.filetype = filetype
        ret.tag  = tag
        return ret
    end

    vim.notify( "Could not match filepath " .. filepath, vim.log.levels.ERROR )
    return ret
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
        -- TODO: find if this is depth first or something to know the priority of skeletons
        local skeletons = vim.fn.globpath( paths, expr, false, true)

        -- convert filepath to skeleton item 
        utils.forM( skeletons, 
            function(fpath)
                return vim.tbl_extend( 'force', wrap_filepath( ft, fpath ), meta )
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
local function skeletonset_overrides( skeletonset )

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
    if config.get().override == true then

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
--      kind      :: String             -- ^ kind (hint for UI)
--      skeletons :: [Skeleton]         -- ^ set of Skeleton's
--      ignores   :: UInt               -- ^ number of overridden skeleton files
--      exclusive :: Bool               -- ^ did we exclude non-local skeletonset?
--
local function find_skeletons()

    local ret = {}

    -- metadata
    ret.name = ""
    ret.kind = "skeleton"
    ret.skeletons = {}
    ret.ignores = 0
    ret.exclusive = config.get().localdir_exclusive

    -- filetype of current buffer:
    local filetype = vim.bo.ft
    if not filetype or filetype == '' then return ret end

    ret.name = filetype

    -- priority A (local skeletonset):
    -- add local directory and expand to full path,
    -- relative to current folder, or project folder if 'localdir_project'
    local localdir = expand_localdir( config.get().localdir )
    if localdir then

      if vim.fn.isdirectory( localdir ) then

          skeletonset_append_dirs( ret, filetype, { localdir }, "", { scope = 'local' } )
      else

          vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
      end
    end

    -- priority B (user skeletonset) or C (runtimepath skeletonset)
    if config.get().localdir_exclusive == false or #ret.skeletons == 0 then

        -- turned out we aren't exclusive at all
        ret.exclusive = false

        -- override runtime path if 'dirs' is non-empty
        local dirs = config.get().dirs
        if dirs and #dirs ~= 0 then 

            skeletonset_append_dirs( ret, filetype, dirs, "", { scope = 'user' } )
        else

            local dirs = vim.split( vim.o.rtp, '\n' )
            skeletonset_append_dirs( ret, filetype, dirs, "skeletonset/", { scope = 'runtimepath' })
        end
    end

    -- compute overrides (and remove if 'config.get().override) 
    skeletonset_overrides( ret )

    return ret
end



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
        end)

end
 
--------------------------------------------------------------------------------
-- | handle new buffer
--
local function expand()


    if config.get().enabled then

        local skeletonset = find_skeletons()

        if #skeletonset.skeletons ~= 0 then

            -- select between candidates and expand skeleton into new buffer
            select_skeleton( skeletonset )
        end
    end
end





--------------------------------------------------------------------------------
--  tmp
--package.preload["skeletty.telescope"] = nil
--local tele = require("skeletty.telescope")
--
--local function test_telescope()
--    local opts = {}
--    local skeletonset = find_skeletons()
--    print( "skeletonset: ", #skeletonset  )
--    tele.skeletty_telescope_pick( opts,
--        skeletonset.skeletons
--        --{ { "hei", "coco" }, { "what", "0x4453" }, { "skeleton", "shekelg" } }
--          )
--
--end
--
--
--if vim.env.TESTING  then
--    test_telescope()
--end
--

--------------------------------------------------------------------------------
--  module skeletty where

M.expand = expand
M.setup = config.set

return M



