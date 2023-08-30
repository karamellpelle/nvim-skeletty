--------------------------------------------------------------------------------
--  this code is based on code from dcampos/nvim-snippy (templates)
--

utils = require("skeletty.utils")


-- export data
local M = {}


--------------------------------------------------------------------------------
--  Config
--      enabled            :: Bool                               -- ^ toggle Skeletty
--      dirs               :: Maybe( [FilePath] | CSV-String )   -- ^ list of directories with .snippet files, otherwise
--                                                               --   look at runtimepath for 'skeletons/' folders 
--      override           :: Bool                               -- ^ override hiercially if same template name and tag
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
    localdir_exclusive = false
}

-- | init M.config from default values 
M.config = vim.tbl_extend( "force", {}, default_config )


--------------------------------------------------------------------------------
-- | write parameters directly or modified into M.config 
--   TODO: make sure we don't write 'nil' to wrong fields
--   TODO: make 'M.config' local
--
local function set_config(params)

    -- make sure we have a dictionary
    vim.validate({ params = { params, 'table' }, })

    -- update 'params.dirs' as a list of valid directories
    -- 'param.dirs' can be a CSV string
    if params.dirs then
        local dirs = params.dirs
        local dir_list = type(dirs) == 'table' and dirs or vim.split(dirs, ',')
        for k, dir in ipairs(dir_list) do
            local dir_expanded = vim.fn.expand( dir )

            if vim.fn.isdirectory( dir_expanded ) == 0 then
                vim.notify( 'Skeletty: skeleton_dir = ' .. dir_expanded .. " does not exists", vim.log.levels.WARN )
            end
            -- warn if skeleton folder inside given folder
            if vim.fn.isdirectory( dir_expanded .. '/skeletons') == 1 then
                vim.notify( 'Skeletty: skeleton_dir = ' .. dir_expanded .. " contains a 'skeletons' child folder which will be ignored", vim.log.levels.WARN )
            end

            dir_list[k] = dir_expanded
        end

        params.dirs = dir_list
    end

    -- insert updated and original values directly into config
    M.config = vim.tbl_extend( "force", M.config, params )
end




--------------------------------------------------------------------------------
--| FilePath -> IO SkeletonItem
--
--   SkeletonItem
--      filepath  :: FilePath                               -- ^ file
--      scope     :: String ( local | user | runtimepath )  -- ^ scope
--      name      :: String (assert name == ft)             -- ^ name (i.e. filetype)
--      tag       :: Maybe String                           -- ^ tag name
--      home      :: FilePath                               -- ^ location of file
--      overrides :: UInt                                   -- ^ number of overrides from higher priority items
--
local function wrap_filepath(ft, filepath)

    local ret = { 
        filepath = filepath
      , scope = ''
      , home = ''
      , name = ''
      , tag = ''
      , overrides = 0
    }

    -- non-tagged skeleton file?
    local regexA = [[(.*)]] ..  [[(]] .. ft .. [[)]] .. [[\.]] .. [[(snippet)]] .. [[$]]
    --               home               name                          ext

    local home, name, ext = utils.regex_pick( filepath, regexA )     
    if home and name and ext then
        ret.name = name
        ret.home = home
        return ret
    end

    -- tagged?
    regexBC = [[(.*)]] .. [[(]] .. ft .. [[)]] .. [[(/|-)]] .. [[(\w+)]] .. [[\.]] .. [[(snippet)]] .. [[$]]
    --          home              name              / or -        tag                       ext 
    
    local home, name, sep, tag, ext = utils.regex_pick( filepath, regexBC )
    if home and name and sep and tag and ext then
        ret.home = home
        ret.name = name
        ret.tag  = tag
        return ret
    end

    vim.notify( "Could not match filepath " .. filepath, vim.log.levels.ERROR )
    return ret
end




--------------------------------------------------------------------------------
-- | append all skeleton files inside given directories
--   metadata added: filepath, name, tag
--
local function skeletons_append_dirs(skeletons, ft, dirs, sub, meta)

    -- flatten table into comma separated list and convert to fullpath from globs
    local paths = table.concat( dirs, ',' )
    for k, expr in ipairs({
        sub .. ft .. '.snippet',     -- [filetype]
        sub .. ft .. '-*.snippet',   -- [filetype]-[tag]
        sub .. ft .. '/*.snippet',   -- [filetype]/[tag]
    }) do
        -- add all files matching globs above, for each directory in 'paths' (comma separated)
        -- TODO: find if this is depth first or something to know the priority of items
        local items = vim.fn.globpath( paths, expr, false, true)

        -- convert filepath to skeleton item 
        utils.forM( items, 
            function(fpath)
                return vim.tbl_extend( 'force', wrap_filepath( ft, fpath ), meta )
            end
        )

        -- add items to the end (lower priority)
        vim.list_extend( skeletons.items, items )
      end

end



--------------------------------------------------------------------------------
-- | returns expanded local folder (relative to project, if 'localdir_project' is true)
--
local function expand_localdir(localdir)

    if not localdir or localdir == "" then return nil end

    -- shall we use project folder as parent folder for 'localdir'?
    if M.config.localdir_project == true then

        local project_dir = vim.fn.finddir( '.git/..', vim.fn.fnamemodify( vim.fn.getcwd(), ':p:h' ) .. ';' )
        return project_dir .. '/' .. localdir
    else

        return vim.fn.fnamemodify( localdir, ':p' )
    end
