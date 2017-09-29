local code = {}
local lume = require "libs.lume"

local tw = 40
local th = 20

function code.init()
	code.lines = {}
	code.t = 0
	code.lines[1] = ""
	code.icon = 8
	code.name = "code editor"
	code.bg = config.editors.code.bg

	code.select = {
		start = {
			x = -1,
			y = -1
		},

		finish = {
			x = -1,
			y = -1
		},

		active = false
	}

	code.cursor = {
		x = 0,
		y = 0
	}

	code.view = {
		x = 0,
		y = 0
	}
end

function code.open()
	code.forceDraw = true
end

function code._draw()
	if code.forceDraw then
		code.redraw()
		code.forceDraw = false
	end

	editors.drawUI()
	code.drawInfo()
end

local function cursorBlink()
	return code.t < 16 or code.t % 30 < 16
end

function code._update()
	local lb = cursorBlink()
	code.t = code.t + 1

	if cursorBlink() ~= lb then
		code.redraw()
	end

	lmb = mb
	mx, my, mb = api.mstat(1)
	mx = mx + code.view.x * 4
	my = my + code.view.y * 6

	if mb then
		if not lmb or code.select.start.x == -1 then
			code.select.start.x = api.flr((mx - 1) / 4)
			code.select.start.y = api.flr((my - 8) / 6)

			code.select.start.y = api.mid(
				0, api.max(1, #code.lines - 1), code.select.start.y
			)

			code.select.start.x = api.mid(
				0, #code.lines[code.select.start.y + 1],
				code.select.start.x
			)
		end

		if lmb or code.select.finish.x == -1 then
			code.select.finish.x = api.flr((mx - 1) / 4)
			code.select.finish.y = api.flr((my - 8) / 6)

			code.select.finish.y = api.mid(
				0, api.max(1, #code.lines - 1), code.select.finish.y
			)

			code.select.finish.x = api.mid(
				0, #code.lines[code.select.finish.y + 1],
				code.select.finish.x
			)
		end

		code.select.active =
			api.abs(code.select.start.x - code.select.finish.x) > 0
			or api.abs(code.select.start.y - code.select.finish.y) > 0

		code.cursor.x = code.select.finish.x
		code.cursor.y = code.select.finish.y
		code.checkCursor()

		code.forceDraw = true
	end
end

local function colorPrint(b, c)
	for i = 1, #b do
		local cx, cy = api.cget()
		local c = c[i] or 6

		if c then
			api.color(c)
		end
		api.print(b:sub(i, i), true, false)
	end

	api.print("")
	api.cursor(1 - code.view.x * 4)
end

function code.redraw()
	api.cls(config.editors.code.bg)

	local buffer = lume.clone(
		lume.slice(
			code.lines, code.view.y + 1,
			code.view.y + th - 1
		)
	)

	local cbuffer = code.colorizeLines(
		buffer,
		config.editors.code.colors
	)

	api.cursor(1 - code.view.x * 4, 9)

	local c = config.editors.code.colors.select

	if code.select.active then
		if code.select.finish.y - code.select.start.y == 0 then
			api.rectfill(
				code.select.start.x * 4 - code.view.x * 4,
				code.select.start.y * 6 + 9 - code.view.y * 6,
				code.select.finish.x * 4 - code.view.x * 4,
				(code.select.start.y + 1) * 6 + 8 - code.view.y * 6,
				c
			)
		else
			local min = code.select.start.y
				> code.select.finish.y and
				code.select.finish
				or code.select.start

			local max = code.select.start.y
				< code.select.finish.y and
				code.select.finish
				or code.select.start

			api.rectfill(
				min.x * 4 - code.view.x * 4,
				min.y * 6 + 9 - code.view.y * 6,
				#code.lines[min.y + 1] * 4 - code.view.x * 4,
				(min.y + 1) * 6 + 8 - code.view.y * 6,
				c
			)

			for y = min.y + 1, max.y - 1 do
				api.rectfill(
					-code.view.x * 4,
					y * 6 + 9 - code.view.y * 6,
					#code.lines[y + 1] * 4 - code.view.x * 4,
					(y + 1) * 6 + 8 - code.view.y * 6,
					c
				)
			end

			api.rectfill(
				-code.view.x * 4,
				max.y * 6 + 9 - code.view.y * 6,
				max.x * 4 - code.view.x * 4,
				(max.y + 1) * 6 + 8 - code.view.y * 6,
				c
			)
		end
	end

	for i = 1, #buffer do
		colorPrint(buffer[i], cbuffer[i])
	end

	local cx = code.cursor.x
			- code.view.x

	local cy = code.cursor.y
			- code.view.y

	if cursorBlink() then
		api.rectfill(
			cx * 4,
			cy * 6 + 8,
			cx * 4 + 4,
			cy * 6 + 14,
			config.editors.code.cursor
		)
	end

	api.line(
		0, config.canvas.height - 7,
		config.canvas.width,
		config.canvas.height - 7,
		config.editors.code.bg
	)

	api.line(
		0, 8, config.canvas.width,
		8, config.editors.code.bg
	)
end

function code.drawInfo()
	api.print(
		string.format(
			"line %d/%d, char %d/%d",
			code.cursor.y + 1, #code.lines,
			code.cursor.x,
			#code.lines[code.cursor.y + 1]
		),
		1, config.canvas.height - 6,
		config.editors.ui.fg
	)

	local total = 0

	for i = 1, #code.lines do
		total = total + #code.lines[i]
	end

	local s = string.format(
		"%d/65536 chars", total
	)

	api.print(
		s,
		config.canvas.width - (#s + 1) * 4 - 2,
		config.canvas.height - 6,
		config.editors.ui.fg
	)
end

function code.close()

end

function code._keydown(k)
	if api.key("rctrl") or api.key("lctrl") then
		if k == "s" then
			commands.save()
		elseif k == "a" then
			code.select.active = true
			code.select.start = { x = 0, y = 0 }
			code.select.finish = {
				x = #code.lines[api.max(1, #code.lines - 1)],
				y = api.max(1,#code.lines - 1)
			}

			code.forceDraw = true
		end
	else
		local shift = api.key("lshift") or api.key("rshift")

		if k == "left" then
			local lastX = code.cursor.x
			local lastY = code.cursor.y

			code.cursor.x = code.cursor.x - 1
			code.t = 0
			code.checkCursor()

			if shift then
				if not code.select.active then
					code.select.active = true
					code.select.start.x = lastX
					code.select.start.y = lastY
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				else
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				end
			else
				code.select.active = false
			end
		elseif k == "right" then
			local lastX = code.cursor.x
			local lastY = code.cursor.y

			code.cursor.x = code.cursor.x + 1
			code.t = 0
			code.checkCursor()

			if shift then
				if not code.select.active then
					code.select.active = true
					code.select.start.x = lastX
					code.select.start.y = lastY
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				else
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				end
			else
				code.select.active = false
			end
		elseif k == "up" then
			local lastX = code.cursor.x
			local lastY = code.cursor.y

			code.cursor.y = code.cursor.y - 1
			code.t = 0
			code.checkCursor()

			if shift then
				if not code.select.active then
					code.select.active = true
					code.select.start.x = lastX
					code.select.start.y = lastY
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				else
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				end
			else
				code.select.active = false
			end
		elseif k == "down" then
			local lastX = code.cursor.x
			local lastY = code.cursor.y

			code.cursor.y = code.cursor.y + 1
			code.t = 0
			code.checkCursor()

			if shift then
				if not code.select.active then
					code.select.active = true
					code.select.start.x = lastX
					code.select.start.y = lastY
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				else
					code.select.finish.x = code.cursor.x
					code.select.finish.y = code.cursor.y
				end
			else
				code.select.active = false
			end
		elseif k == "return" or k == "kpenter" then
			if code.select.active then
				code.replaceSelected("")
			end

			local cx, cy = code.cursor.x, code.cursor.y
			local newLine = code.lines[cy + 1]:sub(cx + 1, -1)

			code.lines[cy + 1] = code.lines[cy + 1]:sub(0, cx)

			local snum = string.find(code.lines[cy + 1] .. "a", "%S")
			snum = snum and snum - 1 or 0
			newLine = string.rep(" ", snum) .. newLine

			code.cursor.x, code.cursor.y = snum, cy + 1

			cx = code.cursor.x
			cy = code.cursor.y

			if cy + 1 > #code.lines then
				api.add(code.lines, newLine)
			else
				code.lines = lume.concat(
					lume.slice(
						code.lines, 0, cy
					), { newLine },
					lume.slice(
						code.lines, cy + 1, -1
					)
				)
			end
			code.t = 0
			code.checkCursor()
		elseif k == "home" then
			code.cursor.x = 0
			code.t = 0
			code.checkCursor()
		elseif k == "end" then
			code.cursor.x = #code.lines[code.cursor.y + 1]
			code.t = 0
			code.checkCursor()
		elseif k == "pagedown" then
			code.cursor.y = code.cursor.y + th
			code.checkCursor()
			code.cursor.x = #code.lines[code.cursor.y + 1]
			code.t = 0
		elseif k == "pageup" then
			code.cursor.y = code.cursor.y - th
			code.cursor.x = 0
			code.t = 0
			code.checkCursor()
		elseif k == "backspace" then
			if code.select.active then
				code.replaceSelected("")
				return
			end
			if #code.lines[code.cursor.y + 1] > 0
				and code.cursor.x > 0 then
				code.lines[code.cursor.y + 1] =
					code.lines[code.cursor.y + 1]
					:sub(1, code.cursor.x - 1)
					.. code.lines[code.cursor.y + 1]
					:sub(
						code.cursor.x + 1,
						#code.lines[code.cursor.y + 1]
					)

				code.cursor.x = code.cursor.x - 1
			elseif code.cursor.y > 0 then
				local l1 = code.lines[code.cursor.y]
				local l2 = code.lines[code.cursor.y + 1]

				table.remove(code.lines, code.cursor.y + 1)

				if code.lines[code.cursor.y]
					and l1 and l2 then

					code.lines[code.cursor.y] = l1 .. l2
					code.cursor.x = #l1
					code.cursor.y = code.cursor.y - 1
				end
			end
			code.t = 0
			code.checkCursor()
		elseif k == "tab" then
			code._text(" ")
			code.t = 0
		elseif k == "delete" then
			code.t = 0

			if code.select.active then
				code.replaceSelected("")
				return
			end

			if #code.lines[code.cursor.y + 1] > 0
				and code.cursor.x < #code.lines[code.cursor.y + 1] then
				code.lines[code.cursor.y + 1] =
					code.lines[code.cursor.y + 1]
					:sub(1, code.cursor.x)
					.. code.lines[code.cursor.y + 1]
					:sub(
						code.cursor.x + 2,
						#code.lines[code.cursor.y + 1]
					)
			elseif code.cursor.y + 1 < #code.lines then
				local l1 = code.lines[code.cursor.y + 1]
				local l2 = code.lines[code.cursor.y + 2]

				table.remove(code.lines, code.cursor.y + 1)

				if l1 and l2 then
					code.lines[code.cursor.y + 1] = l1 .. l2
				end
			end
		end
	end
	code.redraw()
end

function code.replaceSelected(text)
	if code.select.finish.y - code.select.start.y == 0 then
		local min = code.select.start.x
			> code.select.finish.x and
			code.select.finish
			or code.select.start

		local max = code.select.start.x
			< code.select.finish.x and
			code.select.finish
			or code.select.start

		local line = code.lines[min.y + 1]
		local newLine

		if min.x == 0 then
			newLine = text
		else
			newLine = line:sub(0, min.x) ..
				text
		end

		code.lines[min.y + 1] =
			newLine ..
			line:sub(max.x + 1, #line)

		code.cursor.x = #newLine
		code.checkCursor()
	else
		local min = code.select.start.y
			> code.select.finish.y and
			code.select.finish
			or code.select.start

		local max = code.select.start.y
			< code.select.finish.y and
			code.select.finish
			or code.select.start

		local line = code.lines[min.y + 1]
		local newLine

		if min.x > 0 then
			newLine = line:sub(0, min.x) .. text
		else
			newLine = text
		end

		for y = min.y, max.y do
			table.remove(code.lines, min.y + 1)
		end

		table.insert(code.lines, min.y + 1, newLine)

		code.cursor.x = #newLine
		code.cursor.y = min.y
		code.checkCursor()
	end

	code.select.active = false
end

function code._copy()
	if code.select.active then
		local text = ""

		if code.select.finish.y - code.select.start.y == 0 then
			local min = code.select.start.x
				> code.select.finish.x and
				code.select.finish
				or code.select.start

			local max = code.select.start.x
				< code.select.finish.x and
				code.select.finish
				or code.select.start

			local line = code.lines[min.y + 1]
			text = line:sub(min.x + 1, max.x)
		else
			local min = code.select.start.y
				> code.select.finish.y and
				code.select.finish
				or code.select.start

			local max = code.select.start.y
				< code.select.finish.y and
				code.select.finish
				or code.select.start

			local line = code.lines[min.y + 1]
			text = line:sub(min.x, #line)

			local m = 1

			for y = min.y + 2, max.y do
				text = text .. "\n" .. code.lines[y]
			end

			text = text .. "\n" .. code.lines[max.y + m]:sub(0, max.x)
		end

		code.forceDraw = true
		code.select.active = false

		return text
	end
end

function code._cut()
	local active = code.select.active
	local text = code._copy()

	if active then
		code.select.active = true
		code.replaceSelected("")
	end

	return text
end

function code._text(text)
	--text = text:gsub("\t", " ")
	local parts = {}

	for p in text:gmatch("[^\r\n]+") do
		table.insert(parts, p)
	end

	if #parts > 0 then
		for i, part in ipairs(parts) do
			if code.select.active then
				code.replaceSelected(part)
			else
				code.lines[code.cursor.y + 1] =
				code.lines[code.cursor.y + 1]:sub(
				1, code.cursor.x) .. part
				.. code.lines[code.cursor.y + 1]:sub(
					code.cursor.x + 1, #code.lines[
						code.cursor.y + 1
					]
				)

				code.cursor.x = code.cursor.x + #text
			end

			code.checkCursor()

			if #parts > 1 then
				if i < #parts then
					table.insert(code.lines, code.cursor.y + 1, "")
				end
			end

			code.select.active = false
		end

		if #parts > 1 then
			code.cursor.y = code.cursor.y - 1
			code.cursor.x = #code.lines[code.cursor.y + 1]
		end

		code.checkCursor()
	else
		if code.select.active then
			code.replaceSelected(text)
		else
			code.lines[code.cursor.y + 1] =
			code.lines[code.cursor.y + 1]:sub(
			1, code.cursor.x) .. text
			.. code.lines[code.cursor.y + 1]:sub(
				code.cursor.x + 1, #code.lines[
					code.cursor.y + 1
				]
			)

			code.cursor.x = code.cursor.x + #text
			code.checkCursor()
		end
	end

	code.t = 0
	code.redraw()
end

function code._wheel(a)
	if a < 0 then
		code.view.y = api.max(0, api.min(code.view.y + 1, #code.lines - th + 2))
	elseif a > 0 then
		code.view.y = api.max(code.view.y - 1, 0)
	end

	code.t = 0
	code.forceDraw = true
end

function code.checkCursorY()
	code.cursor.y =
		api.mid(
			0, code.cursor.y,
			api.max(1, #code.lines - 1)
		)

	if code.cursor.y > th + code.view.y - 3 then
		code.view.y = code.cursor.y - (th - 3)
		return true
	elseif code.cursor.y < code.view.y then
		code.view.y = code.cursor.y
		return true
	end

	return false
end

function code.checkCursorX(j)
	local f = false

	if code.cursor.x < 0 then
		code.cursor.x = 0
		if code.cursor.y > 0 then
			code.cursor.y = code.cursor.y - 1
			f = code.checkCursorY()
			code.cursor.x = #code.lines[code.cursor.y + 1]
		end
	elseif code.cursor.x >
		#code.lines[code.cursor.y + 1] then

		if code.cursor.y + 1 < #code.lines
			and not j then
			code.cursor.y = code.cursor.y + 1
			f = code.checkCursorY()
			code.cursor.x = 0
		else
			code.cursor.x = #code.lines[code.cursor.y + 1]
		end
	end

	if code.cursor.x > code.view.x + tw - 5 then
		code.view.x = code.cursor.x - tw + 5
		f = true
	elseif code.cursor.x < code.view.x + 5 then
		code.view.x = api.max(0, code.cursor.x - 5)
		f = true
	end

	return f
end

function code.checkCursor(j)
	code.checkCursorY()
	code.checkCursorX(j)
end

local function lines(s)
	if s:sub(-1) ~= "\n" then
		s = s .. "\n"
	end

	return s:gmatch("(.-)\n")
end

function code.import(c)
	code.lines = {}

	c = c:gsub("\t", " ")
	-- todo: doesn't work?

	for l in lines(c) do
		api.add(code.lines, l)
	end

	if not code.lines[1] then
		code.lines[1] = ""
	end
end

function code.export()
	local data = {}

	for l in api.all(code.lines) do
		table.insert(data, l)
		table.insert(data, "\n")
	end

	return table.concat(data)
end

function code.colorizeLines(lines, ct)
	local colors = {}

	for i = 1, #lines do
		colors[i] = code.colorize(lines[i], ct)
	end

	return colors
end

function code.colorize(line, ct)
	local colors = {}

	if neko.loadedCart.lang == "lua" then
		code.highlightNonChars(line, colors, ct)
		code.highlightLuaKeywords(line, colors, ct)
		code.highlightAPI(line, colors, ct)
		code.highlightNumbers(line, colors, ct)
		code.highlightSigns(line, colors, ct)
		code.highlightLuaComments(line, colors, ct)
		code.highlightStrings(line, colors, "\"", ct)
	elseif neko.loadedCart.lang == "basic" then
		code.highlightNonChars(line, colors, ct)
		code.highlightBasicKeywords(line, colors, ct)
		code.highlightBasicAPI(line, colors, ct)
		code.highlightNumbers(line, colors, ct)
		code.highlightSigns(line, colors, ct)
		code.highlightBasicComments(line, colors, ct)
		code.highlightStrings(line, colors, "\"", ct)
	elseif neko.loadedCart.lang == "asm" then
		code.highlightNonChars(line, colors, ct)
		code.highlightAsmKeywords(line, colors, ct)
		code.highlightAPI(line, colors, ct)
		code.highlightNumbers(line, colors, ct)
		code.highlightSigns(line, colors, ct)
		code.highlightAsmComments(line, colors, ct)
		code.highlightStrings(line, colors, "\"", ct)
	else

	end

	return colors
end

function code.foreach(line, f)
	for i = 1, #line do
		f(line:sub(i, i), i)
	end
end

function code.highlightNonChars(line, colors, ct)
	code.foreach(line, function(c, x, y)
		if string.byte(c) < 32 then
			colors[x][y] = ct.other
		end
	end)
end

local function isLetter(c)
	return c and c:match("%a")
end

local function isNumber(c)
	return c and (tonumber(c) ~= nil)
end

local function isDot(c)
	return c and c == "."
end

local function isNil(c)
	return not isLetter(c) and not isNumber(c) and not isDot(c)
end

function code.highlightWords(line, colors, words, color)
	-- todo: check if no char is before, like
	-- cdsasLS() will mark LS blue
	-- that's wrong

	for i = 1, #line do
		local c = line:sub(i, i)
		local start = i

		if isNil(line:sub(i - 1, i - 1)) then
			while i <= #line and (isLetter(c) or isNumber(c)) do
				i = i + 1
				c = line:sub(i, i)
			end

			local w = line:sub(start, i - 1)

			for j = 1, #words do
				local word = words[j]

				if word == w then
					for k = start, i - 1 do
						colors[k] = color
					end
					break
				end
			end
		end
	end
end

local luaKeywords = {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "goto", "if",
	"in", "local", "nil", "not", "or", "repeat",
	"return", "then", "true", "until", "while"
}

function code.highlightLuaKeywords(line, colors, ct)
	code.highlightWords(line, colors, luaKeywords, ct.keyword)
end

function code.highlightAPI(line, colors, ct)
	code.highlightWords(line, colors, apiNamesOnly, ct.api)
end

function code.highlightNumbers(line, colors, ct)
	for i = 1, #line do
		local c = line:sub(i, i)
		local start = i

		if isNil(line:sub(i - 1, i - 1)) and isNumber(c) then
			while i <= #line and (isNumber(c) or isDot(c)) do
				i = i + 1
				c = line:sub(i, i)
			end

			if not isLetter(line:sub(i, i)) then
				for k = start, i - 1 do
					colors[k] = ct.number
				end
			end
		end
	end
end

local signs = {
	{ "+", 1 },
	{ "-", 1 },
	{ "*", 1 },
	{ "/", 1 },
	{ "^", 1 },
	{ "#", 1 },
	{ "%", 1 },
	{ "&", 1 },
	{ "~", 1 },
	{ "|", 1 },
	{ "<<", 2 },
	{ ">>", 2 },
	{ "//", 2 },
	{ "==", 2 },
	{ "+=", 2 },
	{ "-=", 2 },
	{ "~=", 2 },
	{ "<=", 2 },
	{ ">=", 2 },
	{ "<", 1 },
	{ ">", 1 },
	{ "=", 1 },
	{ "(", 1 },
	{ ")", 1 },
	{ "{", 1 },
	{ "}", 1 },
	{ "[", 1 },
	{ "]", 1 },
	{ "::", 2 },
	{ ";", 1 },
	{ ":", 1 },
	{ ",", 1 },
	{ ".", 1 },
	{ "..", 2 },
	{ "...", 3 }
}

local function esc(x)
  return  x:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

function code.highlightSigns(line, colors, ct)
	for i = 1, #signs do
		local sign = signs[i]
		local sg = esc(sign[1])
		local start = 1

 		repeat
			start = line:find(sg, start)

			if start then
				for j = start, start + sign[2] - 1 do
					colors[j] = ct.token
				end
				start = start + sign[2]
			end
		until not start
	end
end

function code.highlightLuaComments(line, colors, ct)
	code.highlightCommentsBase(line, colors, "--", "\n", 0, ct.comment)
	code.highlightCommentsBase(line, colors, "--[[", "]]", 2, ct.comment)
	-- todo: multiline
end

function code.highlightCommentsBase(line, colors, start, finish, extra, clr)
	for i = 1, #line do
		local s = line:find(start, i, true)

		if s then
			local f = line:find(finish, s + 1, true)

			if not f then
				f = #line
				-- todo
			else
				f = f + extra
			end

			for j = s, f do
				colors[j] = clr
			end
		end
	end
end

function code.highlightStrings(line, colors, del, ct, s)
	local start

	if s then
		start = string.find(line, del, s, true)
	else
		start = string.find(line, del, s, true)
	end

	if start then
		local finish = string.find(line, del, start + 1, true)

		if finish then
			for i = start, finish do
				if colors[i] ~= ct.comment then
					colors[i] = ct.string
				end
			end

			code.highlightStrings(line, colors, del, ct, finish + 1)
		end
	end
end

local basicKeywords = {
	"LET", "DATA", "IF", "THEN", "ELSE",
	"FOR", "TO", "NEXT", "WHILE", "WEND", "REPEAT	",
	"UNTIL", "DO", "LOOP", "GOTO", "GOSUB", "ON",
	"DEF", "END"
}

function code.highlightBasicKeywords(line, colors, ct)
	code.highlightWords(line, colors, basicKeywords, ct.keyword)
end

function code.highlightBasicComments(line, colors, ct)
	code.highlightCommentsBase(line, colors, "`", "\n", 0, ct.comment)
	-- is this right? o_O not too sure
end

function code.highlightBasicAPI(line, colors, ct)
	code.highlightWords(line, colors, apiNamesOnlyUpperCase, ct.api)
end

local asmKeywords = {
	"if", "then", "end", "until", "repeat",
	"while", "loop", "ret", "extern"
}

function code.highlightAsmKeywords(line, colors, ct)
	code.highlightWords(line, colors, asmKeywords, ct.keyword)
end

function code.highlightAsmComments(line, colors, ct)
	code.highlightCommentsBase(line, colors, "--", "\n", 0, ct.comment)
end

return code