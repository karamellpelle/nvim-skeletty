M = {  }

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"

local myutils = require("skeletty.utils")

local displayer = entry_display.create( {
  separator = "| ",
  items = {
    { width = 8 },
    { width = 4 },
    { width = 2 },
    { remaining = true },
  },
  }
)

local function entry_display( entry )

    local item = entry.value

    myutils.debug( "make_entry->value: " .. vim.inspect( entry.value ) )

    --return item.name .. "->" .. item.overrides

    return displayer {
      { item.overrides, "TelescopeResultsNumber" },
      { item.tag, "TelescopeResultsComment" },
      { "**", "DiffChange" },
      item.name .. ":" .. item.home,
    }
    --return displayer {
    --      { entry.bufnr, "TelescopeResultsNumber" },
    --      { entry.indicator, "TelescopeResultsComment" },
    --      { icon, hl_group },
    --      display_bufname .. ":" .. entry.lnum,
    --    }
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
    }

end

-- our picker function: skeletty_telescope_pick
local function skeletty_telescope_pick(opts, skeletons)
  opts = opts or {}
      --myutils.debug("telescope_pick\n")
      --myutils.debug( vim.inspect( skeletons ) )
  pickers.new(opts, {
    prompt_title = "Pick Skeleton",
    sorter = conf.generic_sorter( opts ),

    finder = finders.new_table {

        results = skeletons.items,

        entry_maker = make_entry,
    },

    attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          --vim.api.nvim_put({ selection.value[1] }, "", false, true)

           --print(vim.inspect(selection))
          vim.api.nvim_put({ vim.inspect(selection) }, "", false, true)


        end)
        return true
      end,

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
        item.home = "/Users"
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

