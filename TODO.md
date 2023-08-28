# TODO
* pick automatic file if `g:localdir_auto` 
* create connection to _Telescope_ if that exists

## config
* `g:skeletty_auto`: only works with local skeltons, it ignores all other skeletons. 
  if there exists a <ft>.snippet always use that. otherwise, choose between tagged 
  skeletons <tf>-<tag>.snippet or <ft>/tag.snippet. create an <ft>-empty.snippet if
  you will ignore skeleton

## API
### lua-fs
vim.fs.normalize
