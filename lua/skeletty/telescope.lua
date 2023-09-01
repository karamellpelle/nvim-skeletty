M = {  }

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"

local myutils = require("skeletty.utils")
config = require("skeletty.config")

--------------------------------------------------------------------------------
--  default configuratio



--------------------------------------------------------------------------------
--  display

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

    --return item.filetype .. "->" .. item.overrides

    return displayer {
      { " " .. item.overrides, "TelescopeResultsNumber" },
      { item.filetype, "" },
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
--    (optional fields)                     -- , see :h telescope.make_entry
local function make_entry( item )
    return {
      value = item,
      ordinal = item.tag, -- FIXME: define order of Skeletons; use priority
      display = entry_display,
      --filepath = item.filepath, -- 'filepath' is actually an optional field for Entry
    }

end


-- | define picker controller
local function mapper( bufnr, map )
    actions.select_default:replace(
        function()
            -- this is where the magic happens
            actions.close(bufnr)
            local selection = action_state.get_selected_entry()

            vim.api.nvim_put({ vim.inspect(selection) }, "", false, true)

        end)

    return true
end


-- our picker function: skeletty_telescope_pick
local function skeletty_telescope_pick(opts, skeletonset)

    local opts = opts or {  }
  
    -- handle user options

    -- skull selector (can be overridden by user (telescope.skeletty.selection_caret))
    opts.selection_caret = opts.selection_caret or '💀' 

  opts.initial_mode = "normal"
    --opts.path_display = "smart"

    pickers.new(opts, {

        --prompt_title = "Pick Skeleton",
        prompt_title = "Create new file from", -- TODO: only if new file
        sorter = conf.generic_sorter( opts ),
        finder = finders.new_table {

            results = skeletonset.skeletons,
            entry_maker = make_entry,
        },

        attach_mappings = mapper,
        --attach_mappings = mapper1,

    }):find()
end

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

    --myutils.debug( vim.inspect( skeletons ))

    skeletty_telescope_pick( default_opts, skeletonset )
end

myutils.start_debug()
test_pick()

return M

