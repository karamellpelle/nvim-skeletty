--------------------------------------------------------------------------------
--  NOTES:
--
-- * how to concatenate two tables: for k,v in pairs(second_table) do first_table[k] = v end FIXME??
-- * how to concatenate two lists:  for k,v in ipairs(second_table) do table.insert(first_table, second_table[k] ) FIXME??


--------------------------------------------------------------------------------
--  

utils = require("skeletty.utils")

utils.debug("testing debugger->")
utils.debug("is it OK?\n")
utils.debug("testing a table: \n", { 2, 3, 5, { spider = 45, owl = "green" }, 2, { cat = { a = 1, b = 2, c = 3 }, dog = "secret" }, 4, 3 })
-- export data
local M = {}

-- default configuration
local default_config = {
    enabled = true,           -- ^ toggle Skeletty                                            :: Bool 
    dirs = nil,               -- ^ list of directories with .snippet files, otherwise         :: [String] | CSV-String
                              --   look at runtimepath for 'skeletons/' folders 
    override = false,         -- ^ override hiercially if same template name and tag          :: Bool
    localdir = '.skeletons',  -- ^ directory path relative to current                         :: String
    localdir_project = false,     -- ^ localdir is relative to parent VCS project (i.e. git)  :: Bool
    auto = false              -- ^ pick automatically a skeleton from localdir for every      :: Bool
                              --   new file. always ignore other files. if no <ft>.snippet, 
                              --   choose between tagged <ft>-<tag>.snippet
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


--| for filepath element, convert to
--  { filepath, name, tag }
local function wrap_filepath(ft, filepath)
utils.debug("wrap_filepath()\n")
    local ret = { filepath = filepath, name = '', tag = '' }

    local regex = ''
    local matches = {}

    -- non tagged?
    regex = [[\(]] .. ft .. [[\)]] .. [[(\.snippet$)]]
    --               name                   ext

    matches = vim.fn.matchlist( [[\v]] .. regex, filepath ) utils.debug("no tag: ", matches)
    if #matches == 2 then

        ret.name = ix( 0, matches ) 
        return ret
    end

    -- tagged?
    regex = [[\(]] .. ft .. [[\)]] .. [[\(\/|-\)]] .. [[\(\w+\)]] .. [[\(\.snippet$\)]]
    --               name               / or -            tag                ext

    matches = vim.fn.matchlist( "\v" .. regex, filepath ) utils.debug("tagged: ", matches)
    if #matches == 4 then

        ret.name = ix( 0, matches )
        ret.tag  = ix( 2, matches ) 
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
        local items = vim.fn.globpath( paths, expr, false, true)

        -- convert filepath to skeleton item 
        utils.foreach( items, 
            function(fpath)
                --return { name = 'name', filetype = 'ft', tag = 'tag', scope = 'scope' }
                return vim.tbl_extend( 'force', wrap_filepath( ft, fpath ), meta )
            end
        )

--print(" ")
--print("type items")
--for k, expr in ipairs(items) do
--    print("type item: " .. type(expr))
--end

        -- add items to skeleton item list
        vim.list_extend( skeletons, items )
      end


--print(" ")

end



-- | returns expanded local folder (relative to project, if 'localdir_project' is true
local function expand_localdir(localdir)

    if not localdir then return nil end

    -- shall we use project folder as parent folder for 'localdir'?
    if M.config.localdir_project == true then

        local project_dir = vim.fn.finddir( '.git/..', vim.fn.fnamemodify( vim.fn.getcwd(), ':p:h' ) .. ';' )
        return project_dir .. '/' .. localdir
    else

        return vim.fn.fnamemodify( localdir, ':p' )
    end
end

-- | find skeleton files from filetype of current buffer
--   skelton item: {
--      filepath :: FilePath
--      scope    :: String ( local | user | runtimepath )
--      name     :: String (assert name == ft)
--      tag      :: Maybe String
--   }
local function find_skeletons()

    -- filetype of current buffer:
    local filetype = vim.bo.ft
    if not filetype or filetype == '' then return {} end

    local skeletons = {}

    -- ignore global files if 'auto' is set
    if not M.config.auto or M.config.auto == false then

        -- override runtime path if 'dirs' is non-empty
        local dirs = M.config.dirs
        if dirs and #dirs ~= 0 then 

            skeletons_append_dirs( skeletons, filetype, dirs, "", { scope = 'user' } )
        else
            local dirs = vim.split( vim.o.rtp, '\n' )
            skeletons_append_dirs( skeletons, filetype, dirs, "skeletons/", { scope = 'runtimepath' })
        end
    end

    -- add local directory and expand to full path .
    -- relative to current folder, or project folder if 'localdir_project'
    local localdir = expand_localdir( M.config.localdir )
    if localdir then
      if vim.fn.isdirectory( localdir ) then
          skeletons_append_dirs( skeletons, filetype, { localdir }, "", { scope = 'local' } )
      else
          vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
      end
    end

--for k, expr in ipairs(skeletons) do
--    print("type skeleton_: " .. type(expr))
--end
--
    return skeletons
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

    -- populate new buffer
    return snippy.expand_snippet(snip, '')
end


-- | select and expand skeleton (or cancel)
local function select_skeleton( skeletons )

    -- show menu
    local prompter = "Select skeleton"
    local kinder = 'skeleton_item'
    local formatter = 
    function(item) 
--print("type iten: " .. type(item))
          -- TODO: ignore name, only show tag
          local line = item.name .. " (" .. item.tag .. ") " 

          -- pad width spaces. TODO
          local width = 16 -- longest ft found was 15 letters

          if item.scope == 'local' then line = line .. "[L]" end
          return line
    end
    local opts = { prompt = prompter, format_item = formatter, kind = kinder }
    
    local on_choice =
    function( item, ix )
        if item then expand_skeleton( item.filepath ) end
    end

    -- populate from skeleton, or cancel
    vim.ui.select( skeletons, opts, on_choice )
end
 

-- | expand current, new buffer
local function expand()

    -- only expand if enabled
    if M.config.enabled then

      local skeletons = find_skeletons()
      if #skeletons ~= 0 then

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
