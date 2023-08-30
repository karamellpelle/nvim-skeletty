M = {  }

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- our picker function: skeletty_telescope_pick
local function skeletty_telescope_pick(opts, tbl)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "colors",
    sorter = conf.generic_sorter(opts),

    finder = finders.new_table {

      results = tbl,
      --{
      --  { "red", "#ff0000" },
      --  { "green", "#00ff00" },
      --  { "blue", "#0000ff" },
      --},
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1],
          ordinal = entry[1],
        }
      end
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


skeletty_telescope_pick( 
      nil, {
        { "red", "#ff0000" },
        { "green", "#00ff00" },
        { "blue", "#0000ff" },
      }
)

M.skeletty_telescope_pick = skeletty_telescope_pick

return M

