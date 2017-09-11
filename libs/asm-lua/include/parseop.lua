
local ops = {}
ops['mov'] = {pattern = '%s=%s', arg = {'a', 'b'}}
ops['call'] = {pattern = '_R.f.syserr=not pcall(%s)', arg = {'a'}}
ops['callx'] = {pattern = '_Xargs={}\n' ..
                          'local n=%d\n' ..
                          '_R.sp=_R.sp-n\n' ..
                          'for i=0,n-1 do _Xargs[i+1]=_D[_R.sp+i] end\n' ..
                          '_R.f.syserr=not pcall(%s,table.unpack(_Xargs))\n' ..
                          '_Xargs=nil', arg = {'b', 'a'}}
ops['ret'] = {pattern = 'return', arg = {}}
ops['push'] = {pattern = '_D[_R.sp]=%s;_R.sp=_R.sp+1', arg = {'a'}}
ops['pop'] = {pattern = '_R.sp=_R.sp-1;%s=_D[_R.sp]', arg = {'a'}}
ops['cmp'] = {pattern = '_R.f=asmcmp(%s,%s)', arg = {'a', 'b'}}
ops['test'] = {pattern = '_R.f=asmtest(%s)', arg = {'a'}}
ops['not'] = {pattern = '_R.f=asmnot()', arg = {}}
ops['cmpl'] = {pattern = '%s=bit.bnot(%s)', arg = {'a', 'a'}}
ops['and'] = {pattern = '%s=bit.band(%s,%s)', arg = {'a', 'a', 'b'}}
ops['or'] = {pattern = '%s=bit.bor(%s,%s)', arg = {'a', 'a', 'b'}}
ops['xor'] = {pattern = '%s=bit.bxor(%s,%s)', arg = {'a', 'a', 'b'}}
ops['nand'] = {pattern = '%s=bit.bnot(bit.band(%s,%s))', arg = {'a', 'a', 'b'}}
ops['nor'] = {pattern = '%s=bit.bnot(bit.bor(%s,%s))', arg = {'a', 'a', 'b'}}
ops['xnor'] = {pattern = '%s=bit.bnot(bit.bxor(%s,%s))', arg = {'a', 'a', 'b'}}
ops['shl'] = {pattern = '%s=bit.lshift(%s,%s)', arg = {'a', 'a', 'b'}}
ops['shr'] = {pattern = '%s=bit.rshift(%s,%s)', arg = {'a', 'a', 'b'}}
ops['rol'] = {pattern = '%s=bit.rol(%s,%s)', arg = {'a', 'a', 'b'}}
ops['ror'] = {pattern = '%s=bit.ror(%s,%s)', arg = {'a', 'a', 'b'}}
ops['inc'] = {pattern = '%s=%s+1', arg = {'a', 'a'}}
ops['dec'] = {pattern = '%s=%s-1', arg = {'a', 'a'}}
ops['add'] = {pattern = '%s=%s+%s', arg = {'a', 'a', 'b'}}
ops['sub'] = {pattern = '%s=%s-%s', arg = {'a', 'a', 'b'}}
ops['mul'] = {pattern = '%s=%s*%s', arg = {'a', 'a', 'b'}}
ops['div'] = {pattern = '%s=%s/%s', arg = {'a', 'a', 'b'}}

local neko8 = false

local parsearg = require(_ASM.root .. 'include/parsearg')
local parseop = function(expr, verbose)
    if _ASM.neko8 and not neko8 then
        neko8 = true
        for k, v in pairs(ops) do
            v.pattern = string.gsub(v.pattern, 'table%.unpack', 'unpck')
            v.pattern = string.gsub(v.pattern, 'bit%.([^b])', 'b%1')
        end
    end

    local err = false

    for k, v in pairs(expr) do
        if k == 'a' or k == 'b' or k == 'c' then
            local status, result = pcall(parsearg, v, verbose)
            if status then
                expr[k] = result
            else
                print(result)
                err = true
            end
        end
    end

    if err then
        error('invalid operator(s) in source file')
    end

    local op = expr.op

    local args = {}
    for _, v in ipairs(ops[op].arg) do
        args[#args+1] = expr[v]
    end

    local lua = string.format(ops[op].pattern, table.unpack(args))
    return lua
end

return parseop