end




--------------------------------------------------------------------------------
-- | count overrides (and remove them if M.config.override)
--
local function skeletons_overrides( skeletons )

    local len = #skeletons.items
    for i, a in ipairs( skeletons.items ) do

        local item_i = a

        local j = i + 1
        while j ~= len + 1 do

            local item_j = skeletons.items[ j ]

            -- equals item with lower priorty?
            if item_i.name == item_j.name and item_i.tag == item_j.tag then

                -- increase override of item with lower priority
                skeletons.items[ j ].overrides = skeletons.items[ j ].overrides + 1
            end
            
            j = j + 1
        end

    end

    -- remove overrides
    skeletons.ignores = 0
    if M.config.override == true then

        local i = 0
        local len= #skeletons.items
        while i ~= len do

            if skeletons.items[ (i + 1) ].overrides ~= 0 then

                -- shift elements down
                local j = i
                while j + 1 ~= len do

                    skeletons.items[ (j + 1) ] = skeletons.items[ (j + 1 ) + 1 ]

                    j = j + 1
                end

                -- erase last element (nil-terminated list) 
                skeletons.items[ (j + 1) ] = nil

                skeletons.ignores = skeletons.ignores + 1

                len = len - 1
            else

                i = i + 1
            end
        end
    end

end



--------------------------------------------------------------------------------
-- | find_skeletons() :: IO Skeletons
--
--   find skeleton files from filetype of current buffer
--
--   Skeletons
--      name      :: String             -- ^ name of this collection
--      kind      :: String             -- ^ kind (hint for UI)
--      items     :: [SkeletonItem]     -- ^ set of SkeletonItem's
--      ignores   :: UInt               -- ^ number of overridden skeleton files
--      exclusive :: Bool               -- ^ did we exclude non-local skeletons?
--
local function find_skeletons()

    local ret = {}

    -- metadata
    ret.name = ""
    ret.kind = "skeleton"
    ret.items = {}
    ret.ignores = 0
    ret.exclusive = M.config.localdir_exclusive

    -- filetype of current buffer:
    local filetype = vim.bo.ft
    if not filetype or filetype == '' then return ret end

    ret.name = filetype

    -- priority A (local skeletons):
    -- add local directory and expand to full path,
    -- relative to current folder, or project folder if 'localdir_project'
    local localdir = expand_localdir( M.config.localdir )
    if localdir then

      if vim.fn.isdirectory( localdir ) then

          skeletons_append_dirs( ret, filetype, { localdir }, "", { scope = 'local' } )
      else

          vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
      end
    end

    -- priority B (user skeletons) or C (runtimepath skeletons)
    if M.config.localdir_exclusive == false or #ret.items == 0 then

        -- turned out we aren't exclusive at all
        ret.exclusive = false

        -- override runtime path if 'dirs' is non-empty
        local dirs = M.config.dirs
        if dirs and #dirs ~= 0 then 

            skeletons_append_dirs( ret, filetype, dirs, "", { scope = 'user' } )
        else

            local dirs = vim.split( vim.o.rtp, '\n' )
            skeletons_append_dirs( ret, filetype, dirs, "skeletons/", { scope = 'runtimepath' })
        end
    end

    -- compute overrides (and remove if 'M.config.override) 
    skeletons_overrides( ret )

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
        
        -- name
        line = "(default)"
    else
        -- name
        line = item.tag
    end

    -- show overrides
    line = line .. " " .. string.rep( "*", item.overrides )

    -- add column with [L] for local skeletons
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
local function select_skeleton( skeletons )

    -- show menu
    local formatter = format_select_item
    local kinder = skeletons.kind
    local prompter = "Select " .. skeletons.name .. " Skeleton"
                     if skeletons.ignores ~= 0 then prompter = prompter .. " (hiding " .. skeletons.ignores .. " by override)" end
                     if skeletons.exclusive then prompter = prompter .. " (LOCALDIR EXCLUSIVE)" end

    local opts = { prompt = prompter, format_item = formatter, kind = kinder }
    
    -- select skeleton or cancel
    vim.ui.select( skeletons.items, opts, function( item, ix ) 

            if item then expand_skeleton( item.filepath ) end 
        end)

end
 
--------------------------------------------------------------------------------
-- | handle new buffer
--
local function expand()


    if M.config.enabled then

        local skeletons = find_skeletons()

        if #skeletons.items ~= 0 then

            -- select between candidates and expand skeleton into new buffer
            select_skeleton( skeletons )
        end
    end
end





--------------------------------------------------------------------------------
--  tmp
local tele = require("skeletty.telescope")

function test_telescope()
    local opts = {}
    local skeletons = find_skeletons()
    print( "skeletons: ", #skeletons  )
    tele.skeletty_telescope_pick( opts,
        skeletons.items
        --{ { "hei", "coco" }, { "what", "0x4453" }, { "skeleton", "shekelg" } }
          )

end

test_telescope()


--------------------------------------------------------------------------------
--  module skeletty where

M.expand = expand
M.setup = function(o) set_config( o ) end

return M



