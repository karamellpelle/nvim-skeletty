M = {  }

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"

local myutils = require("skeletty.utils")

-- | displayer :: String -> [UInt] -> ([Value, Highlight] -> String
local displayer = entry_display.create( {
  separator = "|",
  items = {
    { width = 3 },
    { width = 8 },
    { width = 10 },
    { width = 10 },
    { remaining = true },
  },
  }
)

local function entry_display( entry )

    local item = entry.value

    myutils.debug( "make_entry->value: " .. vim.inspect( entry.value ) )

    --return item.name .. "->" .. item.overrides

    return displayer {
      { " " .. item.overrides, "TelescopeResultsNumber" },
      { item.name, "" },
      { item.tag, "TelescopeResultsComment" },
      { item.scope, "" },
      { item.home, "" },
      --{ item., "" },
    }
end

--------------------------------------------------------------------------------
-- Entry 
--    value :: a                            -- ^ value 
--    ordinal :: String                     -- ^ dictioary sort value
--    display :: String | (Entry -> String) -- ^ display value or function 
local function make_entry( item )
    return {
      value = item,
      ordinal = item.tag, -- FIXME: define order of SkeletonItems; use priority
      display = entry_display,
      --filepath = item.filepath, -- 'filepath' is actually an optional field for Entry
    }

end


-- | define picker controller
local function make_mappings( bufnr, map )

    actions.select_default:replace(
        function()
            -- this is where the magic happens
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()

            --vim.api.nvim_put({ selection.value[1] }, "", false, true)

             --print(vim.inspect(selection))
            vim.api.nvim_put({ vim.inspect(selection) }, "", false, true)

        end)

    return true
end

-- our picker function: skeletty_telescope_pick
local function skeletty_telescope_pick(opts, skeletons)

    opts = opts or {  }
   
    -- skull selector (can be overridden by user (telescope.skeletty.selection_caret))
    opts.selection_caret = opts.selection_caret or '💀' 

    opts.initial_mode = "normal"
    --opts.path_display = "smart"

    pickers.new(opts, {

        prompt_title = "Pick Skeleton",
        sorter = conf.generic_sorter( opts ),
        finder = finders.new_table {

            results = skeletons.items,
            entry_maker = make_entry,
        },

        attach_mappings = make_mappings,

    }):find()
end

local function test_pick()
    local skeletons = {  }
    skeletons.name = "SKELETONS"
    skeletons.kind = "skeletons"
    skeletons.items = {}
    skeletons.ignores = 0
    skeletons.exclusive = false

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
        item.name = v[ 0 + 1 ]
        item.tag = v[ 1 + 1 ]
        item.overrides = i
        table.insert( skeletons.items, item )
    end

    
        --myutils.debug( vim.inspect( skeletons ))
    skeletty_telescope_pick( nil, skeletons )
end

myutils.start_debug()
test_pick()

return M

