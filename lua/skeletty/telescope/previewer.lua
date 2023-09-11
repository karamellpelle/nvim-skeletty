local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local su = require("skeletty.utils")
local from_entry = require "telescope.from_entry"
local utils = require "telescope.utils"

local M = {  }


local skeleton_previewer = function( opts )

    opts = opts or {}

    return previewers.new_buffer_previewer {

        -- title
        title = "Skeleton Preview",

        -- dynamic title
        dyn_title = function(_, entry)

            local skeleton = entry.value
            return skeleton.filetype .. "(" .. (skeleton.tag and skeleton.tag or "") .. ")"
        end,

        -- buffer name
        get_buffer_by_name = function(_, entry)
            return from_entry.path(entry, false)
        end,

        -- machinery
        define_preview = function(self, entry, status)

            local skeleton = entry.value

            conf.buffer_previewer_maker( skeleton.filepath, self.state.bufnr, {

                bufname = self.state.bufname,
                winid = self.state.winid,
                preview = opts.preview,
                file_encoding = opts.file_encoding,

                -- we need custom highlighting based on skeleton filetype
                use_ft_detect = false,
                callback = function(bufnr) 

                    -- set syntax to filetype defined by skeleton
                    vim.api.nvim_buf_set_option( bufnr, "syntax", skeleton.filetype )

                    -- syntax highlight of snippet placeholders
                    -- FIXME: this does not always work because of syntax priority, see :h syn-priority.
                    --        example haskell: import ${n:x} overrides range below 
                    vim.api.nvim_buf_call( bufnr, function()

                        local skeletty_higroup = opts.skeletty_higroup or [[SkelettyPlaceholder]]
                        -- ${n:x}
                        vim.cmd( [[syn region ]] .. skeletty_higroup .. [[ start="${" end="}" contains=]] .. skeletty_higroup)
                        -- $n
                        vim.cmd( [[syn match ]] .. skeletty_higroup .. [[ "$\d\+"]])
                    end)
                end,
            })
          end,
    }

end 



--------------------------------------------------------------------------------
--  module skeletty.telescope.previewer

M.skeleton_previewer = skeleton_previewer

return M
