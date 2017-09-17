
local vi = {}
vi.commands = {}
vi.modes = {}
vi.kmaps = {}
local lume = require "libs.lume"
local colorize = require "libs.colorize"

local tw = 40
local th = 20

function vi.init()
	vi.mode = "normal"
	vi.shift = false
	vi.ctrl = false
	vi.count = nil
	vi.needMotion = false
	vi.operator = nil
	vi.motion = nil
	vi.escape = 0.0
	vi.escapeTimeout = 1.5
	vi.currentRegister = nil
	vi.registers = {['"'] = ""}
	vi.command = ""

	vi.lines = {}
	vi.t = 0
	vi.lines[1] = ""
	vi.icon = 8
	vi.name = "viNeko"
	vi.bg = config.editors.vi.bg

	vi.select = {
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

	vi.cursor = {
		x = 0,
		y = 0
	}

	vi.cursorReal = {
		x = 0,
		y = 0
	}

	vi.cursorEx = {
		x = 0,
		y = 0
	}

	vi.view = { -- haha vi-ew get it. **vi** - ew: view
		x = 0,
		y = 0
	}

	if config.editors.vi.virc then
		config.editors.vi.virc(vi)
	end
end

function vi.register()
	local register = vi.currentRegister or '"'
	vi.currentRegister = nil
	return register
end

function vi.reg(register, value)
	register = register or vi.register()
	if value then
		vi.registers[register] = tostring(value)
		return vi.registers[register]
	else
		return vi.registers[register] or ""
	end
end

function vi.line()
	return vi.lines[vi.cursor.y + 1]
end

function vi.getcount()
	local count = vi.count or 1
	vi.count = nil
	return count
end

function vi.commands.nmap(key, func)
	vi.kmaps.normal[key] = vi.modes.normal[func]
end

function vi.commands.imap(key, func)
	vi.kmaps.insert[key] = vi.modes.insert[func]
end

function vi.commands.cmap(key, func)
	vi.kmaps.command[key] = vi.modes.command[func]
end

function vi.commands.w(filename)
	commands.save(filename)
end

function vi.open()
	vi.forceDraw = true
	vi.tryClose = false
end

function vi._draw()
	if vi.forceDraw then
		vi.redraw()
		vi.forceDraw = false
	end

	editors.drawUI()
	vi.drawInfo()
end

local function cursorBlink()
	return vi.t < 16 or vi.t % 30 < 16
end

function vi._update(dt)
	if vi.tryClose then
		vi.escape = vi.escape + dt
		if vi.escape >= vi.escapeTimeout then
			vi.escape = 0
			vi.tryClose = false
		end
	end

	local lb = cursorBlink()
	vi.t = vi.t + 1

	if cursorBlink() ~= lb then
		vi.redraw()
	end

	lmb = mb
	mx, my, mb = api.mstat(1)
	mx = mx + vi.view.x * 4
	my = my + vi.view.y * 6

	if mb then
		if not lmb or vi.select.start.x == -1 then
			vi.select.start.x = api.flr((mx - 1) / 4)
			vi.select.start.y = api.flr((my - 8) / 6)

			vi.select.start.y = api.mid(
				0, api.max(1, #vi.lines - 1), vi.select.start.y
			)

			vi.select.start.x = api.mid(
				0, #vi.lines[vi.select.start.y + 1],
				vi.select.start.x
			)
		end

		if lmb or vi.select.finish.x == -1 then
			vi.select.finish.x = api.flr((mx - 1) / 4)
			vi.select.finish.y = api.flr((my - 8) / 6)

			vi.select.finish.y = api.mid(
				0, api.max(1, #vi.lines - 1), vi.select.finish.y
			)

			vi.select.finish.x = api.mid(
				0, #vi.lines[vi.select.finish.y + 1],
				vi.select.finish.x
			)
		end

		vi.select.active =
			api.abs(vi.select.start.x - vi.select.finish.x) > 0
			or api.abs(vi.select.start.y - vi.select.finish.y) > 0

		vi.setCursor(vi.select.finish.x, vi.select.finish.y)

		vi.forceDraw = true
	end
end

local function highlight(lines)
	return colorize(
		lines,
		config.editors.vi.colors
	)
end

local function colorPrint(tbl)
	for i = 1, #tbl, 2 do
		local cx, cy = api.cget()

		api.color(tbl[i])
		api.print(tbl[i + 1], true, false)
	end

	api.print("")
	api.cursor(1 - vi.view.x * 4)
end

function vi.redraw()
	api.cls(config.editors.vi.bg)

	local buffer = lume.clone(
		lume.slice(
			vi.lines, vi.view.y + 1,
			vi.view.y + th - 1
		)
	)

	buffer = highlight(buffer)

	api.cursor(1 - vi.view.x * 4, 9)

	local c = config.editors.vi.colors.select

	if vi.select.active then
		if vi.select.finish.y - vi.select.start.y == 0 then
			api.rectfill(
				vi.select.start.x * 4 - vi.view.x * 4,
				vi.select.start.y * 6 + 9 - vi.view.y * 6,
				vi.select.finish.x * 4 - vi.view.x * 4,
				(vi.select.start.y + 1) * 6 + 8 - vi.view.y * 6,
				c
			)
		else
			local min = vi.select.start.y
				> vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			local max = vi.select.start.y
				< vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			api.rectfill(
				min.x * 4 - vi.view.x * 4,
				min.y * 6 + 9 - vi.view.y * 6,
				#vi.lines[min.y + 1] * 4 - vi.view.x * 4,
				(min.y + 1) * 6 + 8 - vi.view.y * 6,
				c
			)

			for y = min.y + 1, max.y - 1 do
				api.rectfill(
					-vi.view.x * 4,
					y * 6 + 9 - vi.view.y * 6,
					#vi.lines[y + 1] * 4 - vi.view.x * 4,
					(y + 1) * 6 + 8 - vi.view.y * 6,
					c
				)
			end

			api.rectfill(
				-vi.view.x * 4,
				max.y * 6 + 9 - vi.view.y * 6,
				max.x * 4 - vi.view.x * 4,
				(max.y + 1) * 6 + 8 - vi.view.y * 6,
				c
			)
		end
	end

	for l in api.all(buffer) do
		colorPrint(l)
	end

	local cx = vi.cursor.x - vi.view.x
	local cy = vi.cursor.y - vi.view.y

	if vi.mode ~= "command" then
		if cursorBlink() then
			api.rectfill(
				cx * 4,
				cy * 6 + 8,
				cx * 4 + 4,
				cy * 6 + 14,
				config.editors.vi.cursor
			)
		end
	end

	api.line(
		0, config.canvas.height - 7,
		config.canvas.width,
		config.canvas.height - 7,
		config.editors.vi.bg
	)

	api.line(
		0, 8, config.canvas.width,
		8, config.editors.vi.bg
	)

	if vi.mode == "command" then
		api.rectfill(
			0, config.canvas.height - 12,
			config.canvas.width, config.canvas.height - 6,
			config.editors.ui.bg
		)
	end
end

function vi.drawInfo()
	if vi.tryClose then
		api.print(
			"press escape again to quit",
			1, config.canvas.height - 6 * (20 - th + 1),
			config.editors.ui.fg
		)
	else
		local cx = vi.cursor.x
		if #vi.line() > 0 then
			cx = cx + 1
		end

		api.print(
			string.format(
				"%s line %d/%d, char %d/%d",
				vi.mode,
				vi.cursor.y + 1, #vi.lines,
				cx, #vi.line()
			),
			1, config.canvas.height - 6 * (20 - th + 1),
			config.editors.ui.fg
		)

		if vi.mode == "command" then
			api.print(
				string.format(":%s", vi.command),
				1, config.canvas.height - 6,
				config.editors.ui.fg
			)

			if cursorBlink() then
				local cx = vi.cursorEx.x + 1
				local cy = th
				api.rectfill(
					cx * 4,
					cy * 6 + 8,
					cx * 4 + 4,
					cy * 6 + 14,
					config.editors.vi.cursor
				)
			end
		end
	end
end

function vi.close()

end

function vi.requestClose()
	if vi.tryClose then
		return true
	end
	vi.tryClose = true
end

vi.modes.normal = {
	["h"] = function()
		vi.moveCursorX(-vi.getcount())
	end,
	["l"] = function()
		vi.moveCursorX(vi.getcount())
	end,
	["k"] = function()
		vi.moveCursorY(-vi.getcount())
	end,
	["j"] = function()
		vi.moveCursorY(vi.getcount())
	end,
	[":"] = function()
		vi.mode = "command"
		th = 19
		vi.forceDraw = true
	end,
	["i"] = function()
		vi.mode = "insert"
	end,
	["I"] = function()
		vi.mode = "insert"
		vi.modes.normal["^"]()
	end,
	["a"] = function()
		vi.mode = "insert"
		vi.moveCursorX(1)
	end,
	["A"] = function()
		vi.mode = "insert"
		vi.setCursorX(#vi.line())
	end,
	["$"] = function()
		vi.setCursorX(65535)
	end,
	["^"] = function()
		local x = string.find(vi.line(), '[^%s]')
		vi.setCursorX(x - 1)
	end,
	["0"] = function()
		vi.setCursorX(0)
	end,
	["G"] = function()
		vi.setCursorY(#vi.lines - 1)
	end,
	["p"] = function()
		local register = vi.reg()
		for i = 1, vi.getcount() do
			vi.lines[vi.cursor.y + 1] =
				vi.line():sub(1, vi.cursor.x + 1)
				.. register
				.. vi.line():sub(
					vi.cursor.x + 2,
					#vi.line()
				)
			vi.moveCursorX(1)
		end
	end,
	["P"] = function()
		local register = vi.reg()
		for i = 1, vi.getcount() do
			vi.lines[vi.cursor.y + 1] =
				vi.line():sub(1, vi.cursor.x)
				.. register
				.. vi.line():sub(
					vi.cursor.x + 1,
					#vi.line()
				)
		end
	end,
	["x"] = function()
		if vi.select.active then
			vi.replaceSelected("")
			return
		end

		if #vi.line() > 0
			and vi.cursor.x < #vi.line() then
			local count = vi.getcount()
			local cut = vi.line():sub(vi.cursor.x + 1, vi.cursor.x + count)
			vi.lines[vi.cursor.y + 1] =
				vi.line()
				:sub(1, vi.cursor.x)
				.. vi.line()
				:sub(
					vi.cursor.x + 1 + count,
					#vi.line()
				)
			vi.setCursor()

			vi.reg(nil, cut)
		end
	end,
	["s"] = function()
		vi.modes.normal["x"]()
		vi.modes.normal["i"]()
	end,
}

vi.modes.insert = {
	["escape"] = function()
		vi.mode = "normal"
		vi.moveCursorX(-1)
	end,
	["left"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.moveCursorX(-1)
	end,
	["right"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.moveCursorX(1)
	end,
	["up"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.moveCursorY(-1)
	end,
	["down"] = function()
		local lastX = vi.cursor.x
		local lastY = vi.cursor.y

		vi.moveCursorY(1)
	end,
	["return"] = function()
		if vi.select.active then
			vi.replaceSelected("")
		end

		local cx, cy = vi.cursor.x, vi.cursor.y
		local newLine = vi.lines[cy + 1]:sub(cx + 1, -1)

		vi.lines[cy + 1] = vi.lines[cy + 1]:sub(0, cx)

		local snum = string.find(vi.lines[cy + 1] .. "a", "%S")
		snum = snum and snum - 1 or 0
		newLine = string.rep(" ", snum) .. newLine

		vi.setCursor(snum, cy + 1)

		cx = vi.cursor.x
		cy = vi.cursor.y

		if cy + 1 > #vi.lines then
			api.add(vi.lines, newLine)
		else
			vi.lines = lume.concat(
				lume.slice(
					vi.lines, 0, cy
				), { newLine },
				lume.slice(
					vi.lines, cy + 1, -1
				)
			)
		end
	end,
	["home"] = function()
		vi.setCursorX(0)
	end,
	["end"] = function()
		vi.setCursorX(#vi.line())
	end,
	["pagedown"] = function()
		vi.moveCursorY(th)
		vi.setCursorX(#vi.line())
	end,
	["pageup"] = function()
		vi.moveCursorY(-th)
		vi.setCursorX(0)
	end,
	["backspace"] = function()
		if vi.select.active then
			vi.replaceSelected("")
			return
		end
		if #vi.line() > 0
			and vi.cursor.x > 0 then
			vi.lines[vi.cursor.y + 1] =
				vi.line()
				:sub(1, vi.cursor.x - 1)
				.. vi.line()
				:sub(
					vi.cursor.x + 1,
					#vi.line()
				)

			vi.moveCursorX(-1)
		elseif vi.cursor.y > 0 then
			local l1 = vi.lines[vi.cursor.y]
			local l2 = vi.line()

			table.remove(vi.lines, vi.cursor.y + 1)

			if vi.lines[vi.cursor.y]
				and l1 and l2 then

				vi.lines[vi.cursor.y] = l1 .. l2
				vi.setCursorX(#l1)
				vi.moveCursorY(-1)
			end
		end
	end,
	["tab"] = function()
		vi._text(" ")
	end,
	["delete"] = function()
		if vi.select.active then
			vi.replaceSelected("")
			return
		end

		if #vi.line() > 0
			and vi.cursor.x < #vi.line() then
			vi.lines[vi.cursor.y + 1] =
				vi.line()
				:sub(1, vi.cursor.x)
				.. vi.line()
				:sub(
					vi.cursor.x + 2,
					#vi.line()
				)
		elseif vi.cursor.y + 1 < #vi.lines then
			local l1 = vi.line()
			local l2 = vi.lines[vi.cursor.y + 2]

			table.remove(vi.lines, vi.cursor.y + 1)

			if l1 and l2 then
				vi.lines[vi.cursor.y + 1] = l1 .. l2
			end
		end
	end,
}

vi.modes.command = {
	["escape"] = function()
		vi.mode = "normal"
		vi.command = ""
		th = 20
		vi.forceDraw = true
	end,
	["left"] = function()
		vi.moveCursorEx(-1)
	end,
	["right"] = function()
		vi.moveCursorEx(1)
	end,
	["up"] = function() -- TODO
	end,
	["down"] = function() -- TODO
	end,
	["return"] = function() -- TODO
		local command = string.match(vi.command, "%s*(%a+)")
		local args = string.match(vi.command, "%s*%a+%s+(.*)%s*")

		print(command)
		local arguments = {}
		if args and #args > 0 then
			for arg in string.gmatch(args, "([^,]*)") do
				arguments[#arguments + 1] = arg
			end
			print(unpack(arguments))
		end

		if vi.commands[command] then
			vi.commands[command](unpack(arguments))
		end

		vi.modes.command["escape"]()
	end,
	["home"] = function()
		vi.setCursorEx(0)
	end,
	["end"] = function()
		vi.setCursorEx(#vi.command)
	end,
	["backspace"] = function()
		if #vi.command > 0
			and vi.cursorEx.x > 0 then
			vi.command = vi.command:sub(1, vi.cursorEx.x - 1)
					.. vi.command:sub(vi.cursorEx.x + 1, #vi.command)

			vi.moveCursorEx(-1)
		else
			vi.modes.command["escape"]()
		end
	end,
	["tab"] = function() -- TODO: tab completion?
	end,
	["delete"] = function()
		if #vi.command > 0
			and vi.cursorEx.x < #vi.command then
			vi.command = vi.command:sub(1, vi.cursorEx.x)
					.. vi.command:sub(vi.cursorEx.x + 2, #vi.command)
		else
			vi.modes.command["escape"]()
		end
	end,
}

-- all the keys that should be treated as special keys, and not alphanumeric
vi.isspecial = {
	["kpenter"] = true,

	["up"] = true,
	["down"] = true,
	["right"] = true,
	["left"] = true,
	["home"] = true,
	["end"] = true,
	["pageup"] = true,
	["pagedown"] = true,

	["insert"] = true,
	["backspace"] = true,
	["tab"] = true,
	["clear"] = true,
	["return"] = true,
	["delete"] = true,

	["f1"] = true,
	["f2"] = true,
	["f3"] = true,
	["f4"] = true,
	["f5"] = true,
	["f6"] = true,
	["f7"] = true,
	["f8"] = true,
	["f9"] = true,
	["f10"] = true,
	["f11"] = true,
	["f12"] = true,
	["f13"] = true,
	["f14"] = true,
	["f15"] = true,
	["f16"] = true,
	["f17"] = true,
	["f18"] = true,

	["numlock"] = true,
	["capslock"] = true,
	["scrolllock"] = true,
	["rshift"] = true,
	["lshift"] = true,
	["rctrl"] = true,
	["lctrl"] = true,
	["ralt"] = true,
	["lalt"] = true,
	["rgui"] = true,
	["lgui"] = true,
	["mode"] = true,

	["www"] = true,
	["mail"] = true,
	["calculator"] = true,
	["computer"] = true,
	["appsearch"] = true,
	["apphome"] = true,
	["appback"] = true,
	["appforward"] = true,
	["apprefresh"] = true,
	["appbookmarks"] = true,

	["pause"] = true,
	["escape"] = true,
	["help"] = true,
	["printscreen"] = true,
	["sysreq"] = true,
	["menu"] = true,
	["application"] = true,
	["power"] = true,
	["currencyunit"] = true,
	["undo"] = true,
}

vi.kmaps.normal = {}
for k, v in pairs(vi.modes.normal) do
	vi.kmaps.normal[k] = v
end

vi.kmaps.insert = {}
for k, v in pairs(vi.modes.insert) do
	vi.kmaps.insert[k] = v
end

vi.kmaps.command = {}
for k, v in pairs(vi.modes.command) do
	vi.kmaps.command[k] = v
end

function vi._keyup(k)
	if k == "lshift" or k == "rshift" then
		vi.shift = false
		return
	elseif k == "lctrl" or k == "rctrl" then
		vi.ctrl = false
		return
	end
end

function vi._keydown(k)
	if not vi.isspecial[k] then
		return
	end

	if k ~= "escape" then
		vi.tryClose = false
	end

	if k == "lshift" or k == "rshift" then
		vi.shift = true
		return
	elseif k == "lctrl" or k == "rctrl" then
		vi.ctrl = true
		return
	end

	local kmap = vi.kmaps[vi.mode]
	if kmap and kmap[k] then
		kmap[k]()
	end

	vi.t = 0
	vi.redraw()
end

function vi.replaceSelected(text)
	if vi.select.finish.y - vi.select.start.y == 0 then
		local min = vi.select.start.x
			> vi.select.finish.x and
			vi.select.finish
			or vi.select.start

		local max = vi.select.start.x
			< vi.select.finish.x and
			vi.select.finish
			or vi.select.start

		local line = vi.lines[min.y + 1]
		local newLine

		if min.x == 0 then
			newLine = text
		else
			newLine = line:sub(0, min.x) ..
				text
		end

		vi.lines[min.y + 1] =
			newLine ..
			line:sub(max.x + 1, #line)

		vi.setCursorX(#newline)
	else
		local min = vi.select.start.y
			> vi.select.finish.y and
			vi.select.finish
			or vi.select.start

		local max = vi.select.start.y
			< vi.select.finish.y and
			vi.select.finish
			or vi.select.start

		local line = vi.lines[min.y + 1]
		local newLine

		if min.x > 0 then
			newLine = line:sub(0, min.x) .. text
		else
			newLine = text
		end

		for y = min.y, max.y do
			table.remove(vi.lines, min.y + 1)
		end

		table.insert(vi.lines, min.y + 1, newLine)

		vi.setCursor(#newline, min.y)
	end

	vi.select.active = false
end

function vi._copy()
	if vi.select.active then
		local text = ""

		if vi.select.finish.y - vi.select.start.y == 0 then
			local min = vi.select.start.x
				> vi.select.finish.x and
				vi.select.finish
				or vi.select.start

			local max = vi.select.start.x
				< vi.select.finish.x and
				vi.select.finish
				or vi.select.start

			local line = vi.lines[min.y + 1]
			text = line:sub(min.x + 1, max.x)
		else
			local min = vi.select.start.y
				> vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			local max = vi.select.start.y
				< vi.select.finish.y and
				vi.select.finish
				or vi.select.start

			local line = vi.lines[min.y + 1]
			text = line:sub(0, min.x, #line)

			local m = 1

			for y = min.y + 1, max.y + m do
				text = text .. "\n\n" .. vi.lines[y]
			end

			text = text .. "\n\n" .. vi.lines[max.y + m]:sub(0, max.x)
		end

		vi.forceDraw = true
		vi.select.active = false

		return text
	end
end

function vi._cut()
	local active = vi.select.active
	local text = vi._copy()

	if active then
		vi.select.active = true
		vi.replaceSelected("")
	end

	return text
end

function vi._text(text)
	vi.tryClose = false
	if vi.mode == "normal" then
		for k in string.gmatch(text, '.') do
			if vi.count or k ~= "0" then
				local count = tonumber(k)
				if count then
					vi.count = vi.count or 0 
					vi.count = vi.count * 10 + count
					break
				end
			end
	
			local kmap = vi.kmaps[vi.mode]
			if kmap and kmap[k] then
				kmap[k]()
			end
		end

	elseif vi.mode == "command" then
		vi.command = 
			vi.command:sub(1, vi.cursorEx.x)
			.. text
			.. vi.command:sub(vi.cursorEx.x + 1, #vi.command)
		vi.moveCursorEx(1)
	elseif vi.mode == "insert" then

		-- todo: rewrite
		text = text:gsub("\t", " ")
		local parts = {}

		for p in text:gmatch("([^\r\n]*)\r?\n") do
			table.insert(parts, p)
		end

		if #parts > 0 then
			for i, part in ipairs(parts) do
				if vi.select.active then
					vi.replaceSelected(part)
				else
					vi.lines[vi.cursor.y + 1] =
					vi.line():sub(
					1, vi.cursor.x) .. part
					.. vi.line():sub(
						vi.cursor.x + 1, #vi.lines[
							vi.cursor.y + 1
						]
					)

					vi.moveCursorX(#text)
				end

				if #parts > 1 then
					if i < #parts then
						table.insert(vi.lines, vi.cursor.y + 1, "")
					end
				end

				vi.select.active = false
			end

			vi.moveCursorY(-1)
			vi.setCursorX(#vi.line())
		else
			if vi.select.active then
				vi.replaceSelected(text)
			else
				vi.lines[vi.cursor.y + 1] =
				vi.line():sub(
				1, vi.cursor.x) .. text
				.. vi.line():sub(
					vi.cursor.x + 1, #vi.lines[
						vi.cursor.y + 1
					]
				)

				vi.moveCursorX(#text)
			end
		end

	end
	vi.t = 0
	vi.redraw()
end

function vi._wheel(a)
	if a < 0 then
		vi.view.y = api.max(0, api.min(vi.view.y + 1, #vi.lines - th + 2))
	elseif a > 0 then
		vi.view.y = api.max(vi.view.y - 1, 0)
	end

	vi.t = 0
	vi.forceDraw = true
end

function vi.updateCursorY()
	vi.cursorReal.y = api.max(0, vi.cursorReal.y)
	vi.cursor.y =
		api.mid(
			0, vi.cursorReal.y,
			api.max(1, #vi.lines - 1)
		)

	if vi.cursor.y > th + vi.view.y - 3 then
		vi.view.y = vi.cursor.y - (th - 3)
		return true
	elseif vi.cursor.y < vi.view.y then
		vi.view.y = vi.cursor.y
		return true
	end

	return false
end

function vi.updateCursorX()
	vi.cursorReal.x = api.max(0, vi.cursorReal.x)
	local max = #vi.line() - 1
	if vi.mode == "insert" then
		max = #vi.line()
	end
	vi.cursor.x =
		api.mid(
			0, vi.cursorReal.x,
			max
		)

	if vi.cursor.x > vi.view.x + tw - 5 then
		vi.view.x = vi.cursor.x - tw + 5
		return true
	elseif vi.cursor.x < vi.view.x + 5 then
		vi.view.x = api.max(0, vi.cursor.x - 5)
		return true
	end

	return false
end

function vi.moveCursorX(x)
	if x < 0 and vi.cursorReal.x > #vi.line() then
		vi.setCursorX(#vi.line() + x - 1)
	else
		vi.setCursorX(vi.cursorReal.x + x)
	end
end

function vi.moveCursorY(y)
	if y < 0 and vi.cursorReal.y > #vi.lines then
		vi.setCursorY(#vi.lines + y - 1)
	else
		vi.setCursorY(vi.cursorReal.y + y)
	end
end

function vi.setCursorX(x, nocheck)
	vi.cursorReal.x = x
	if not nocheck then
		vi.updateCursorY()
		vi.updateCursorX()
	end
end

function vi.setCursorY(y, nocheck)
	vi.cursorReal.y = y
	if not nocheck then
		vi.updateCursorY()
		vi.updateCursorX()
	end
end

function vi.setCursor(x, y, nocheck)
	if x then vi.setCursorX(x, true) end
	if y then vi.setCursorY(y, true) end
	if not nocheck then
		vi.updateCursorY()
		vi.updateCursorX()
	end
end

function vi.updateCursorEx()
	vi.cursorEx.x =
		api.mid(
			0, vi.cursorEx.x,
			#vi.command
		)
end

function vi.moveCursorEx(x)
	vi.setCursorEx(vi.cursorEx.x + x)
end

function vi.setCursorEx(x, nocheck)
	vi.cursorEx.x = x
	vi.updateCursorEx()
end

local function lines(s)
	if s:sub(-1) ~= "\n" then
		s = s .. "\n"
	end

	return s:gmatch("(.-)\n")
end

function vi.import(c)
	vi.lines = {}

	c = c:gsub("\t", " ")
	-- todo: doesn't work?

	for l in lines(c) do
		api.add(vi.lines, l)
	end

	if not vi.lines[1] then
		vi.lines[1] = ""
	end
end

function vi.export()
	local data = {}

	for l in api.all(vi.lines) do
		table.insert(data, l)
		table.insert(data, "\n")
	end

	return table.concat(data)
end

return vi

-- vim: noet
