-- simple binary search stole and improved from Kotlin Language
-- @param cmpval: function that returns numerical value of the value used for searching.
--         implementation: function(s) return whateverhashornumber(s) end
--                      e.g. function(s) return string.hash(s) end -- for string values
--        you must implement it by yourself!
do -- Avoid heap allocs for performance
    local default_cmp_fn = function(s) return string.hash(tostring(s)) end

    function table.binsearch(t, value, cmpval)
        local low = 1
        local high = #t
        local cmp = cmpval or default_cmp_fn

        local value = cmp(value)

        while low <= high do
            local mid = bit.rshift((low + high), 1)
            local midVal = t[mid]

            if value > cmp(midVal) then
                low = mid + 1
            elseif value < cmp(midVal) then
                high = mid - 1
            else
                return mid -- key found
            end
        end
        return nil -- key not found
    end
end

commands = require "commands"
api = require "basicapi"

_G._TBASIC = {}
_G._TBASIC._VERNUM = 0x0004 -- 0.4
_G._TBASIC._VERSION = tonumber(string.format("%d.%d", bit.rshift(_TBASIC._VERNUM, 8), bit.band(_TBASIC._VERNUM, 0xFF)))
_G._TBASIC._HEADER = string.format("    **** TERRAN BASIC V%d.%d ****    ", bit.rshift(_TBASIC._VERNUM, 8), bit.band(_TBASIC._VERNUM, 0xFF))
_G._TBASIC.PROMPT = function() print("\nREADY.") end
_G._TBASIC._INVOKEERR = function(msg, msg1)
		local e = ""
		if msg1 then
        e = "?L".._G._TBASIC._INTPRTR.PROGCNTR..": "..msg.." "..msg1
    else
        e = "?L".._G._TBASIC._INTPRTR.PROGCNTR..": "..msg, "ERROR"
    end
		print(e)
    if _TBASIC.SHOWLUAERROR then syntaxError(e, false) end
    --os.exit(1) -- terminate
    _G._TBASIC.__appexit = true -- duh, computercraft
end
_G._TBASIC._ERROR = {
    SYNTAX = function() _TBASIC._INVOKEERR("SYNTAX") end,
    SYNTAXAT = function(word) _TBASIC._INVOKEERR("SYNTAX ERROR AT", "'"..word.."'") end,
    TYPE = function() _TBASIC._INVOKEERR("TYPE MISMATCH") end,
    ILLEGALNAME = function(name, reason)
            if reason then
                _TBASIC._INVOKEERR("ILLEGAL NAME: ".."'"..name.."'", "REASON:"..reason)
            else
                _TBASIC._INVOKEERR("ILLEGAL NAME:", "'"..name.."'")
            end
        end,
    ILLEGALARG = function(expected, got)
            if (not expected) and (not got) then
                _TBASIC._INVOKEERR("ILLEGAL QUANTITY")
            elseif not got then
                _TBASIC._INVOKEERR(expected:upper().." EXPECTED")
            else
                _TBASIC._INVOKEERR(expected:upper().." EXPECTED,", "GOT "..got:upper())
            end
        end,
    NOSUCHLINE = function(line) _TBASIC._INVOKEERR("NO SUCH LINE:", line) end,
    NULFN = function(var) _TBASIC._INVOKEERR("UNDEFINED FUNCTION:", "'"..var.."'") end,
    NULVAR = function(var) _TBASIC._INVOKEERR("UNDEFINED VARIABLE:", "'"..var.."'") end,
    DIV0 = function() _TBASIC._INVOKEERR("DIVISION BY ZERO") end,
    NAN = function() _TBASIC._INVOKEERR("NOT A NUMBER") end,
    STACKOVFL = function() _TBASIC._INVOKEERR("TOO MANY RECURSION") end,
    LINETOOBIG = function() _TBASIC._INVOKEERR("TOO BIG LINE NUMBER") end,
    NOLINENUM = function() _TBASIC._INVOKEERR("NO LINE NUMBER") end,
    ABORT = function(reason)
            if reason then
                _TBASIC._INVOKEERR("PROGRAM", "ABORTED: "..reason)
            else
                _TBASIC._INVOKEERR("PROGRAM", "ABORTED")
            end
        end,
    ARGMISSING = function(fname, remark)
            if remark then
                _TBASIC._INVOKEERR("MISSING ARGUMENT(S) FOR", "'"..fname.."' ("..remark..")")
            else
                _TBASIC._INVOKEERR("MISSING ARGUMENT(S) FOR", "'"..fname.."'")
            end
        end,
    NOMATCHING = function(fname, match) _TBASIC._INVOKEERR("'"..fname.."' HAS NO MACTHING", "'"..match.."'") end,
    TOOLONGEXEC = function() _TBASIC._INVOKEERR("TOO LONG WITHOUT YIELDING") end,
    RETURNWOSUB = function() _TBASIC._INVOKEERR("RETURN WITHOUT GOSUB") end,
    NEXTWOFOR = function() _TBASIC._INVOKEERR("NEXT WITHOUT FOR") end,
    ASGONIF = function() _TBASIC._INVOKEERR("ASSIGNMENT ON IF CLAUSE") end,
    SHELLCMD = function() _TBASIC._INVOKEERR("THIS IS A SHELL COMMAND") end,
    IOERR = function() _TBASIC._INVOKEERR("READ/WRITE") end,
    NOSYMFORNEXT = function() _TBASIC._INVOKEERR("NO VAR FOR NEXT CLAUSE") end,

    DEV_FUCKIT = function() _TBASIC._INVOKEERR("FEELING DIRTY") end,
    DEV_UNIMPL = function(fname) _TBASIC._INVOKEERR("UNIMPLEMENTED SYNTAX:", "'"..fname.."'") end
}
_G._TBASIC._FNCTION = { -- aka OPCODES because of some internal-use-only functions
    -- variable control
    "DIM", -- allocates an array
    "DEF", -- defines new function. Synopsis "DEF FN FOOBAR(arg)"
    "FN", -- denotes function
    -- flow control
    "GO", "GOTO", -- considered harmful
    "GOSUB", "RETURN",
    "FOR", "NEXT", "IN",
    "DO", -- reserved only
    "IF", "THEN",
    "LABEL", -- line number alias
    --"ELSE", "ELSEIF", -- reserved only, will not be implemented
    "END", -- terminate program cleanly
    "ABORT", -- break as if an error occured
    "ABORTM", -- ABORT with message
    -- stdio
    "INT", -- integer part of a number (3.78 -> 3, -3.03 -> -3)
    -- string manipulation
    "LEN",
    "LEFT", -- just like in Excel
    "MID", --  -- just like in Excel (substring)
    "RIGHT", -- just like in Excel
    -- type conversion
    "ASC", -- converts a charactor into its code point
    "CHR", -- converts an integer into corresponding character
    "STR", -- number to string
    "VAL", -- string to number
    -- misc
    "REM", -- mark this line as comment
    -- internal use only!!
    "ASSIGNARRAY",
    "READARRAY",

    "CLS"
}
_G._TBASIC._OPERATR = {
    -- operators
    ">>>", "<<", ">>", "|", "&", "XOR", "!", -- bitwise operations
    ";", -- string concatenation
    "==", ">", "<", "<=", "=<", ">=", "=>", -- TURN OFF your font ligature for this part if you're seeing two identical symbols!
    "!=", "<>", "><", -- not equal
    "=", ":=", -- assign
    "AND", "OR", "NOT",
    "^", -- math.pow, 0^0 should return 1.
    "*", "/", "+", "-", -- arithmetic operations
    "%", -- math.fmod
    "TO", "STEP", -- integer sequence operator
    "MINUS", -- unary minus (internal use only!!)
    "+=", "-=", "*=", "/=", "%=" -- C-style assign
}
_G._TBASIC.OPILLEGAL = { -- illegal functions and operators (internal-use-only opcodes)
    "ASSIGNARRAY",
    "READARRAY",
    "MINUS",
}
_G._TBASIC._INTPRTR = {}
_G._TBASIC._INTPRTR.TRACE = false -- print program counter while execution
_G._TBASIC.SHOWLUAERROR = true

