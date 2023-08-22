-- export data
local M = {}

-- default configuration
local default_config = {
    skeleton_dirs = nil, -- ^ _list_  of directories
    local_skeleton_dir = '.skeletons', -- ^ directory path relative to current
}

-- | M.config :: Config
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
                vim.notify(
                    'Snippy: folders in "skeleton_dirs" should no longer contain a "skeletons" subfolder',
                    vim.log.levels.WARN
                )
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

    -- use config directories (if present) or runtime paths
    if config.skeleton_dirs or 1 <= #config.skeleton_dirs then -- FIXME: can we just use #?
        table.insert( dirs, 1, config.skeleton_dirs )  
    else
        table.insert( dirs, 1, vim.split( vim.o.rtp, '\n' ) ) 
    end

    if vim.fn.isdirectory(vim.fn.expand(dir) .. '/skeletons') == 1 then

    -- add current directory (local)
    local local_dir = config.local_skeleton_dir
    if local_dir and vim.fn.isdirectory(local_dir) then
        table.insert(dirs, 1, vim.fn.fnamemodify(local_dir, ':p'))
    end

    local relative_paths = ""

    -- flatten table into comma separated paths
    --if type(dirs) ~= 'string' then
    --    relative_paths = table.concat(dirs, ',')
    --end
 
    -- for now, ignore user setting
    relative_paths = vim.o.rtp -- comma separated paths

    -- expand from glob expand
    local skeletons = {}
    for _, expr in ipairs({
        'skeletons/' .. ft .. '.snippet',
        'skeletons/' .. ft .. '/*.snippet',
    }) do
        vim.list_extend(skeletons, vim.fn.globpath( relative_paths, expr, false, true))
    end
    return skeletons
end


-- | use snippy to insert skeleton and populate snippet fields
local function expand_skeleton(tpl_file)
    if vim.g.skeletty_enabled
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
end

-- | expand current buffer
local function expand()
    if vim.g.skeletty_enabled
      local skeletons = list_skeletons()
      if not #skeletons == 0
          -- add selection option: no template
          vim.list_extend(skeletons, 'None')
          -- show menu
          --local formatter = function(item) return "Skeleton: " .. item end
          -- ^TODO: unicode skeleton
          --local select_args = { prompt = 'Select file skeleton:', format_item = formatter }
          --local 
          --local selection = function( sel ) if not sel == 'None' then expand_skeleton( sel ) end
          vim.ui.select( skeletons, {
              prompt = 'Select file skeleton:'
              --, format_item = formatter, 
          }, function(selected)
             if not selected == 'None' then
                expand_skeleton(selected)
             end
          end
          )
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
