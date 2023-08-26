M = {}

local log = io.open("debug-log.txt", "w")
io.output( log ) -- ^ redirect print to 'log'
--log:write("\n\n\n")
log:write("* * * LOG SESSION * * *\n")
log:flush()


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


local function debugger(str, tp)

    if str then log:write(str) log:flush() end

    if tp == nil then return end

    printtype(0, tp)
end

M.foreach = foreach
M.ix = ix
M.debug = debugger

return M
