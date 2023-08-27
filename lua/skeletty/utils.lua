M = {}

-- create debug log file
local log = io.open("debug-log.txt", "w")
io.output( log ) -- ^ redirect write() to 'log'
log:write("* * * LOG SESSION * * *\n") log:flush()


-- | foreach :: [a] -> (a -> b) -> [b]
local function foreach(list, map)
    for k, a in ipairs(list) do
        list[k] = map(a)
    end
end

-- | retrieve value from list from index relative to beginning
--   (and optionally set to new). 
local function ix(list, ix, a)
    ret = list[ ix + 1 ]
    if a then list[ ix + 1 ] = a end
    
    return ret
end


-- can tostring() be used instead?
local function printtype(indent, tp)
    local indent_str = string.rep( " ", indent )
    log:write( indent_str ) log:flush()

    local tpstr = type( tp )
    --log:write(tpstr) log:flush()
    if tpstr == "nil"      then log:write( tp       .. " :: " .. tpstr ) log:flush()           return end
    if tpstr == "string"   then log:write( tp       .. " :: " .. tpstr ) log:flush()           return end
    if tpstr == "number"   then log:write( tp       .. " :: " .. tpstr ) log:flush()           return end
    if tpstr == "boolean"  then log:write( tp       .. " :: " .. tpstr ) log:flush()           return end
    if tpstr == "function" then log:write( "<<function>> :: " .. tpstr ) log:flush()  return end
    if tpstr == "thread"   then log:write( "<<thread>>   :: " .. tpstr )   log:flush() return end
    if tpstr == "userdata" then log:write( "<<userdata>> :: " .. tpstr ) log:flush()   return end
    
    -- type is table
    log:write( "table (# = " .. #tp .. "):\n" ) log:flush()
    for k, v in pairs( tp ) do
        
        -- TODO: key -> 
        printtype( indent + 4, v ) 

        log:write( "\n" ) log:flush()
    end

end

local function debugtype(tp)
    return printtype( 0, tp )
end

local function debugger(str, tp)

    if str then log:write(str) log:flush() end

    if tp == nil then return end

    debugtype( tp )

end


-- | use regex to pick capture groups out of string.
--   regex is of type "very magic"; see :h magic
--   implementation based on :h sscanf()
--
--   TIPS:  ( ) is a capturing group
--          %( ) is a non-capturing group 
--
--   NOTE: it looks like there is a Lua function string.match() to use instead!
--         https://www.lua.org/manual/5.1/manual.html#pdf-string.match
local function regex_pick(str, regex)
    local ret = {}
    
    -- use "very magic" regex, i.e. normal
    regex = [[\v]] .. regex

    -- only work on matching substring
    str = vim.fn.matchstr( str, regex )

    -- retrieve each capture group \1 .. \9
    local i = 1
    while i ~= 10 do

        local sub = [[\]] .. i
        local res = vim.fn.substitute( str, regex, sub, "" )
        
        if res == "" then break end
        
        table.insert( ret, res )
        i = i + 1
    end

    return unpack(ret)
end

--------------------------------------------------------------------------------
--  module skeletty.utils where

M.foreach    = foreach
M.ix         = ix
M.debug      = debugger
M.debugtype  = debugtype
M.regex_pick = regex_pick

return M
