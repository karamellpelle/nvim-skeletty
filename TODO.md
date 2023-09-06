# TODO
* make sure `setup()` does not write `nil` to wrong fields, and make `M.config` local
* apply at top of buffer
* create connection to _Telescope_ (if found)
* create `doc.txt` 

## Telescope
* do action on select
* connect to skeletty.lua
* previewer
* conf settings
  - show column X, etc.
  - caret
  - enable disable automatic Telescope
  - 
* (create Telescope extension)
### tips
* telescope.extensions: a table with all extension opts
## plan
* setup auto commands from `setup( enable )`
* choose skeleton selector (native, telescope)
* find module with new arguments
* automatic telescope selection

## Restructuring
```

SkeletonSet
    name :: String
    skeletons :: [Skeleton]
    ignores :: UInt
    exclusieve :: Bool
    
plugin/skeletty.lua
    setup :: Config -> IO ()
    -- => skeletty.setup
    
lua/skeletty.lua
    setup :: Config -> IO ()
    -- => skeletty.config.setup
    -- => skeletty.config.get >>= create autocmd based on setup => apply Type
    apply :: Maybe Type -> () 
    -- ^ Maybe Type -> use type, take into account config settings: overrides, localdir_exclusive, localdir_project
    -- ^ Nothing    -> use all, take into account config settings: localdir_project
    -- ^ ui.select or telescope.select (and apply from them)
    
    
lua/skeletty/config.lua
         %%auto               :: Bool                               -- ^ apply skeleton (from selection) upon new buffer with filetype 
    setup :: Config -> IO ()
    -- ^ make sure values are inside
    get :: IO Config

lua/skeletty/apply.lua
    apply :: Skeleton -> IO ()
    -- ^ apply skeleton to current buffer using Snippy
    
lua/skeletty/select.lua
    skeleton_select :: SkeletonSet -> Maybe Skeleton
    
lua/skeletty/find.lua
    find_skeletons :: Maybe Scope -> Maybe Type -> SkeletonSet   
    -- ^ Nothing Scope => all scopes (Scope Nothing Nothing Nothing)
        Scope
            localdir         -- if nil, use config
            userdir          -- if nil, use config
            runtimepath   -- if nil, use config
    -- ^ Nothing Type => all types
    -- ^ Just Scope 
    skeltons_overrides :: &SkeletonSet -> Bool -> IO ()
    -- ^ bool if remove
    expand_localdir :: FilePath -> FilePath
    -- ^ use config for project relative
            
lua/skeletty/telescope.lua
    telescope_select :: SkeletonSet -> IO ()
    -- ^ choose skeleton and apply if select

lua/telescope/_extensions/skeletty/skeletty.lua
    :Telescope skeletty apply
    -- ^ find and apply: 
       no filename => select( all types ) >>= apply( Skeleton Type )
       filename    => select( filetype ) >>= apply( Skeleton Type )
    -- ^ use skeletty.apply? what about config?
    :Telescope skeletty new
    -- ^ create new buf (no filenamea) >>= select( all types ) => apply ( Skeleton Type )

lua/telescope/_extensions/skeletty/skeletty/etc.lua

```
