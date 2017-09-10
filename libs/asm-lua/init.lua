
local boilerplate = [[
_R={a=0,b=0,c=0,d=0,ss='\0',ds='\0',f={gt=false,lt=false,ge=false,le=false,eq=false,ne=false,err=false,syserr=false},sp=65536}
_X={}
_D={}
local asmcmp=function(a,b) return {lt=a<b,gt=a>b,le=a<=b,ge=a>=b,eq=a==b,ne=a~=b,err=false,syserr=false} end
local asmtest=function(a) local eq=a==0; return {lt=false,gt=false,le=eq,ge=eq,eq=eq,ne=not eq,err=false,syserr=false} end
local asmnot=function() return {lt=not _R.f.lt,gt=not _R.f.gt,le=not _R.f.le,ge=not _R.f.ge,eq=not _R.f.eq,ne=not _R.f.ne,err=false,syserr=false} end
]]

table.unpack = table.unpack or unpack

prelude = [[]]
local name = ...
root = string.gsub(name, '/init$', '') .. '/'
std = require(root .. 'include/std')

label = 0x0
labels = {}
externs = {}

stdsymbols = {}

local parseline = require(root .. 'include/parseline')
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

local assemble = require(root .. 'include/assemble')
local compile = function(src, verbose)
    prelude = [[]]

    local ast = genast(src, verbose)
    local asm = assemble(ast, verbose)

    return boilerplate .. prelude .. asm
end

return {compile = compile}
