--------------------------------------------------------------------------------
--  NOTES:
--
-- * how to concatenate two tables: for k,v in pairs(second_table) do first_table[k] = v end FIXME??
-- * how to concatenate two lists:  for k,v in ipairs(second_table) do table.insert(first_table, second_table[k] ) FIXME??


--------------------------------------------------------------------------------
--  

utils = require("skeletty.utils")

utils.debug("testing debugger->")
utils.debug("OK?\n")
--utils.debug("testing a table: \n", { 2, 3, 5, { spider = 45, owl = "green" }, 2, { cat = { a = 1, b = 2, c = 3 }, dog = "secret" }, 4, 3 })

-- export data
local M = {}


--------------------------------------------------------------------------------
--  Config
--      enabled           :: Bool                               -- ^ toggle Skeletty
--      dirs              :: Maybe( [FilePath] | CSV-String )   -- ^ list of directories with .snippet files, otherwise
--                                                              --   look at runtimepath for 'skeletons/' folders 
--      localdir          :: Maybe FilePath                     -- ^ directory path relative to current
--      localdir_project  :: Bool                               -- ^ localdir is relative to parent VCS project (i.e. git)
--      override          :: Bool                               -- ^ override hiercially if same template name and tag
--      auto              :: Bool                               -- ^ pick automatically a skeleton from localdir for every 
                                                                --   new file. always ignore other files. if no <ft>.snippet, 
                                                                --   choose between tagged <ft>-<tag>.snippet
-- default configuration
local default_config = {
    enabled = true,           
    dirs = nil,              
    localdir = '.skeletons',
    localdir_project = false,
    override = false,      
    auto = false            
}

-- | init M.config from default values 
M.config = vim.tbl_extend('force', {}, default_config)


--------------------------------------------------------------------------------
--  

-- | write parameters directly or modified into M.config 
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
    M.config = vim.tbl_extend('force', M.config, params)
end


--| for filepath element, convert to SkeletonItem
--   SkeletonItem
--      filepath  :: FilePath                               -- ^ file
--      scope     :: String ( local | user | runtimepath )  -- ^ scope
--      name      :: String (assert name == ft)             -- ^ name (i.e. filetype)
--      tag       :: Maybe String                           -- ^ tag name
--      home      :: FilePath                               -- ^ location of file
--      overrides :: UInt                                   -- ^ number of overrides from higher priority items

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
--  

-- | append all skeleton files inside given directories
--   added metadata: filepath, filetype/name, tag
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
                --return { name = 'name', filetype = 'ft', tag = 'tag', scope = 'scope' }
                return vim.tbl_extend( 'force', wrap_filepath( ft, fpath ), meta )
            end
        )

        -- add items to the fromt (higher priority)
        utils.list_append_front( skeletons.items, items )
        --vim.list_extend( skeletons.items, items ) -- append to end
      end

end



-- | returns expanded local folder (relative to project, if 'localdir_project' is true
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


-- | count overrides and maybe remove them
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

                len = len - 1
            else

                i = i + 1
            end
        end
    end

end


-- | find_skeletons() :: IO Skeletons
--
--   find skeleton files from filetype of current buffer
--
--   Skeletons
--      items     :: [SkeletonItem]     -- ^ set of SkeletonItem
--      name      :: String             -- ^ name of this collection
--      kind      :: String             -- ^ kind (for UI hint)
--
local function find_skeletons()

    local ret = {}

    -- metadata
    ret.name = ""
    ret.items = {}
    ret.kind = "skeleton"

    -- filetype of current buffer:
    local filetype = vim.bo.ft
    if not filetype or filetype == '' then return ret end


    -- ignore global files if 'auto' is set
    if not M.config.auto or M.config.auto == false then

        -- override runtime path if 'dirs' is non-empty
        local dirs = M.config.dirs
        if dirs and #dirs ~= 0 then 

            skeletons_append_dirs( ret, filetype, dirs, "", { scope = 'user' } )
        else

            local dirs = vim.split( vim.o.rtp, '\n' )
            skeletons_append_dirs( ret, filetype, dirs, "ret/", { scope = 'runtimepath' })
        end
    end

    -- add local directory and expand to full path .
    -- relative to current folder, or project folder if 'localdir_project'
    local localdir = expand_localdir( M.config.localdir )
    if localdir then

      if vim.fn.isdirectory( localdir ) then

          skeletons_append_dirs( ret, filetype, { localdir }, "", { scope = 'local' } )
      else

          vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
      end
    end

    -- compute (and maybe remove if 'M.config.override) overrides
    skeletons_overrides( ret )

    -- add metadata
    ret.name = filetype

    return ret
end



-- | use snippy to insert skeleton and populate snippet fields
--   TODO: use a map with properties, not just 'tpl_file'
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
        vim.notify( 'Skeletty: could not populate from skeleton, Snippy not found', vim.log.levels.WARN )
        return
    end

    -- call Snippy! 
    return snippy.expand_snippet(snip, '')
end


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


-- | select and expand skeleton (or cancel)
local function select_skeleton( skeletons )

    -- show menu
    local formatter = format_select_item
    local kinder = skeletons.kind
    local prompter = "Select " .. skeletons.name .. " skeleton"

    local opts = { prompt = prompter, format_item = formatter, kind = kinder }
    
    -- select skeleton or cancel
    vim.ui.select( skeletons.items, opts, function( item, ix ) 

            if item then expand_skeleton( item.filepath ) end 
        end)

end
 

-- | expand current, new buffer
local function expand()

    -- only expand if enabled
    if M.config.enabled then

      local skeletons = find_skeletons()
      if #skeletons.items ~= 0 then

          -- select between candidates and expand skeleton into new buffer
          select_skeleton( skeletons )
      end
    end
end

 
--------------------------------------------------------------------------------
--  export

M.expand = expand

-- | M.setup :: function( options )
M.setup = function(o) set_config( o ) end


-- | return content of this file 
return M
