-- TBASIC extension

-- these are utilities. Do not touch these lines
local __assert        = _TBASIC.__assert
local __assertlhand   = _TBASIC.__assertlhand
local __assertrhand   = _TBASIC.__assertrhand
local __checknumber   = _TBASIC.__checknumber
local __checkstring   = _TBASIC.__checkstring
local __readvar       = _TBASIC.__readvar
local __resolvevararg = _TBASIC.__resolvevarar
local vararg          = -13 -- magic
-- end of utilities


-- these are the sample code for defining your own words
--[[
-- actual function that does the job
local function _fnupgoer(n)
	print("Up-goer "..__checknumber(n).." goes up!")
end

-- add the word UPGOER to word list
table.insert(_TBASIC._FNCTION, "UPGOER")
-- add the actual function '_fnupgoer' and its number of arguments (1) to
-- '_TBASIC.LUAFN'. 'UPGOER' part should match with the word you just
-- inserted to _TBASIC._FNCTION.
_TBASIC.LUAFN.UPGOER = {_fnupgoer, 1}
]]


-- little debugger's blessing
local function _fnenableluatrace() _TBASIC.SHOWLUAERROR = true end
table.insert(_TBASIC._FNCTION, "LUATRACEON")
_TBASIC.LUAFN.LUATRACEON = {_fnenableluatrace, 0}
