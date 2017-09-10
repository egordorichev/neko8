
local mklabel = function(name, value)
    label = label + 1
    labels[name] = label
    return string.format('_D[%d]=%s', label, value or '')
end

local mkext = function(name)
    externs[name] = label
    return string.format('_X["%s"]=%s', name, name)
end

local comp = {}
comp['do'] = {pattern = 'do', arg = {}}
comp['end'] = {pattern = 'end', arg = {}}
comp['loop'] = {pattern = '_R.c=_R.c+1;while _R.c>1 do _R.c=_R.c-1', arg = {}}
comp['if'] = {pattern = 'if _R.f.%s then', arg = {'cond'}}
comp['while'] = {pattern = 'while _R.f.%s do', arg = {'cond'}}
comp['until'] = {pattern = 'until _R.f.%s', arg = {'cond'}}

local section = 'text'
local parseop = require(root .. 'include/parseop')
local expr_to_lua = function(expr, verbose)
    local type = expr.type

    if type == 'section' then
        section = expr.name
        return ''
    elseif type == 'op' then -- TODO
        return parseop(expr, verbose)
    elseif type == 'def' then
        return mklabel(expr.name, expr.val)
    elseif type == 'extern' then
        return mkext(expr.name)
    elseif type == 'label' then
        return mklabel(expr.name) .. 'function()'
    else
        local args = {}
        for _, v in ipairs(comp[type].arg) do
            args[#args+1] = expr[v]
        end

        return string.format(comp[type].pattern, table.unpack(args))
    end
end

local assemble = function(ast, verbose)
    local dst = ''

    local err = false

    for _, v in ipairs(ast) do
        local lua
        local status, result = pcall(expr_to_lua, v, verbose)
        if status then
            lua = result
            if verbose and verbose >= 2 then
                lua = string.format(' -- line %d\n -- %s\n%s\n', v.linen, v.text, lua)
            elseif verbose then
                lua = string.format('%s -- %s', lua, v.text)
            end
            dst = dst .. lua .. '\n'
        else
            print(string.format('invalid expression: %s\n' ..
                                '           at line: %d', v.text, v.linen))
            err = true
        end
    end

    if err then
        error('invalid expression(s) in source file')
    end

    return dst
end

return assemble
