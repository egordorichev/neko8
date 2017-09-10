
local arg = {
    {type = 'reg', pattern = '(f%.%a+)', out = {'reg'}}, -- TODO: validate
    {type = 'reg', pattern = '(ss)', out = {'reg'}},
    {type = 'reg', pattern = '(ds)', out = {'reg'}},
    {type = 'reg', pattern = '(a)', out = {'reg'}},
    {type = 'reg', pattern = '(b)', out = {'reg'}},
    {type = 'reg', pattern = '(c)', out = {'reg'}},
    {type = 'reg', pattern = '(d)', out = {'reg'}},
    {type = 'reg', pattern = '(sp)', out = {'reg'}},
    {type = 'immediate', pattern = '(".*")', out = {'val'}}, -- TODO: string validation
    {type = 'immediate', pattern = '(true)', out = {'val'}},
    {type = 'immediate', pattern = '(false)', out = {'val'}},
    {type = 'mem', pattern = '%[(0x[%da-fA-F]+)%]', out = {'ptr'}, numeric = true},
    {type = 'mem', pattern = '%[(0[0-7]+)%]', out = {'ptr'}, numeric = true},
    {type = 'mem', pattern = '%[(0b[01]+)%]', out = {'ptr'}, numeric = true},
    {type = 'mem', pattern = '%[([%d]+)%]', out = {'ptr'}, numeric = true},
    {type = 'memvar', pattern = '%[([%a%d_%-]+)%]', out = {'name'}},
    {type = 'immediate', pattern = '(0x[%da-fA-F]*%.?[%da-fA-F]+)', out = {'val'}, numeric = true},
    {type = 'immediate', pattern = '(0[0-7]*%.?[0-7]+)', out = {'val'}, numeric = true},
    {type = 'immediate', pattern = '(0b[01]*%.?[01]+)', out = {'val'}, numeric = true},
    {type = 'immediate', pattern = '([%d]*%.?[%d]+)', out = {'val'}, numeric = true},
    {type = 'var', pattern = '([%a%d_%-]+)', out = {'name'}}
}

for _, v in ipairs(arg) do
    local b = '^%s*' -- begin
    local e = '%s*$' -- end
    v.pattern = b .. v.pattern .. e
end

local match_arg = function(expr, arg, result, verbose)
    local out = {string.match(expr, arg.pattern)}
    if #out == 0 then
        return false
    end

    result.type = arg.type

    for i = 1, #arg.out do
        local name = arg.out[i]
        if arg.numeric then
            result[name] = tonumber(out[i])
        else
            result[name] = out[i]
        end
    end

    if result.type == 'var' then
        if labels[result.name] then
            result.type = 'immediate'
            result.val = labels[result.name] 
            result.name = nil
        elseif std[result.name] then
            result.type = 'immediate'
            result.val = result.name
            if not stdsymbols[result.name] then
                prelude = prelude .. std[result.name] .. '\n'
                stdsymbols[result.name] = true
            end
            result.name = nil
        elseif externs[result.name] then
            result.type = 'externref'
            result.name = result.name
        else
            error(string.format('invalid identifier: %s', result.name))
        end
    elseif result.type == 'memvar' then
        if labels[result.name] then
            result.type = 'mem'
            result.ptr = labels[result.name] 
        elseif externs[result.name] then
            result.type = 'extern'
            result.name = result.name
        elseif std[result.name] then
            error(string.format('cannot access static std member: %s', result.name))
        else
            error(string.format('invalid identifier: %s', result.name))
        end
    end

    if verbose then
        result.text = expr
    end

    return true
end

local gentype = function(expr, verbose)
    if not string.match(expr, '^%s*$') then
        local found = false
        for _, v in ipairs(arg) do
            local result = {}
            if match_arg(expr, v, result, verbose) then
                return result
            end
        end
    end
    return nil
end

local types = {}
types['reg'] = {pattern = '_R.%s', arg = {'reg'}}
types['immediate'] = {pattern = '%s', arg = {'val'}}
types['mem'] = {pattern = '_D[%d]', arg = {'ptr'}}
types['externref'] = {pattern = '_X["%s"]', arg = {'name'}}
types['extern'] = {pattern = '%s', arg = {'name'}}

local type_to_lua = function(expr, verbose)
    local type = expr.type

    local args = {}
    for _, v in ipairs(types[type].arg) do
        args[#args+1] = expr[v]
    end

    local lua = string.format(types[type].pattern, table.unpack(args))
    return lua
end

local parsearg = function(expr, verbose)
    return type_to_lua(gentype(expr, verbose), verbose)
end

return parsearg
