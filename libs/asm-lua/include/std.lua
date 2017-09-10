
local std = {}

-- base operations, included in prelude
std.include = [[local include=function() require(_R.ss) end]]
std.putc = [[local putc=function() io.write(string.sub(_R.ss,1,1)) end]]
std.puts = [[local puts=function() print(_R.ss) end]]
std.endl = [[local endl=function() io.write('\n') end]]
std.sprintf = [[local sprintf=function()
local args={}
_R.sp=_R.sp-_R.a
for i=0,_R.a-1 do args[i+1]=_D[_R.sp+i] end
_R.ds=string.format(_R.ss,table.unpack(args))
end]]
std.printf = [[local printf=function() sprintf();io.write(_R.ds) end]]
std.itoa = [[local itoa=function() _R.ds=tostring(_R.a) end]]
std.atoi = [[local atoi=function() _R.ds=tostring(_R.a) end]]
std.memset = [[local memset=function() for i=0,_R.c-1 do _D[_R.b+i]=_R.a end end]]
std.memcpy = [[local memcpy=function() for i=0,_R.c-1 do _D[_R.b+i]=_D[_R.a+i] end end]]
std.memcmp = [[local memcmp=function() for i=0,_R.c-1 do local a=_D[_R.a+i]-_D[_R.b+i];ifa=0 then _R.a=a;return end end;_R.a=0 end]]

-- math
std.abs = [[local abs=function() _R.a=math.abs(_R.a) end]]
std.mod = [[local mod=function() _R.a=math.mod(_R.a,_R.d) end]]
std.floor = [[local floor=function() _R.a=math.floor(_R.a) end]]
std.round = [[local round=function() _R.a=math.floor(_R.a+.5) end]]
std.ceil = [[local ceil=function() _R.a=math.ceil(_R.a) end]]
std.min = [[local min=function() _R.a=math.min(_R.a,_R.d) end]]
std.max = [[local max=function() _R.a=math.max(_R.a,_R.d) end]]

std.sqrt = [[local sqrt=function() _R.a=math.sqrt(_R.a) end]]
std.pow = [[local pow=function() _R.a=math.pow(_R.a,_R.d) end]]
std.exp = [[local exp=function() _R.a=math.exp(_R.a) end]]
std.log = [[local log=function() _R.a=math.log(_R.a) end]]
std.log10 = [[local log10=function() _R.a=math.log10(_R.a) end]]

std.deg = [[local deg=function() _R.a=math.deg(_R.a) end]]
std.rad = [[local rad=function() _R.a=math.rad(_R.a) end]]
std.sin = [[local sin=function() _R.a=math.sin(_R.a) end]]
std.cos = [[local cos=function() _R.a=math.cos(_R.a) end]]
std.tan = [[local tan=function() _R.a=math.tan(_R.a) end]]
std.asin = [[local asin=function() _R.a=math.asin(_R.a) end]]
std.acos = [[local acos=function() _R.a=math.acos(_R.a) end]]
std.atan = [[local atan=function() _R.a=math.atan(_R.a) end]]
std.atan2 = [[local atan2=function() _R.a=math.atan2(_R.a,_R.d) end]]

-- string
std.strlen = [[local strlen=function() _R.a=string.len(_R.ss) end]]
std.strsub = [[local strsub=function() _R.ds=string.sub(_R.ss,_R.a,_R.b-1) end]]
std.strrep = [[local strrep=function() _R.ds=string.rep(_R.ss,_R.a) end]]
std.strup = [[local strup=function() _R.ds=string.upper(_R.ss) end]]
std.strlow = [[local strlow=function() _R.ds=string.lower(_R.ss) end]]
std.strfind = [[local strfind=function() _R.a,_R.c=string.find(_R.ss,_R.ds);_R.c=_R.c-_R.a+1 end]]
std.strmatch = [[local strmatch=function() _R.ds=string.find(_R.ss,_R.ds) end]]

std.ord = [[local ord=function() _R.a=string.byte(_R.ss,1,1) end]]
std.chr = [[local chr=function() _R.ds=string.char(_R.a) end]]

-- os functions, to be made into syscalls
std.system = [[local system=function() _R.a=os.execute(_R.ss) end]]
std.exit = [[local exit=function() os.exit(_R.b) end]]
std.env = [[local env=function() _R.ds=os.getenv(_R.ss) end]]
std.time = [[local time=function() _R.a=os.time() end]]

return std
