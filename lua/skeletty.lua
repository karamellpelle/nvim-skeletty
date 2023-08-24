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
        for _, dir in ipairs(dir_list) do
            -- warn if skeleton folder inside skeleton
            if vim.fn.isdirectory(vim.fn.expand(dir) .. '/skeletons') == 1 then
                vim.notify( 'Skeletty: folders in "skeleton_dirs" should not contain a "skeletons" subfolder', vim.log.levels.WARN )
                -- TODO: remove 'dir'
            end
        end
        params.skeleton_dirs = dir_list
    end

    -- insert updated and original values directly into config
    M.config = vim.tbl_extend('force', M.config, params)
end


-- | find skeleton files from filetype of current buffer
local function list_skeletons()
    local ft = vim.bo.ft
    if not ft or ft == '' then
        return {}
    end

    local dirs = {} 

    -- use configuration directories (if present) or runtime paths
    if M.config.skeleton_dirs and 1 <= #M.config.skeleton_dirs then 
        table.insert( dirs, 1, M.config.skeleton_dirs )  
    else
        table.insert( dirs, 1, vim.split( vim.o.rtp, '\n' ) ) 
    end

    if vim.fn.isdirectory(vim.fn.expand(dir) .. '/skeletons') == 1 then end

    -- add current directory (local)
    local local_dir = M.config.local_skeleton_dir
    if local_dir and vim.fn.isdirectory(local_dir) then
        table.insert(dirs, 1, vim.fn.fnamemodify(local_dir, ':p'))
    end

    local relative_dirs = ""

    -- flatten table into comma separated paths
    --if type(dirs) ~= 'string' then
    --    relative_dirs = table.concat(dirs, ',')
    --end
 
    -- for now, ignore user setting
    relative_dirs = vim.o.rtp -- comma separated paths like runtimepath

    -- expand from glob expand
    local skeletons = {}
    for _, expr in ipairs({
        'skeletons/' .. ft .. '.snippet',     -- [filetype]
        'skeletons/' .. ft .. '-*.snippet',   -- [filetype]-[tag]
        'skeletons/' .. ft .. '/*.snippet',   -- [filetype]/[tag]
    }) do

        -- find files using globs 
        vim.list_extend( skeletons, vim.fn.globpath( relative_dirs, expr, false, true))
    end

    --print( "skeltons: " .. table.concat( skeletons , ", " ) )
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