local function stackpush(t, v)
    t[#t + 1] = v
end

local function stackpop(t)
    local v = t[#t]
    t[#t] = nil
    return v
end

local function stackpeek(t)
    local v = t[#t]
    return v
end

function string.hash(str) -- FNV-1 32-bit
    local hash = 2166136261
    for i = 1, #str do
        hash = hash * 16777619
        hash = bit.bxor(hash, str:byte(i))
    end
    return hash
end

_G._TBASIC._INTPRTR.RESET = function()
    _TBASIC.__appexit = false
    _TBASIC._INTPRTR.PROGCNTR = 0
    _TBASIC._INTPRTR.MAXLINES = 999999
    _TBASIC._INTPRTR.VARTABLE = {} -- table of variables. [NAME] = data
    _TBASIC._INTPRTR.FNCTABLE = {} -- table of functions. [NAME] = array of strings? (TBA)
    _TBASIC._INTPRTR.CALLSTCK = {} -- return points (line number)
    _TBASIC._INTPRTR.LINELABL = {} -- LABEL statement table
    _TBASIC._INTPRTR.STACKMAX = 2000
    _TBASIC._INTPRTR.CNSTANTS = {
        M_PI    = 3.141592653589793, -- this is a standard implementation
        M_2PI   = 6.283185307179586, -- this is a standard implementation
        M_E     = 2.718281828459045, -- this is a standard implementation
        M_ROOT2 = 1.414213562373095, -- this is a standard implementation
        TRUE = true,
        FALSE = false,
        NIL = nil,
        _VERSION = _TBASIC._VERSION
    }
end



-- FUNCTION IMPLEMENTS --------------------------------------------------------

local function __readvar(varname)
    -- varname could be either real name, or a data
    -- if varname is a string that can be represented as number, returns tonumber(varname) ("4324" -> 4324)
    -- if varname is a TBASIC string, return resolved string ("~FOOBAR" -> "FOOBAR")
    -- if varname is a TBASIC variable, return resolved variable ("$FOO" -> any value stored in variable 'FOO')

    --print("readvar_varname", varname)

    if type(varname) == "table" or type(varname) == "nil" or type(varname) == "boolean" then
        return varname
    end

    if tonumber(varname) then
        return tonumber(varname)
    end

    if varname:byte(1) == 126 then
        return varname:sub(2, #varname)
    end

    if varname:byte(1) == 36 then
        local data = varname:sub(2, #varname)
        if tonumber(data) then
            return tonumber(data)
        else
            -- try for constants
            local retval = _TBASIC._INTPRTR.CNSTANTS[data:upper()]
            if retval ~= nil then return retval
            -- try for variable table
            else return _TBASIC._INTPRTR.VARTABLE[data:upper()] end
        end
    elseif varname:byte(1) == 37 then
        local array = _TBASIC._INTPRTR.VARTABLE[varname:sub(2, #varname):upper()]
        if not array or type(array) ~= "table" then
            return false
        elseif array.identifier == "tbasicarray" then
            return array
        else
            error(varname.." is not an TBASIC array")
        end
    else
        return varname -- already resolved
    end
end

local function __makenewtbasicarray(dimensional)
    local t = {}
    t.dimension = dimensional
    t.data = {} -- this data WILL BE one-based whilst TBASIC is zero-based. BEWARE!
    t.identifier = "tbasicarray"

    return t
end

-- ARRNAME(3,2,4), arguments denote max possible index, starting from zero
function gfnarrayget(arrname, ...)
    local t = __readvar(arrname)

    local function getdimensionalsum(iteration)
        local i = 0
        for dim = iteration, (#t.dimension) - 1 do
            i = i + t.dimension[dim]
        end
        return i
    end

    local indices = {...}
    local actualIndex = 0
    for d = 1, #indices do
        if (d < #indices) then
            actualIndex = actualIndex + getdimensionalsum(d) * indices[d]
        else
            actualIndex = actualIndex + indices[d]
        end
    end

    return t.data[actualIndex + 1] -- actualIndex is zero-based, but t.data is one-based
end

function gfnarrayset(arrname, value, ...)
    local t = __readvar(arrname)

    local function getdimensionalsum(iteration)
        local i = 0
        for dim = iteration, (#t.dimension) - 1 do
            i = i + t.dimension[dim]
        end
        return i
    end

    local indices = {...}

    local actualIndex = 0
    for d = 1, #indices do
        if (d < #indices) then
            actualIndex = actualIndex + getdimensionalsum(d) * indices[d]
        else
            actualIndex = actualIndex + indices[d]
        end
    end

    t.data[actualIndex + 1] = value -- actualIndex is zero-based, but t.data is one-based
end

local function __assert(aarg, expected)
    local arg = __readvar(aarg)

    if type(arg) ~= expected then
        _TBASIC._ERROR.ILLEGALARG(expected, type(arg))
        return
    end
end

local function __assertlhand(llval, expected)
    local lval = __readvar(llval)

    if type(lval) ~= expected then
        _TBASIC._ERROR.ILLEGALARG("LHAND: "..expected, type(lval))
        return
    end
end

local function __assertrhand(rrval, expected)
    local rval = __readvar(rrval)

    if type(rval) ~= expected then
        _TBASIC._ERROR.ILLEGALARG("RHAND: "..expected, type(rval))
        return
    end
end

local function __checknumber(aarg)
    local arg = __readvar(aarg)

    if arg == nil then
        _TBASIC._ERROR.ILLEGALARG("number", type(arg))
        return
    else
        if type(arg) == "table" then
            repeat
                tval = arg[1]
                arg = tval
            until type(tval) ~= "table"
        end

        n = tonumber(arg)
        if n == nil then
            _TBASIC._ERROR.ILLEGALARG("number", type(arg))
            return
        else
            return n
        end
    end
end

local function __checkstring(aarg)
    local arg = __readvar(aarg)

    if type(arg) == "function" then
        _TBASIC._ERROR.ILLEGALARG("STRING/NUMBER/BOOL", type(arg))
        return
    end

    if type(arg) == "table" then
        repeat
            tval = arg[1]
            arg = tval
        until type(tval) ~= "table"
    end

    local strarg = tostring(arg)
    return strarg:byte(1) == 126 and strarg:sub(2, #strarg) or strarg
end

local function __resolvevararg(...)
    local ret = {}
    for _, varname in ipairs({...}) do
        table.insert(ret, __readvar(varname))
    end
    return ret
end

_G._TBASIC.__assert        = __assert
_G._TBASIC.__assertlhand   = __assertlhand
_G._TBASIC.__assertrhand   = __assertrhand
_G._TBASIC.__checknumber   = __checknumber
_G._TBASIC.__checkstring   = __checkstring
_G._TBASIC.__readvar       = __readvar
_G._TBASIC.__resolvevararg = __resolvevararg


--[[
Function implementations

 Cautions:
* Every function that returns STRING must prepend "~"
 ]]

local function _fnprinth(...)
    function printarg(arg)
        if type(arg) == "function" then
            _TBASIC._ERROR.SYNTAX()
            return
        end

        if type(arg) == "boolean" then
            if arg then io.write(" TRUE")
            else io.write(" FALSE") end
        elseif _TBASIC.isstring(arg) then
            io.write(__checkstring(arg))
        elseif _TBASIC.isnumber(arg) then -- if argument can be turned into a number (e.g. 14321, "541")
            io.write(" "..arg)
        elseif type(arg) == "table" then
            printarg(arg[1]) -- recursion
        else
            io.write(tostring(arg))
        end
    end

    local args = __resolvevararg(...)

    if #args < 1 then
        io.write ""
    else
        for i, arg in ipairs(args) do
            if i > 1 then io.write "\t" end

            printarg(arg)
        end
    end

    io.write "\n"
end

local function _fngoto(lnum)
    local linenum = nil
    if _TBASIC.isnumber(lnum) then
        linenum = __checknumber(lnum)
    else
        linenum = _TBASIC._INTPRTR.LINELABL[__checkstring(lnum)]
    end

    if linenum == nil or linenum < 1 then
        _TBASIC._ERROR.NOSUCHLINE(linenum)
        return
    end

    _TBASIC._INTPRTR.PROGCNTR = linenum - 1
end

local function _fnnewvar(varname, value)
    _TBASIC._INTPRTR.VARTABLE[varname:upper()] = __readvar(value)
end

local function _fngosub(lnum)
    local linenum = nil
    if _TBASIC.isnumber(lnum) then
        linenum = __checknumber(lnum)
    else
        linenum = _TBASIC._INTPRTR.LINELABL[__checkstring(lnum)]
    end

    stackpush(_TBASIC._INTPRTR.CALLSTCK, _TBASIC._INTPRTR.PROGCNTR) -- save current line number
    _fngoto(linenum)
end

local function _fnreturn()
    if #_TBASIC._INTPRTR.CALLSTCK == 0 then -- nowhere to return
        _TBASIC._ERROR.RETURNWOSUB()
        return
    end

    local return_line = stackpop(_TBASIC._INTPRTR.CALLSTCK) + 1 -- the line has GOSUB, so advance one
    _fngoto(return_line)
end

local function _fnabort()
    _TBASIC._ERROR.ABORT()
end

local function _fnabortmsg(reason)
    _TBASIC._ERROR.ABORT(__checkstring(__readvar(reason)))
end

local function _fnif(bbool)
    local bool = __readvar(bbool)

    __assert(bool, "boolean")

    if bool == nil then
        _TBASIC._ERROR.ILLEGALARG()
        return
    end

    if not bool then
        _TBASIC._INTPRTR.PROGCNTR = _TBASIC._INTPRTR.PROGCNTR + 1
    end
end

local function _fnnop()
    return
end

local function _fnfor(seq)
    stackpush(_TBASIC._INTPRTR.CALLSTCK, _TBASIC._INTPRTR.PROGCNTR)
end

local function _fnnext(...)
    if #_TBASIC._INTPRTR.CALLSTCK == 0 then -- nowhere to return
        _TBASIC._ERROR.NEXTWOFOR()
        return
    end

    local variables = {...} -- array of strings(varname) e.g. "$X, $Y, $Z"

    -- error if no symbol is specified (a common "mistake")
    if #variables == 0 then
        _TBASIC._ERROR.NOSYMFORNEXT()
    end

    local branch = false
    -- dequeue intsequences
    for i, v in ipairs(variables) do
        local t = nil
        if _TBASIC.isvariable(v) then
            t = _TBASIC._INTPRTR.VARTABLE[v:sub(2, #v)]

            if type(t) ~= "table" then
                _TBASIC._ERROR.ILLEGALARG("ARRAY", type(t))
                return
            end

            table.remove(t, 1)

            -- unassign variable
            if #t == 0 then
                _TBASIC._INTPRTR.VARTABLE[v] = nil
                branch = true
            end
        else
            _TBASIC._ERROR.ILLEGALARG("ARRAY", type(t))
            return
        end
    end

    -- branch? or go back?
    if not branch then
        _fngoto(stackpeek(_TBASIC._INTPRTR.CALLSTCK) + 1) -- the line has FOR statement
    else
        stackpop(_TBASIC._INTPRTR.CALLSTCK) -- dump the stack
    end
end

local function _fnabs(n)
    return math.abs(__checknumber(n))
end

local function _fnsin(n)
    return math.sin(__checknumber(n))
end

local function _fncos(n)
    return math.cos(__checknumber(n))
end

local function _fntan(n)
    return math.tan(__checknumber(n))
end

local function _fntorad(n)
    return math.rad(__checknumber(n))
end

local function _fnascii(char)
    return __checkstring(char):byte(1)
end

local function _fncbrt(n)
    return __checknumber(n)^3
end

local function _fnceil(n)
    return math.ceil(__checknumber(n))
end

local function _fnchar(code)
    return "~"..string.char(__checknumber(code)) -- about "~".. ? read the cautions above!
end

local function _fnfloor(n)
    return math.floor(__checknumber(n))
end

local function _fngetkeycode(...)
    -- TODO get a single character from the keyboard and saves the code of the character to the given variable(s)
end

local function _fnint(n)
    num = __checknumber(n)
    return num >= 0 and math.floor(n) or math.ceil(n)
end

local function _fnmultinv(n) -- multiplicative invert
    return 1.0 / __checknumber(n)
end

local function _fnsubstrleft(str, n)
    return "~"..__checkstring(str):sub(1, __checknumber(n))
end

local function _fnsubstr(str, left, right)
    return "~"..__checkstring(str):sub(__checknumber(left), __checknumber(right))
end

local function _fnsubstrright(str, n)
    return "~"..__checkstring(str):sub(-__checknumber(n))
end

local function _fnlen(var)
    local value = __readvar(var)
    return #value
end

local function _fnloge(n)
    return math.log(__checknumber(n))
end

local function _fnmax(...)
    local args = __resolvevararg(...)
    if #args < 1 then
        _TBASIC._ERROR.ARGMISSING("MAX")
        return
    end

    local max = -math.huge
    for _, i in ipairs(args) do
        local n = __checknumber(i)
        if max < n then max = n end
    end
    return max
end

local function _fnmin(...)
    local args = __resolvevararg(...)
    if #args < 1 then
        _TBASIC._ERROR.ARGMISSING("MIN")
        return
    end

    local min = math.huge
    for _, i in ipairs(args) do
        local n = __checknumber(i)
        if min > n then min = n end
    end
    return min
end

local function _fnrand()
    return math.random()
end

local function _fnround(n)
    return math.floor(__checknumber(n) + 0.5)
end

local function _fnsign(n)
    local num = __checknumber(n)
    return num > 0 and 1.0 or num < 0 and -1.0 or 0.0
end

local function _fnsqrt(n)
    return __checknumber(n)^(0.5)
end

local function _fntostring(n)
    local ret = tostring(__checknumber(n))
    if not ret then
        _TBASIC._ERROR.ILLEGALARG()
        return
    else
        return "~"..ret
    end
end

local function _fntonumber(s)
    if tonumber(s) then return s end
    return tonumber(__checkstring(s))
end

local function _fntan(n)
    return math.tan(__checknumber(n))
end

local function _fninput(...) -- INPUT(var1, [var2, var3 ...])
    local args = {...}
    local prompt = "YOUR INPUT ? "
    local prompt_numbered = "YOUR INPUT (%d OF %d) ? "

    function prompt_and_get_input()
        -- if there's two or more input, a number will be shown
        if #args >= 2 then
            io.write(string.format(prompt_numbered, argcount, #args))
        else
            io.write(prompt)
        end
        io.flush() -- print out the line right away

        local value = io.read()

        return value
    end

    if #args < 1 then
        _TBASIC._ERROR.ARGMISSING("INPUT")
        return
    else
        for argcount, varname in ipairs(args) do
            local inputvalue = nil
            while inputvalue == nil or inputvalue == "" do
                inputvalue = prompt_and_get_input()
                _opassign(varname, inputvalue)
            end
        end
    end
end

local function _fnlabel(lname)
    _TBASIC._INTPRTR.LINELABL[__checkstring(lname)] = _TBASIC._INTPRTR.PROGCNTR
end

-- dim(max_index, max_index, ...)
local function _fndim(...)
    local args = {...}
    local varname = args[1]
    local dimensional = {}
    for i, v in ipairs(args) do
        if i > 1 then
            dimensional[i - 1] = v + 1 -- stores size, not max_index
        end
    end

    _opassign(varname, __makenewtbasicarray(dimensional))
end

local function _fnassignarray(arrname, value, ...)
    gfnarrayset(arrname, value, ...)
end

local function _fnreadarray(arrname, ...)
    return gfnarrayget(arrname, ...)
end


-- OPERATOR IMPLEMENTS --------------------------------------------------------

local function booleanise(bool)
    return bool and "$TRUE" or "$FALSE"
end

function _opconcat(llval, rrval)
    local lval = __readvar(llval)
    local rval = __readvar(rrval)

    if type(lval) == "function" then _TBASIC._ERROR.ILLEGALARG("VALUE", "FUNCTION") return end
    if type(rval) == "function" then _TBASIC._ERROR.ILLEGALARG("VALUE", "FUNCTION") return end

    local l = (type(lval) == "string" and lval:byte(1)) == 126 and lval:sub(2, #lval) or __checkstring(lval)
    local r = (type(rval) == "string" and rval:byte(1)) == 126 and rval:sub(2, #rval) or __checkstring(rval)

    return "~"..l..r
end

function _opplus(lval, rval)
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return l + r
end

function _optimes(lval, rval)
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return l * r
end

function _opminus(lval, rval)
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return l - r
end

function _opdiv(lval, rval)
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    if r == 0 then
        _TBASIC._ERROR.DIV0()
        return
    else
        return _optimes(l, 1.0 / r)
    end
end

function _opmodulo(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return math.fmod(l, r)
end

function _oppower(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return math.pow(l, r) -- 0^0 is 1 according to the spec, and so is the Lua's.
end

function _opassign(var, value)
    if _TBASIC.isnumber(var) or _TBASIC.isfunction(var) or _TBASIC.isoperator(var) or _TBASIC.isargsep(var) then
        _TBASIC._ERROR.ILLEGALNAME(var)
        return
    end

    -- remove uncaught "$"
    local varname = var:byte(1) == 36 and var:sub(2, #var) or var

    -- if it still has "$", the programmer just broke the law
    if varname:byte(1) == 36 then
        _TBASIC._ERROR.ILLEGALNAME(varname, "HAS ILLEGAL CHARACTER '$'")
        return
    end

    _TBASIC._INTPRTR.VARTABLE[varname:upper()] = __readvar(value)
end

function _opeq(llval, rrval)
    local lval = __readvar(llval)
    local rval = __readvar(rrval)

    if tonumber(lval) and tonumber(rval) then
        return booleanise(tonumber(lval) == tonumber(rval))
    else
        return booleanise(__checkstring(lval) == __checkstring(rval))
    end
end

function _opne(llval, rrval)
    local lval = __readvar(llval)
    local rval = __readvar(rrval)

    if tonumber(lval) and tonumber(rval) then
        return booleanise(tonumber(lval) ~= tonumber(rval))
    else
        return booleanise(__checkstring(lval) ~= __checkstring(rval))
    end
end

function _opgt(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return booleanise(l > r)
end

function _oplt(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return booleanise(l < r)
end

function _opge(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return booleanise(l >= r)
end

function _ople(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return booleanise(l <= r)
end

function _opband(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return bit.band(l, r)
end

function _opbor(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return bit.bor(l, r)
end

function _opbxor(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return bit.bxor(l, r)
end

function _opbnot(val)
    local expected = "number"
    local v = __checknumber(val)

    return bit.bnot(v)
end

function _oplshift(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return bit.lshift(l, r)
end

function _oprshift(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return bit.arshift(l, r)
end

function _opurshift(lval, rval)
    local expected = "number"
    local l = __checknumber(lval)
    local r = __checknumber(rval)

    return bit.rshift(l, r)
end

function _opland(lhand, rhand)
    return booleanise(__readvar(lhand) and __readvar(rhand))
end

function _oplor(lhand, rhand)
    return booleanise(__readvar(lhand) or __readvar(rhand))
end

function _oplnot(rhand)
    return booleanise(not __readvar(rhand))
end

function _opintrange(x, y) -- x TO y -> {x..y}
    local from = __checknumber(x)
    local to   = __checknumber(y)

    local seq = {}
    if from < to then
        for i = from, to do
            table.insert(seq, i)
        end
    else
        for i = from, to, -1 do
            table.insert(seq, i)
        end
    end

    return seq
end

function _opintrangestep(sseq, sstp) -- i know you can just use "for i = from, to, step"
    local seq = __readvar(sseq)
    local stp = __readvar(sstp)
    local step = __checknumber(stp)      -- but that's just how not this stack machine works...
    __assert(seq, "table")

    if step == 1 then return seq end
    if step < 1 then _TBASIC._ERROR.ILLEGALARG() return end

    local newseq = {}
    for i, v in ipairs(seq) do
        if i % step == 1 then
            table.insert(newseq, v)
        end
    end

    return newseq
end

function _opunaryminus(n)
    local num = __checknumber(n)
    return -num
end

function _opplusassign(var, value)
    if type(__readvar(var)) == "number" then
        _opassign(var, __readvar(var) + __checknumber(value))
    else
        _TBASIC._ERROR.ILLEGALARG()
        return
    end
end

function _opminusassign(var, value)
    if type(__readvar(var)) == "number" then
        _opassign(var, __readvar(var) - __checknumber(value))
    else
        _TBASIC._ERROR.ILLEGALARG()
        return
    end
end

function _optimesassign(var, value)
    if type(__readvar(var)) == "number" then
        _opassign(var, __readvar(var) * __checknumber(value))
    else
        _TBASIC._ERROR.ILLEGALARG()
        return
    end
end

function _opdivassign(var, value)
    if type(__readvar(var)) == "number" then
        if __checknumber(value) == 0 then
            _TBASIC._ERROR.DIV0()
            return
        else
            _opassign(var, __readvar(var) / __checknumber(value))
        end
    else
        _TBASIC._ERROR.ILLEGALARG()
        return
    end
end

function _opmodassign(var, value)
    if type(__readvar(var)) == "number" then
        if __checknumber(value) == 0 then
            _TBASIC._ERROR.DIV0()
            return
        else
            _opassign(var, math.fmod(__readvar(var), __checknumber(value)))
        end
    else
        _TBASIC._ERROR.ILLEGALARG()
        return
    end
end

_G._TBASIC.LUAFN = {
    -- variable control
    CLR     = {function() _TBASIC._INTPRTR.VARTABLE = {} end, 0},
    DIM     = {_fndim, vararg},
    ASSIGNARRAY = {_fnassignarray, vararg},
    READARRY = {_fnreadarray, vararg},
    -- flow control
    IF      = {_fnif, 1},
    THEN    = {_fnnop, 0},
    GOTO    = {_fngoto, 1},
    GOSUB   = {_fngosub, 1},
    RETURN  = {_fnreturn, 0},
    END     = {function() _G._TBASIC.__appexit = true end, 0},
    ABORT   = {_fnabort, 0},
    ABORTM  = {_fnabortmsg, 1},
    FOR     = {_fnfor, 1},
    NEXT    = {_fnnext, vararg},
    LABEL   = {_fnlabel, 1},
    -- string manipulation
    LEFT    = {_fnsubstrleft, 2},
    LEN     = {_fnlen, 1},
    MID     = {_fnsubstr, 3},
    RIGHT   = {_fnsubstrright, 2},
    -- type conversion
    ASC     = {_fnascii, 1},
    CHR     = {_fnchar, 1},
    STR     = {_fntostring, 1},
    VAL     = {_fntonumber, 1},
    ---------------
    -- operators --
    ---------------
    [";"]   = {_opconcat, 2},
    ["+"]   = {_opplus, 2},
    ["*"]   = {_optimes, 2},
    ["-"]   = {_opminus, 2},
    ["/"]   = {_opdiv, 2},
    ["%"]   = {_opmodulo, 2},
    ["^"]   = {_oppower, 2},
    ["=="]  = {_opeq, 2},
    ["!="]  = {_opne, 2}, ["<>"] = {_opne, 2}, ["><"] = {_opne, 2},
    [">="]  = {_opge, 2}, ["=>"] = {_opge, 2},
    ["<="]  = {_ople, 2}, ["=<"] = {_ople, 2},
    [">"]   = {_opgt, 2},
    ["<"]   = {_oplt, 2},
    ["="]   = {_opassign, 2}, [":="] = {_opassign, 2},
    ["+="]  = {_opplusassign, 2}, ["-="] = {_opminusassign, 2},
    ["*="]  = {_optimesassign, 2}, ["/="] = {_opdivassign, 2}, ["%="] = {_opmodassign, 2},
    MINUS   = {_opunaryminus, 1},
    -- logical operators
    AND     = {_opland, 2},
    OR      = {_oplor, 2},
    NOT     = {_oplnot, 1},
    -- bit operators
    ["<<"]  = {_oplshift, 2},
    [">>"]  = {_oprshift, 2}, -- bit.arshift
    [">>>"] = {_opurshift, 2}, -- bit.rshift
    ["|"]   = {_opbor, 2},
    ["&"]   = {_opband, 2},
    ["!"]   = {_opbnot, 1},
    XOR     = {_opbxor, 2},
    -- int sequence
    TO      = {_opintrange, 2},
    STEP    = {_opintrangestep, 2},
    -- misc
    REM     = {_fnnop, 0}
}


_G._TBASIC._GETARGS = function(func)
    local f = _TBASIC.LUAFN[func]
    if f == nil then return nil end
    return f[2]
end

-- PARSER IMPL ----------------------------------------------------------------

local opprecedence = {
    {":=", "=", "+=", "-=", "*=", "/=", "%="}, -- least important
    {"OR"},
    {"AND"},
    {"|"},
    {"XOR"},
    {"&"},
    {"==", "!=", "<>", "><"},
    {"<=", ">=", "=<", "=>", "<", ">"},
    {"TO", "STEP"},
    {">>>", "<<", ">>"},
    {";"},
    {"+", "-"},
    {"*", "/", "%"},
    {"NOT", "!"},
    {"^"}, -- most important
    {"MINUS"}
}
local opassoc = {
    rtl = {";", "^", "NOT", "!"}
}
local function exprerr(token)
    _TBASIC._ERROR.SYNTAXAT(token)
end
function _op_precd(op)
    -- take care of prematurely prepended '#'
    local t1 = op:byte(1) == 35 and op:sub(2, #op) or op
    op = t1:upper()

    for i = 1, #opprecedence do
        for _, op_in_quo in ipairs(opprecedence[i]) do
            if op == op_in_quo then
                return i
            end
        end
    end
    exprerr("precedence of "..op)
end

function _op_isrtl(op)
    for _, v in ipairs(opassoc.rtl) do
        if op == v then return true end
    end
    return false
end

function _op_isltr(op)
    return not _op_isrtl(op)
end



function _G._TBASIC.isnumber(token)
    return tonumber(token) and true or false
end

function _G._TBASIC.isoperator(token)
    if token == nil then return false end

    -- take care of prematurely prepended '#'
    local t1 = token:byte(1) == 35 and token:sub(2, #token) or token
    token = t1

    for _, tocheck in ipairs(_TBASIC._OPERATR) do
        if tocheck == token:upper() then return true end
    end
    return false
end

function _G._TBASIC.isvariable(word)
    if type(word) == "number" then return false end
    if type(word) == "boolean" then return true end
    if type(word) == "table" then return true end
    if word == nil then return false end
    return word:byte(1) == 36
end

function _G._TBASIC.isargsep(token)
    return token == ","
end

function _G._TBASIC.isfunction(token)
    if token == nil then return false end

    -- take care of prematurely prepended '&'
    local t1 = token:byte(1) == 38 and token:sub(2, #token) or token
    token = t1

    -- try for builtin
    local cmpval = function(table_elem) return string.hash(table_elem) end

    local found = table.binsearch(_TBASIC._FNCTION, token, cmpval)

    if found then
        return true
    end

    -- try for user-defined functions
    found = table.binsearch(_TBASIC._INTPRTR.FNCTABLE, token, cmpval)
    if found then -- found is either Table or Nil. We want boolean value.
        return true
    else
        return false
    end
end

function _G._TBASIC.isstring(token)
    if type(token) ~= "string" then return false end
    return token:byte(1) == 126
end

function _G._TBASIC.isarray(token)
    if token:byte(1) == 37 then
        return true
    else
        local var = __readvar("%"..token)
        return type(var) == "table" and var.identifier == "tbasicarray"
    end
end



local function printdbg(...)
    local debug = false
    if debug then print("TBASINCL", ...) end
end


-- implementation of the Shunting Yard algo
_G._TBASIC.TORPN = function(exprarray)
    local stack = {}
    local outqueue = {}

    local loophookkeylist = {}
    local function infloophook(key)
        if not _G[key] then
            _G[key] = 0
            table.insert(loophookkeylist, key)
        end
        _G[key] = _G[key] + 1

        if _G[key] > 50000 then
            error(key..": too long without yielding")
        end
    end

    local isfunction = _TBASIC.isfunction
    local isoperator = _TBASIC.isoperator
    local isargsep   = _TBASIC.isargsep
    local isnumber   = _TBASIC.isnumber
    local isstring   = _TBASIC.isstring
    local isarray    = _TBASIC.isarray

    for _, token in ipairs(exprarray) do--expr:gmatch("[^ ]+") do
        if token == nil then error("Token is nil!") end

        -- hack: remove single prepended whitespace
        t1 = token:byte(1) == 32 and token:sub(2, #token) or token
        token = t1

        printdbg("TOKEN", "'"..token.."'")
        if isfunction(token:upper()) then
            printdbg("is function")

            stackpush(stack, "&"..token:upper())
        elseif isarray(token:upper()) then
            printdbg("is array")

            stackpush(stack, "%"..token:upper())
        elseif isargsep(token) then
            printdbg("is argument separator")

            if not (stackpeek(stack) == "(" or #stack == 0) then
            repeat
                stackpush(outqueue, stackpop(stack))

                infloophook("repeat1")
            until stackpeek(stack) == "(" or #stack == 0
            end
            -- no left paren encountered, ERROR!
            if #stack == 0 then exprerr(token) end -- misplaces sep or mismatched parens
        elseif isoperator(token) then
            printdbg("is operator")

            local o1 = token

            while isoperator(stackpeek(stack)) and (
                        (_op_isltr(o1) and _op_precd(o1) <= _op_precd(stackpeek(stack))) or
                        (_op_isrtl(o1) and _op_precd(o1) <  _op_precd(stackpeek(stack)))
                    ) do
                local o2 = stackpeek(stack)

                printdbg("--> push o2 to stack, o2:", o2)

                stackpop(stack) -- drop
                stackpush(outqueue, (o2:byte(1) == 35) and o2 or "#"..o2:upper()) -- try to rm excess '#'

                infloophook("while")
            end

            stackpush(stack, "#"..o1:upper())
        elseif token == "(" then
            stackpush(stack, token)
        elseif token == ")" then
            while stackpeek(stack) ~= "(" do
                if #stack == 0 then
                    exprerr(token)
                end

                printdbg("--> stack will pop", stackpeek(stack))

                stackpush(outqueue, stackpop(stack))

                infloophook("")
            end

            printdbg("--> will drop", stackpeek(stack), "(should be left paren!)")

            --[[found_left_paren = false
            if stackpeek(stack) ~= "(" then
                exprerr(token)
            else
                found_left_paren = true
            end]]
            stackpop(stack) -- drop

            printdbg("--> stack peek after drop", stackpeek(stack))

            if isfunction(stackpeek(stack)) then
                printdbg("--> will enq fn", stackpeek(stack))
                stackpush(outqueue, stackpop(stack))
            end
            printdbg("--> STACKTRACE_ITMD", table.concat(stack, " "))
            printdbg("--> OUTPUT_ITMD", table.concat(outqueue, " "))

            -- stack empty without finding left paren, ERROR!
            --if not found_left_paren and #stack == 0 then exprerr(token) end -- mismatched parens
        elseif isstring(token) or isnumber(token) then
            printdbg("is data")
            stackpush(outqueue, token) -- arbitrary data
        else -- a word without '~' or anything; assume it's a variable name
            printdbg("is variable")
            stackpush(outqueue, "$"..token:upper())
        end
        printdbg("STACKTRACE", table.concat(stack, " "))
        printdbg("OUTPUT", table.concat(outqueue, " "))
        printdbg()
    end

    while #stack > 0 do
        if stackpeek(stack) == "(" or stackpeek(stack) == ")" then
            exprerr("(paren)") -- mismatched parens
        end
        stackpush(outqueue, stackpop(stack))

        infloophook("while3")
    end

    printdbg("FINAL RESULT: "..table.concat(outqueue, " "))

    for _, key in ipairs(loophookkeylist) do
        _G[key] = nil
    end

    return outqueue
end


-- INIT -----------------------------------------------------------------------

-- load extensions
local status, err = pcall(
    function()
        if os and os.loadAPI then -- ComputerCraft
            os.loadAPI "TBASEXTN.lua"
        else
            require "libs.terran-basic.TBASEXTN"
        end
    end
)
if err then
    error(err)
end


--sort builtin keywords list
table.sort(_TBASIC._FNCTION, function(a, b) return string.hash(a) < string.hash(b) end)


_G._TBASIC.INIT = function ()
	for n, f in pairs(apiList) do
		n = string.upper(n)
		table.insert(_TBASIC._FNCTION, n)

		if f[2] == vararg then
			_TBASIC.LUAFN[n] = { function(...)
				local args = __resolvevararg(...)
				f[1](args)
			end, f[2] }
		else
			_TBASIC.LUAFN[n] = { f[1], f[2] }
		end
	end

	_G._TBASIC._INTPRTR.RESET()
end

--[[
Terran BASIC (TBASIC)
Copyright (c) 2016-2017 Torvald (minjaesong) and the contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the Software), to deal in the
Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
