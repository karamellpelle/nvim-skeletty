# TODO
* work on skeleton metadata
* better presentation in `vim.ui.select` (naming from metadata)
* pick automatic file if `g:localdir_auto` (continue developting)
* create override command settings
* create connection to _Telescope_ if that exists

## config
* `g:skeletty_dirs`: override runtimepath
* `g:skeletty_localdir`: 
* `g:skeletty_localdir_vcs`: bool if use version control parent
* `g:skeletty_auto`: only works with local skeltons, it ignores all other skeletons. 
  if there exists a <ft>.snippet always use that. otherwise, choose between tagged 
  skeletons <tf>-<tag>.snippet or <ft>/tag.snippet. create an <ft>-empty.snippet if
  you will ignore skeleton

## API
### lua-fs
vim.fs.normalize
