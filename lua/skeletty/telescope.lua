M = {  }

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"
local utils = require "telescope.utils"
local action_utils = require "telescope.actions.utils"

local myutils = require("skeletty.utils")
local config = require("skeletty.config")
local apply = require("skeletty.apply")

-- | create default highlight group
vim.cmd( [[hi SkelettyPlaceholder cterm=bold ctermfg=231 ctermbg=20 gui=bold guifg=#ffffff guibg=#0000ee]] )


--------------------------------------------------------------------------------
-- Entry 
--    value :: a                            -- ^ value 
--    ordinal :: String                     -- ^ dictioary sort value
--    display :: String | (Entry -> String) -- ^ display value or function 
--    (optional fields)                     -- , see :h telescope.make_entry

-- | Config -> (Entry -> String)
local function make_entry_maker( opts )
    
    -- TODO: use opts like 'skeletty_display_*`

    -- | displayer :: String -> [UInt] -> ([Value, Highlight] -> String
    local displayer = entry_display.create( {
        --separator = "| ",
        separator = "  ",
        items = {
            { width = 14 },
            { width = 14 },
            { width = 2 },
            { width = 10 },
            { remaining = true },
        },
    })

    -- Entry -> String
    local display_entry = function( entry )

        local skeleton = entry.value
        
        --local localdir_project = config.get().localdir_project
        --local localdir_exclusive = config.get().localdir_exclusive

        local col_filetype  = skeleton.filetype
        local col_tag       = skeleton.tag
        local col_override  = opts.skeletty_display_override == false and "" or 
                              (skeleton.overrides == 0 and "" or "*")                   -- override marker *
                              --(skeleton.overrides == 0 and "" or skeleton.overrides)  -- override counter
        local col_scope     = opts.skeletty_display_scope     == false and "" or 
                              (skeleton.scope == "localdir" and "localdir" or "")
        local col_path  = opts.skeletty_display_directory == false and "" or 
                              utils.transform_path( opts, skeleton.home )

        return displayer {

            { "  " .. col_filetype, "" },
            { col_tag, "TelescopeResultsIdentifier" },
            { col_override, "TelescopeResultsOperator" },
            { col_scope, "TelescopeResultsSpecialComment" },
            { col_path, "" },
        }
    end

    -- return (Entry -> String) : 
    return function( entry )
        
        local skeleton = entry

        -- value that Picker uses for filtering (searching)
        local ordinal = skeleton.filetype .. skeleton.tag 

        return {

            value = skeleton,
            ordinal = ordinal,
            display = display_entry,

            -- for previewer:
            path = skeleton.filepath, 
        }
    end
end




-- | define picker controller
local function make_mapper(opts)
  
    -- TODO: use 'opts'

    return function( bufnr, map )
        actions.select_default:replace( function()

            actions.close(bufnr)
            local skeleton = action_state.get_selected_entry().value
           
            -- this is where the magic happens
            apply.skeleton( skeleton )
        end)

        --local map_override = opts.skeletty_map_toggle_overrides or "<C-o>"
        --local map_localdir = opts.skeletty_map_toggle_localdir or "<C-l>"
        --
        --local prompt_bufnr = vim.api.nvim_get_current_buf()
        --local current_picker = action_state.get_current_picker( prompt_bufnr )

        -- TODO: toggle show overrides
        --map( {"i", "n"}, map_override, function(_prompt_bufnr)
        --    print "toggle overrides"
        --end)

        -- TODO: toggle show localdir exclusive
        --map( {"i", "n"}, map_localdir, function(_prompt_bufnr)
        --  print "toggle localdir"
        --end)

        return true
    end
end

--------------------------------------------------------------------------------
--  Preview


-- | preview skeleton file (.snippet)
local function make_previewer( opts )

    local previewer = require("skeletty.telescope.previewer").skeleton_previewer( opts )
    return previewer

end



-- select skeleton 
local function make_skeletty_picker(opts, skeletonset)

    local opts = opts or {  }
    
    opts.results_title = "Skeletons"

    -- skull selector (can be overridden by user)
    opts.selection_caret = opts.selection_caret or '💀' 
    
    -- vertical layout by default
    opts.layout_strategy = opts.layout_strategy or "vertical"

    pickers.new( opts, {

        prompt_title = opts.prompt_title,

        sorter = conf.generic_sorter( opts ),
        finder = finders.new_table {

            results = skeletonset.skeletons, -- ^ TODO: use `table.sort` here since sorting by 'ordinal' doesn't seem to work?
            entry_maker = make_entry_maker( opts ),
        },

        attach_mappings = make_mapper( opts ),
        previewer = make_previewer( opts ),

    }):find()
end



--------------------------------------------------------------------------------
--  test
--[[
local function test_pick()
    local skeletonset = {  }
    skeletonset.name = "SKELETONS"
    skeletonset.skeletons = {}
    skeletonset.ignores = 0
    skeletonset.exclusive = false

    for i, v in ipairs( { 
        { "haskell", "stack" },
        { "haskell", "hackage" },
        { "haskell", "main" },
        { "cpp",     "bjarne" },
        { "cpp",     "stroustrup" },
        { "c-sharp", "bill" },
        { "git",     "hub" },
        { "git",     "module" },
        { "linux",   "tux" },
        { "logic",   "skolem" },
        { "logic",   "peano" },
    } ) do
        local item = {  }
        item.filepath = "/usr/local/secret"
        item.scope = "test-scope"
        item.home = "/Users/test/snippet" .. (i + 100)
        item.filetype = v[ 0 + 1 ]
        item.tag = v[ 1 + 1 ]
        item.overrides = i
        table.insert( skeletonset.skeletons, item )
    end

    local opts = {  }

    opts.initial_mode = opts.initial_mode or "normal"
    opts.prompt_title = "TestingTelescope"

    make_skeletty_picker( opts, skeletonset )
end

myutils.start_debug()
test_pick()

--]]

--------------------------------------------------------------------------------
--  module skeletty.telescope where


-- | create picker to select between a small set of skeletons. settings from 
--   skeletty user config
M.pick_skeleton = function( skeletonset )

     
    -- TODO: extend from Telescope's 'conf' above

    local opts = config.get().telescope or {  }


    -- default to normal mode since the number of skeletons shouldn't be overwelding
    opts.initial_mode = opts.initial_mode or "normal"

    opts.prompt_title = "Filter"

    make_skeletty_picker( opts, skeletonset )
end

-- | general interface for the Skeletty Telescope extension
M.make_skeletty_picker = make_skeletty_picker

return M

