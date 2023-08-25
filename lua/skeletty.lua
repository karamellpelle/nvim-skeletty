--------------------------------------------------------------------------------
--  NOTES:
--
-- * how to concatenate two tables: for k,v in pairs(second_table) do first_table[k] = v end FIXME??
-- * how to concatenate two lists:  for k,v in ipairs(second_table) do table.insert(first_table, second_table[k] ) FIXME??


--------------------------------------------------------------------------------
--  

-- export data
local M = {}

-- default configuration
local default_config = {
    enabled = true,           -- ^ toggle Skeletty                                            :: Bool 
    dirs = nil,               -- ^ list of directories with .snippet files, otherwise     :: [String] | CSV-String
                              --   look at runtimepath for 'skeletons/' folders 
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

-- | append all skeleton files inside given directories
--    TODO: add metadata like local, override, etc
local function skeletons_append_dirs(skeletons, ft, dirs, sub)

    ---- flatten table into comma separated list
--print(" ")
--print( "skeletons_append_dirs() "  )
--print( "    type(dirs): " .. type(dirs) )
--print( "    length:     " ..#dirs )

--for _, expr in ipairs( dirs ) do print( expr .. ": " .. type( expr ) ) end

    local paths = table.concat( dirs, ',' )
    for _, expr in ipairs({
        sub .. ft .. '.snippet',     -- [filetype]
        sub .. ft .. '-*.snippet',   -- [filetype]-[tag]
        sub .. ft .. '/*.snippet',   -- [filetype]/[tag]
    }) do
        -- add all files matching globs above, for each directory in 'paths' (comma separated)
        local globbed_files = vim.fn.globpath( paths, expr, false, true)
--print("globbel files")
--for _, expr in ipairs( globbed_files ) do print( expr .. ": " .. type( expr ) ) end

        vim.list_extend( skeletons, globbed_files )
    end

    print(" ")
end

-- | returns expanded local folder (relative to project, if 'localdir_project' is true
local function expand_localdir(localdir)
    if not localdir then return nil end

    -- shall we use project folder as parent folder for 'localdir'?
    if M.config.localdir_project == true then
print("expand localdir project")
        local project_dir = vim.fn.finddir( '.git/..', vim.fn.fnamemodify( vim.fn.getcwd(), ':p:h' ) .. ';' )
        return project_dir .. '/' .. localdir

    else
print("expand localdir: no project")
        return vim.fn.fnamemodify( localdir, ':p' )
    end
end

-- [ crate item with metadata
local function unwrap_filepath( filepath )

    --vim.fn.fnamemodify(filepath, "") use regex
    local filepath

    return { filepath, filetype, tag }
end

-- | find skeleton files from filetype of current buffer
--   TODO: add metadata:
--      - file path
--      - file type (name)
--      - tag
--      - local|global|rtp
--      { path = xx, type = ft, tag = "custom", scope = 'local' } 
local function list_skeletons()

    -- filetype of current buffer:
    local ft = vim.bo.ft
    if not ft or ft == '' then return {} end

    local skeletons = {}

    -- ignore global files if 'auto' is set
    if not M.config.auto or M.config.auto == false then

        -- override runtime path if 'dirs' is non-empty
        local dirs = M.config.dirs
        if dirs and #dirs ~= 0 then 

            skeletons_append_dirs( skeletons, ft, dirs, "")
        else
            local dirs = vim.split( vim.o.rtp, '\n' )
            skeletons_append_dirs( skeletons, ft, dirs, "skeletons/")
        end
    end

    -- add local directory and expand to full path .
    -- relative to current folder, or project folder if 'localdir_project'
    local localdir = expand_localdir( M.config.localdir )
    if localdir then
      if vim.fn.isdirectory( localdir ) then
          skeletons_append_dirs( skeletons, ft, { localdir }, "" )
      else
          vim.notify( 'Skeletty: localdir ' .. localdir .. 'is not a valid directory', vim.log.levels.WARN )
      end
    end

    return skeletons
end



-- | use snippy to insert skeleton and populate snippet fields
--   TODO: use a map with properties, not just 'tpl_file'
local function expand_skeleton(tpl_file)
print(" ")
print("expand_skeleton")
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

    return snippy.expand_snippet(snip, '')
end


-- | select skeleton from menu 
--   TODO:
--   * use map with properties, like name, local
--   * use 'auto'
local function select_skeleton( skeletons )

    -- show menu
    local prompter = "Select skeleton: "
    local formatter = function(item) return "Skeleton: " .. item end
    local kinder = 'string'
    local opts = { prompt = prompter, format_item = formatter, kind = kinder }

    vim.ui.select( skeletons, opts, function( selected ) if selected then expand_skeleton( selected ) end end )
end
 

-- | expand current buffer
local function expand()

    -- only expand if enabled
    if M.config.enabled then
      local skeletons = list_skeletons()

      if #skeletons ~= 0 then

          -- select between candidates and expand skeleton
          local selection = select_skeleton( skeletons )
          if selection then
              expand_skeleton( selected )
          end
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
