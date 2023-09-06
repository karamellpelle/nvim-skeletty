local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local utils = require("skeletty.utils")
local from_entry = require "telescope.from_entry"

local M = {  }

local function defaulter(f, default_opts)

    default_opts = default_opts or {}

    return {

        new = function( opts )

            if conf.preview == false and not opts.preview then

                return false
            end

            opts.preview = type( opts.preview ) ~= "table" and {} or opts.preview
            if type( conf.preview ) == "table" then

              for k, v in pairs(conf.preview) do

                  opts.preview[k] = vim.F.if_nil(opts.preview[k], v)
              end
            end

            return f( opts )
        end,

        __call = function()

              local ok, err = pcall( f( default_opts ) )
              if not ok then

                  error(debug.traceback(err))
              end
        end,
    }
end



local skeleton_previewer1 = defaulter(function(opts)

    opts = opts or {}
    local cwd = opts.cwd or vim.loop.cwd()

    local ret = previewers.new_buffer_previewer {
    --return previewers.new_buffer_previewer {

        -- titles
        title = "Skeleton Preview",
        dyn_title = function(_, entry)
            local skeleton = entry.value
            return skeleton.filetype .. "(" .. (skeleton.tag and skeleton.tag or "") .. ")"
        end,

        -- buffer name
        get_buffer_by_name = function(_, entry)
          return from_entry.path(entry, false)
        end,

        -- preview machinery
        define_preview = function(self, entry, status)

            local p = from_entry.path(entry, true)
            if p == nil or p == "" then

              return
            end

            conf.buffer_previewer_maker(p, self.state.bufnr, {
              bufname = self.state.bufname,
              winid = self.state.winid,
              preview = opts.preview,
              file_encoding = opts.file_encoding,
            })
          end,
    }
    utils.debug("skeleton_previewer1", ret) 
    return ret
        
    end, {})


local function skeleton_previewer( opts )

    return skeleton_previewer1.new( opts )
--return conf.file_previewer( opts )
end

    -- TODO: add syntax from entry
    -- TODO: add highlight from .snippet
--------------------------------------------------------------------------------
--  module skeletty.telescope.previewer

M.skeleton_previewer = skeleton_previewer

return M
