# Skeletty 💀

Skeletty is a NeoVim plugin for file skeletons (templates). It depends on [dcompos/nvim-snippy](https://github.com/dcampos/nvim-snippy) to expand the template files that defines the skeletons.

## Install
For example through [vim-plug](https://github.com/junegunn/vim-plug):
```vim
" if has( "nvim" )
Plug 'dcampos/nvim-snippy' 
Plug 'karamellpelle/nvim-skeletty'
" endif
```



Configure Skeletty in your _init.lua_ or [_init.vim_](https://neovim.io/doc/user/lua.html#%3Alua-heredoc):
```lua
require( "skeletty" ).setup( {
      -- key0 = value0,
      -- key1 = value1,
      -- ...
} )
``` 

## Settings
These are the available settings for `require( "skeletty" ).setup()` together with the default values. The `setup()` function can be called multiple times.
```lua
dirs                  = nil,
-- ^ list or comma separated string of directories to look after skeleton files
localdir              = ".skeletons",
-- ^ name of subfolder with local skeletons
localdir_project      = false,
-- ^ is the local folder relative to current working directory (false)
--   or current Git project (true)?
localdir_exclusive    = false,
-- ^ only look for skeletons in the local directory 
--   (however, the ':SkelettyApply' command will look everywhere)
auto                  = false,
-- ^ trig skeleton for every new file with a filetype (i.e. file extension)
auto_single           = false,
-- ^ if there is just 1 candidate, apply without selection prompt
override              = false,
-- ^ only show skeletons with highest priority when filetype and tag are equal
apply_at_top          = false,
-- ^ apply skeleton at top line
apply_syntax          = true,
-- ^ apply syntax highlight from skeleton if buffer have no filetype
native_selector_force = false,
-- ^ use the native selector even if Telescope is present.
--   you probably don't want this.
telescope             = {
    skeletty_display_path               = true,  
    -- ^ display path of skeleton
    skeletty_display_overrides          = true,
    -- ^ display overridden skeletons
    skeletty_display_directory          = true,
    -- ^ display containing directory
    skeletty_hl_group                   = "SkelettyPlaceholder"
    -- ^ highlight group for placeholder in the preview of skeleton
}
-- ^ Telescope specific settings
```

Here is a suggestion of sane settings I would use:
```lua
localdir = ".skeletons",
localdir_project = true,
localdir_exclusive = true,
auto = true, -- or use ':SkelettyAutoEnable'
```
This forces Skeletty to only work when we are inside a Git project and the root folder has a _.skeletons_ subfolder. For any new file that has a corresponding skeleton in the subfolder, we will automatically get the choice to apply the skeleton(s). The `:SkelettyApply` command can always be used to apply any skeleton to any file.

## Skeleton format
Skeleton files are `.snippet` files in SnipMate format as described in `:h snippy-snipmate-syntax`. Their prioritized locations are: (_a_) `localdir` relative to current working directory or project directory (`localdir_project = true`), (_b_) directories specified in `dirs`, (_c_) `skeletons/` subfolders of the directories in NeoVim's `runtimepath`. (_c_) is searched only if `dirs` is empty. Only using local skeletons (_a_) can be set with `localdir_exclusive = true`

Skeletons are named by filetype and tag: as files `<filetype>.snippet` (no tag), `<filetype>-<tag>.snippet` or `<filetype>/<tag>.snippet`.


## Commands
* `:Skeletty`: Apply skeleton to current, empty buffer, or create a new buffer in a new tab.
* `:SkelettyApply <filetype>`: Apply skeleton of chosen filetype (or any skeleton using filetype `*`) to current buffer regardless of content in current buffer. Applies at current position, or top of file if `apply_at_top = true`.
* `:SkelettyAutoEnable` / `:SkelettyAutoDisable`: Enable/disable automatic skeleton application on new files


## Telescope
Skeletty integrates well with [Telescope](https://github.com/nvim-telescope/telescope.nvim). Skeletty will automatically use Telescope as a skeleton selector if Telescope is present. Skeletty is also available as a Telescope extension: 
```lua
telescope.load_extension( "skeletty" )
```

This extension has an interface similar to the commands. For example, to apply a LaTeX specific skeleton: `:Telescope skeletty apply =latex`

![screenshot-macos-1](https://github.com/karamellpelle/nvim-skeletty/assets/4390333/57df3930-3a88-4fe3-9a64-777450379d95)

