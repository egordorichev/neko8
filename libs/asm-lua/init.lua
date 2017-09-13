
local prelude = [[
_R={a=0,b=0,c=0,d=0,ss='\0',ds='\0',f={gt=false,lt=false,ge=false,le=false,eq=false,ne=false,err=false,syserr=false},sp=65536}
_X={}
_D={}
_P={}
_PD={}
_MMAP={{a=0,b=0,set=function()end,get=function()end},{a=1,b=81920,set=function(p,x) _D[p]=x end,get=function(p) return _D[p] end}}
_M=function(p,x)
for i=#_MMAP,1,-1 do
 local v=_MMAP[i]
 if p>=v.a and p<=v.b then
  if x then v.set(p,x) else return v.get(p) end
 end
end
end
local id=function(...) return ... end
local asmcmp=function(a,b) return {lt=a<b,gt=a>b,le=a<=b,ge=a>=b,eq=a==b,ne=a~=b,err=false,syserr=false} end
local asmtest=function(a) local eq=a==0; return {lt=false,gt=false,le=eq,ge=eq,eq=eq,ne=not eq,err=false,syserr=false} end
local asmnot=function() return {lt=not _R.f.lt,gt=not _R.f.gt,le=not _R.f.le,ge=not _R.f.ge,eq=not _R.f.eq,ne=not _R.f.ne,err=false,syserr=false} end
local unpck=table and table.unpack or unpack or unpck
if not bit then
bit={}
bit.bnot=id
bit.band=id
bit.bor=id
bit.bxor=id
bit.lshift=id
bit.rshift=id
bit.rol=id
bit.ror=id
end
]]

local port_std = [[
_P[0x100]=function(a) _PD[0x100]=os.execute(a) end
_P[0x101]=function(a) os.exit(a) end
_P[0x102]=function(a) _PD[0x102]=os.getenv(a) end
_P[0x103]=function() _PD[0x103]=os.time() end
]]

_ASM = {}

table.unpack = table.unpack or unpack

local name = ...
_ASM.root = string.gsub(name, '/init$', '') .. '/'

_ASM.label = 0x0
_ASM.labels = {}
_ASM.externs = {}

local parseline = require(_ASM.root .. 'include/parseline')
local genast = function(src, verbose)
    local line = 1
    local ast = {}
    local iter
    if type(src) == 'string' then
        iter = string.gmatch(src, '[^\n]*')
    elseif type(src) == 'function' then
        iter = src
    end

    local err = false
    for expr in iter do
        expr = string.gsub(expr, '%s*%-%-.*$', '')
        status, result = pcall(parseline, expr, verbose, line)
        if status and result then
            ast[#ast+1] = result
        elseif not status then
            print(result)
            err = true
        end
        line = line + 1
    end
    
    if err then
        error('invalid expression(s) in source file')
    end

    return ast
end

local assemble = require(_ASM.root .. 'include/assemble')
local compile = function(src, verbose, std, ports, mmap)
    _ASM.std = nil

    local prelude = prelude
    if type(std) == 'table' then
        _ASM.std = std
    elseif type(std) == 'string' then
        _ASM.std = {std}
    elseif std then
        _ASM.std = require(_ASM.root .. 'include/std')
        prelude = prelude .. port_std
    end

    if _ASM.std then
        for _, v in pairs(_ASM.std) do
            prelude = prelude .. v .. '\n'
        end
    end

    local ast = genast(src, verbose)
    local asm = assemble(ast, verbose)

    if ports then
        for _, v in ipairs(ports) do
            prelude = prelude .. string.format('_P[%d]=%s\n',
                v.port or v[1], v.func or v[2])
        end
    end

    if mmap then
        for _, v in ipairs(mmap) do
            prelude = prelude .. string.format(
                '_MMAP[#_MMAP+1]={a=%d,b=%d,set=%s,get=%s}\n',
                v.min or v[1],
                v.max or v[2],
                v.set or v[3] or 'function()end',
                v.get or v[4] or 'function()end')
        end
    end
    
    return prelude .. '\n' .. asm
end

return {compile = compile}
