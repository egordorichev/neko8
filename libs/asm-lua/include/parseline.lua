
local ex = {
    {type = 'do', pattern = 'do', out = {}},
    {type = 'end', pattern = 'end', out = {}},
    {type = 'loop', pattern = 'loop', out = {}},
    {type = 'label', pattern = '([%a%d_%-]+)%s*:', out = {'name'}},
    {type = 'section', pattern = 'section %.([%a%d_%-]+)', out = {'name'}},
    {type = 'if', pattern = 'if (%a+) then', out = {'cond'}}, -- TODO: cond validation
    {type = 'while', pattern = 'while (%a+) do', out = {'cond'}},
    {type = 'until', pattern = 'until (%a+)', out = {'cond'}},
    {type = 'extern', pattern = 'extern ([%a%d_]+)', out = {'name'}},
    {type = 'def', pattern = 'def ([%a%d_%-]+) (".*")', out = {'name', 'val'}}, -- TODO: string validation
    {type = 'def', pattern = 'def ([%a%d_%-]+) (0x[%da-fA-F]*%.?[%da-fA-F]+)', out = {'name', 'val'}},
    {type = 'def', pattern = 'def ([%a%d_%-]+) (0[0-7]*%.?[0-7]+)', out = {'name', 'val'}},
    {type = 'def', pattern = 'def ([%a%d_%-]+) (0b[01]*%.?[01]+)', out = {'name', 'val'}},
    {type = 'def', pattern = 'def ([%a%d_%-]+) (%d*%.?%d+)', out = {'name', 'val'}},
    {type = 'op', pattern = '(%a+) ([%a%d%[%]_%-]+), ([%a%d%[%]_%-]+)', out = {'op', 'a', 'b'}},
    {type = 'op', pattern = '(%a+) ([%a%d%[%]_%-]+)', out = {'op', 'a'}},
    {type = 'op', pattern = '(%a+)', out = {'op'}}
}

for _, v in ipairs(ex) do
    local b = '^%s*' -- begin
    local e = '%s*$' -- end
    local s = '%s+'  -- space one or more
    v.pattern = b .. string.gsub(v.pattern, ' ', '%%s+') .. e
end

local match = function(expr, ex, result, verbose, linen)
    local out = {string.match(expr, ex.pattern)}
    if #out == 0 then
        return false
    end

    result.type = ex.type

    for i = 1, #ex.out do
        local name = ex.out[i]
        result[name] = out[i]
    end

    result.linen = linen
    result.text = expr

    return true
end

local parseline = function(line, verbose, linen)
    if not string.match(line, '^%s*$') then
        for _, v in ipairs(ex) do
            local result = {}
            if match(line, v, result, verbose, linen) then
                return result
            end
        end
        error(string.format('invalid expression: %s\n' ..
                            '           at line: %d', expr, linen))
   end
end

return parseline
