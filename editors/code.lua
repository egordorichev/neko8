local code = {}
local lume = require "libs.lume"
local colorize = require "libs.colorize"

local t = 0
local tw = 40
local th = 20

function code.init()
  code.lines = {}
  code.lines[1] = ""
	code.icon = 8
	code.bg = config.editors.code.bg

	code.select = {
		start = {
			x = 0,
			y = 0
		},

		finish = {
			x = 0,
			y = 0
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
end

local function cursorBlink()
  return t < 16 or t % 30 < 16
end

function code._update()
  local lb = cursorBlink()
  t = t + 1

  if cursorBlink() ~= lb then
    code.redraw()
  end

	lmb = mb
	mx, my, mb = api.mstat(1)
	mx = mx + code.view.x * 4
	my = my + code.view.y * 6

	if mb then
		if not lmb then
			code.select.start.x = api.flr((mx - 1) / 4)
			code.select.start.y = api.flr((my - 8) / 6)

			code.select.start.y = api.mid(
				0, #code.lines - 1, code.select.start.y
			)

			code.select.start.x = api.mid(
				0, #code.lines[code.cursor.y + 1],
				code.select.start.x
			)
		else
			code.select.finish.x = api.flr((mx - 1) / 4)
			code.select.finish.y = api.flr((my - 8) / 6)

			code.select.finish.y = api.mid(
				0, #code.lines - 1, code.select.finish.y
			)

			code.select.finish.x = api.mid(
				0, #code.lines[code.cursor.y + 1],
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

local function highlight(lines)
  return colorize(
    lines,
    config.editors.code.colors
  )
end

local function colorPrint(tbl)
  for i = 1, #tbl, 2 do
		local cx, cy = api.cget()

		api.color(tbl[i])
    api.print(tbl[i + 1], true, false)
  end

  api.print("")
  api.cursor(1 - code.view.x * 4)
end

function code.redraw()
  api.cls(5)

  local buffer = lume.clone(
    lume.slice(
      code.lines, code.view.y + 1,
      code.view.y + th - 1
    )
  )

  buffer = highlight(buffer)

  api.cursor(1 - code.view.x * 4, 9)

	if code.select.active then
		if code.select.finish.y - code.select.start.y == 0 then
			api.rectfill(
				code.select.start.x * 4 - code.view.x * 4,
				code.select.start.y * 6 + 9 - code.view.y * 6,
				code.select.finish.x * 4 - code.view.x * 4,
				(code.select.start.y + 1) * 6 + 8 - code.view.y * 6,
				10
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
				10
			)

			for y = min.y + 1, max.y - 1 do
				api.rectfill(
					-code.view.x * 4,
					y * 6 + 9 - code.view.y * 6,
					#code.lines[y + 1] * 4 - code.view.x * 4,
					(y + 1) * 6 + 8 - code.view.y * 6,
					10
				)
			end

			api.rectfill(
				-code.view.x * 4,
				max.y * 6 + 9 - code.view.y * 6,
				max.x * 4 - code.view.x * 4,
				(max.y + 1) * 6 + 8 - code.view.y * 6,
				10
			)
		end
	end

  for l in api.all(buffer) do
    colorPrint(l)
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

  editors.drawUI()

  api.print(
    "line " .. code.cursor.y .. "/"
    .. #code.lines .. ", char "
    .. code.cursor.x .. "/"
    .. #code.lines[code.cursor.y + 1],
    1, config.canvas.height - 6,
    config.editors.ui.fg
  )
end

function code.close()

end

function code._keydown(k)
  if api.key("rctrl") or api.key("lctrl") then
    if k == "s" then
      commands.save()
    end
  else
    if k == "left" then
      code.cursor.x = code.cursor.x - 1
      t = 0
      code.checkCursor()
    elseif k == "right" then
      code.cursor.x = code.cursor.x + 1
      t = 0
      code.checkCursor()
    elseif k == "up" then
      code.cursor.y = code.cursor.y - 1
      t = 0
      code.checkCursor(true)
    elseif k == "down" then
      code.cursor.y = code.cursor.y + 1
      t = 0
      code.checkCursor(true)
    elseif k == "return" or k == "kpenter" then
      local cx, cy = code.cursor.x,
        code.cursor.y
      local newLine = code.lines[cy + 1]
        :sub(cx + 1, -1)

      code.lines[cy + 1] =
        code.lines[cy + 1]:sub(0, cx)

      local snum = string.find(code.lines[cy + 1] .. "a", "%S")
      snum = snum and snum - 1 or 0
      newLine = string.rep(" ", snum) .. newLine

      code.cursor.x, code.cursor.y =
        snum, cy + 1

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
      t = 0
      code.checkCursor()
    elseif k == "home" then
      code.cursor.x = 0
      code.checkCursor()
    elseif k == "end" then
      code.cursor.x =
        #code.lines[code.cursor.y + 1]
	    code.checkCursor()
    elseif k == "backspace" then
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
        local l1 =
          code.lines[code.cursor.y]
        local l2 =
          code.lines[code.cursor.y + 1]

        table.remove(code.lines, code.cursor.y + 1)

        if code.lines[code.cursor.y]
          and l1 and l2 then

          code.lines[code.cursor.y] =
            l1 .. l2
          code.cursor.x = #l1
          code.cursor.y = code.cursor.y - 1
        end
      end
      t = 0
      code.checkCursor()
    elseif k == "delete" then
      if #code.lines[code.cursor.y + 1] > 0
        and code.cursor.x <
        #code.lines[code.cursor.y + 1] then
        code.lines[code.cursor.y + 1] =
          code.lines[code.cursor.y + 1]
          :sub(1, code.cursor.x)
          .. code.lines[code.cursor.y + 1]
          :sub(
            code.cursor.x + 2,
            #code.lines[code.cursor.y + 1]
          )
      elseif code.cursor.y + 1 < #code.lines then
        local l1 =
          code.lines[code.cursor.y + 1]
        local l2 =
          code.lines[code.cursor.y + 2]

        table.remove(code.lines, code.cursor.y + 1)

        if l1 and l2 then
          code.lines[code.cursor.y + 1] =
            l1 .. l2
        end
      end
      t = 0
    end
  end
  code.redraw()
end

function code._text(text)
  code.lines[code.cursor.y + 1] =
    code.lines[code.cursor.y + 1]:sub(
    1, code.cursor.x) .. text
    .. code.lines[code.cursor.y + 1]:sub(
      code.cursor.x + 1, #code.lines[
        code.cursor.y + 1
      ]
    )

  code.cursor.x = code.cursor.x + 1
  t = 0
	code.checkCursor()
	code.redraw()
end

function code.checkCursorY()
  code.cursor.y =
    api.mid(
      0, code.cursor.y,
      #code.lines - 1
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
      code.cursor.y =
        code.cursor.y - 1
      f = code.checkCursorY()
      code.cursor.x =
        #code.lines[code.cursor.y + 1]
    end
  elseif code.cursor.x >
    #code.lines[code.cursor.y + 1] then

    if code.cursor.y + 1 < #code.lines
      and not j then
      code.cursor.y =
        code.cursor.y + 1
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
  local data = ""

  for l in api.all(code.lines) do
    data = data .. l .. "\n"
  end

  return data
end

return code