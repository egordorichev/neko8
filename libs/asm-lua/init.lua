
local boilerplate = [[
_R={a=0,b=0,c=0,d=0,ss='\0',ds='\0',f={gt=false,lt=false,ge=false,le=false,eq=false,ne=false,err=false,syserr=false},sp=65536}
_X={}
_D={}
local asmcmp=function(a,b) return {lt=a<b,gt=a>b,le=a<=b,ge=a>=b,eq=a==b,ne=a~=b,err=false,syserr=false} end
local asmtest=function(a) local eq=a==0; return {lt=false,gt=false,le=eq,ge=eq,eq=eq,ne=not eq,err=false,syserr=false} end
local asmnot=function() return {lt=not _R.f.lt,gt=not _R.f.gt,le=not _R.f.le,ge=not _R.f.ge,eq=not _R.f.eq,ne=not _R.f.ne,err=false,syserr=false} end
]]

local neko8_prelude = [[
local printh=function() printh(_R.ss) end
local csize=function() _R.a,_R.d = csize() end
local rect=function() rect(_R.a,_R.b,_R.c,_R.d) end
local rectfill=function() rectfill(_R.a,_R.b,_R.c,_R.d) end
local brect=function() brect(_R.a,_R.b,_R.c,_R.d) end
local brectfill=function() brectfill(_R.a,_R.b,_R.c,_R.d) end
local color=function() color(_R.a) end
local cls=cls
local circ=function() circ(_R.a,_R.b,_R.d) end
local circfill=function() circfill(_R.a,_R.b,_R.d) end
local pset=function() pset(_R.a,_R.b) end
local pget=function() _R.a=pget(_R.a,_R.b) end
local line=function() line(_R.a,_R.b,_R.c,_R.d) end
local print=function() print(_R.ss) end
local flip=flip
local cursor=function() cursor(_R.a,_R.b) end
local cget=function() _R.a,_R.b=cget() end
local scroll=function() scroll(_R.a) end
local spr=function() spr(_R.d, _R.a, _R.b) end
local sspr=sspr
local sget=function() _R.a=sget(_R.a, _R.b) end
local sset=function() sset(_R.a, _R.b, _R.d) end
local pal=pal
local palt=palt
local map=map
local btn=function() _R.f.eq=btn(_R.ss) end
local btnp=btnp
local key=function() _R.f.eq=key(_R.ss) end

local memset=function() for i=0,_R.c-1 do _D[_R.b+i]=_R.a end end
local memcpy=function() for i=0,_R.c-1 do _D[_R.b+i]=_D[_R.a+i] end end
local memcmp=function() for i=0,_R.c-1 do local a=_D[_R.a+i]-_D[_R.b+i];if a~=0 then _R.a=a;return end end;_R.a=0 end

local strlen=function() _R.a=_R.ss:len() end
local strsub=function() _R.ds=_R.ss:sub(_R.a,_R.b-1) end
local strrep=function() _R.ds=_R.ss:rep(_R.a) end
local strup=function() _R.ds=_R.ss:upper() end
local strlow=function() _R.ds=_R.ss:lower() end
local strfind=function() _R.a,_R.c=_R.ss:find(_R.ds);_R.c=_R.c-_R.a+1 end
local strmatch=function() _R.ds=_R.ss:find(_R.ds) end
]]

_ASM = {}

table.unpack = table.unpack or unpack

_ASM.prelude = [[]]
local name = ...
_ASM.root = string.gsub(name, '/init$', '') .. '/'
_ASM.std = require(_ASM.root .. 'include/std')

_ASM.label = 0x0
_ASM.labels = {}
_ASM.externs = {}

_ASM.stdsymbols = {}

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
local compile = function(src, verbose, neko8)
    _ASM.prelude = [[]]
    _ASM.neko8 = neko8

    local ast = genast(src, verbose)
    local asm = assemble(ast, verbose)

    if neko8 then
        return boilerplate .. neko8_prelude .. asm
    else
        return boilerplate .. _ASM.prelude .. asm
    end
end

return {compile = compile}
