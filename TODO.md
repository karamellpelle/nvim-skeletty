# TODO
* set normal mode after Snippy expansion. problem with `nvim-snippy` :(
  `autocmd User SnippyFinished call feedkeys("\<Esc>", 'n')`

## Telescope
* use `opts` correctly: make use of `require("telescope.config").values` 
* use `skeletty_display_` settings: no filepath, filter overrided. 
* create mappings for filtering: 
    - filter overrided skeletons (default true), otherwise show number of overrides.
    - filter only localdir (default false)

