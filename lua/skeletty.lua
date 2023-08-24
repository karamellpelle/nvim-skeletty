-- export data
local M = {}

-- make sure skellety works by default
vim.g.skeletty_enabled = true

-- default configuration
local default_config = {
    skeleton_dirs = nil, -- ^ _list_  of directories
    local_skeleton_dir = '.skeletons', -- ^ directory path relative to current
}

-- | M.config :: Config. set to default values
M.config = vim.tbl_extend('force', {}, default_config)

-- | M.set_config :: function( parameters )
--   write parameters directly or modified into config 
local function set_config(params)
    vim.validate({ params = { params, 't' }, })

    -- update 'skeleton_dirs' as a list of valid directories
    if params.skeleton_dirs then
        local dirs = params.skeleton_dirs
        local dir_list = type(dirs) == 'table' and dirs or vim.split(dirs, ',')
        for k, dir in ipairs(dir_list) do
            local dir_expanded = vim.fn.expand( dir )

            if vim.fn.isdirectory( dir_expanded ) == 0 then
                vim.nofity( 'Skeletty: skeleton_dir = ' .. dir_expanded .. " does not exists", vim.log.levels.WARN )
            end
            -- warn if skeleton folder inside given folder
            if vim.fn.isdirectory( dir_expanded .. '/skeletons') == 1 then
                vim.nofity( 'Skeletty: skeleton_dir = ' .. dir_expanded .. " contains a 'skeletons' subfolder which will be ignored", vim.log.levels.WARN )
            end

            dir_list[k] = dir_expanded
        end

        params.skeleton_dirs = dir_list
    end

    -- insert updated and original values directly into config
    M.config = vim.tbl_extend('force', M.config, params)
end

-- | append all skeleton files inside given directories
--    TODO: add metadata like local, override, etc
local function skeletons_append_dirs(skeletons, ft, dirs, sub)

    ---- flatten table into comma separated list
    print( "dirs: " .. type(dirs) )
    print( "length: " ..#dirs )
    for _, expr in ipairs( dirs ) do
        print( expr .. ": " .. type( expr ) )
    end

    local paths = table.concat( dirs, ',' )
    for _, expr in ipairs({
        sub .. ft .. '.snippet',     -- [filetype]
        sub .. ft .. '-*.snippet',   -- [filetype]-[tag]
        sub .. ft .. '/*.snippet',   -- [filetype]/[tag]
    }) do
        -- add all files matching globs above, for each directory in 'paths' (comma separated)
        vim.list_extend( skeletons, vim.fn.globpath( paths, expr, false, true))
    end
end

-- | find skeleton files from filetype of current buffer
local function list_skeletons()
    local ft = vim.bo.ft
    if not ft or ft == '' then
        return {}
    end

    local skeletons = {}
    --concatenate: for k,v in pairs(second_table) do first_table[k] = v end

    -- override runtime path if 'skeleton_dirs' is non-empty
    local skeleton_dirs = M.config.skeleton_dirs
    if skeleton_dirs and #skeleton_dirs ~= 0 then 

        skeletons_append_dirs( skeletons, ft, skeleton_dirs, "")
    else
        local dirs = vim.split( vim.o.rtp, '\n' )
        skeletons_append_dirs( skeletons, ft, dirs, "skeletons/")
    end


    -- add local directory (relative to current folder) and expand to full path
    -- TODO: relative to CVS (i.e. git project)
    local local_skeleton_dir = M.config.local_skeleton_dir
    if local_skeleton_dir and vim.fn.isdirectory( local_skeleton_dir ) then

        skeletons_append_dirs( skeletons, ft, { vim.fn.fnamemodify( local_skeleton_dir, ':p' ) }, "" )
    end


    print( "skeltons: " .. table.concat( skeletons , ", " ) )

    return skeletons
end



-- | use snippy to insert skeleton and populate snippet fields
--   TODO: use a map with properties, not just 'tpl_file'
local function expand_skeleton(tpl_file)
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
    if not ok then return end
    return snippy.expand_snippet(snip, '')
end


-- | select skeleton from menu 
--   TODO: use map with properties, like name, local
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
    if vim.g.skeletty_enabled then
      local skeletons = list_skeletons()
        print( "no skeletons: " .. #skeletons )

      if #skeletons ~= 0 then
          --print( type(skeletons) ) 
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

M.clear_cache = function() end

-- | return content of this file 
return M
