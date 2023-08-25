# TODO
* work on skeleton metadata
* pick automatic file if `g:localdir_auto`
* create override command settings
* use a list of data, not just filenames 
* override skeleton if same filename and tag (auto)
* use Emojis

## config
* `g:skeletty_dirs`: override runtimepath
* `g:skeletty_localdir`: 
* `g:skeletty_localdir_vcs`: bool if use version control parent
* `g:skeletty_auto`: only works with local skeltons, it ignores all other skeletons. 
  if there exists a <ft>.snippet always use that. otherwise, choose between tagged 
  skeletons <tf>-<tag>.snippet or <ft>/tag.snippet. create an <ft>-empty.snippet if
  you will ignore skeleton
