M = {  }

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"

local myutils = require("skeletty.utils")
config = require("skeletty.config")
apply = require("skeletty.apply")


--------------------------------------------------------------------------------
-- Entry 
--    value :: a                            -- ^ value 
--    ordinal :: String                     -- ^ dictioary sort value
--    display :: String | (Entry -> String) -- ^ display value or function 
--    (optional fields)                     -- , see :h telescope.make_entry

-- | Config -> (Entry -> String)
local function make_entry_maker( opts )
    
    -- TODO: use opts for config


    -- | displayer :: String -> [UInt] -> ([Value, Highlight] -> String
    local displayer = entry_display.create( {
        separator = "| ",
        items = {
            --{ width = 3 },
            { width = 12 },
            { width = 16 },
            { width = 10 },
            { remaining = true },
        },
    })

    -- Entry -> String
    local display_entry = function( entry )

        local skeleton = entry.value

--myutils.debug( "make_entry->value: " .. vim.inspect( entry.value ) )
        return displayer {

            --{ " " .. skeleton.overrides, "TelescopeResultsNumber" },
            { " " .. skeleton.filetype, "" },
            { skeleton.tag, "TelescopeResultsComment" },
            { skeleton.scope, "" },
            { skeleton.home, "" },
        }
    end

    -- return (Entry -> String) : 
    return function( entry )
        
        local skeleton = entry

        return {

            value = skeleton,
            ordinal = skeleton.tag, -- FIXME: define order of Skeletons; use priority
            display = display_entry,
            --filepath = skeleton.filepath, -- 'filepath' is actually an optional field for Entry
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
            --vim.api.nvim_put({ vim.inspect(skeleton) }, "", false, true)
        end)

        return true
    end
end



-- select skeleton 
-- TODO: handle user options
local function make_skeletty_picker(opts, skeletonset)

    local opts = opts or {  }
  
    -- skull selector (can be overridden by user)
    opts.selection_caret = opts.selection_caret or '💀' 

    pickers.new( opts, {

        prompt_title = "Create new file from", -- TODO: only if new file

        sorter = conf.generic_sorter( opts ),
        finder = finders.new_table {

            results = skeletonset.skeletons,
            entry_maker = make_entry_maker( opts ),
        },

        attach_mappings = make_mapper( opts ),

    }):find()
end



--------------------------------------------------------------------------------
--  test

local function test_pick()
    local skeletonset = {  }
    skeletonset.name = "SKELETONS"
    skeletonset.skeletons = {}
    skeletonset.ignores = 0
    skeletonset.exclusive = false

    for i, v in ipairs( { 
        { "haskell", "stack" },
        { "haskell", "hackage" },
        { "haskell", "rave" },
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


--------------------------------------------------------------------------------
--  module skeletty.telescope where


-- | create picker to select between a small set of skeletons
M.pick_skeleton = function( skeletonset )

     
    -- TODO: extend from Telescope 'conf' ?

    local opts = config.get().telescope or {  }

    -- data to picker
    opts.skeletty_localdir_project = config.get().localdir_project
    opts.skeletty_localdir_exclusive = config.get().localdir_exclusive
    opts.skeletty_SkeletonSet_name = skeletonset.name
    opts.skeletty_SkeletonSet_ignores = skeletonset.ignores
    opts.skeletty_SkeletonSet_exclusive = skeletonset.exclusive


    -- default to normal mode since the number of skeletons shouldn't be overwelding
    opts.initial_mode = opts.initial_mode or "normal"

    opts.prompt_title = "New file from"

    make_skeletty_picker( opts, skeletonset )
end

-- | general interface (usable for the Skeletty Telescope extension)
M.make_skeletty_picker = make_skeletty_picker

return M

