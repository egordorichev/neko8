local code = {}
local editors = require "editors"
local lume = require "libs.lume"
local colorize = require "libs.colorize"

local t = 0
local tw = 35
local th = 21

function code.init()
  code.lines = {}
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
  code.redraw()
end

function code._draw()

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
end

local function highlight(lines)
  return colorize(
    lines,
    config.editors.code.colors
  )
end

local function colorPrint(tbl)
  for i = 1, #tbl, 2 do
    api.color(tbl[i])
    api.print(tbl[i + 1], true, false)
  end
  api.print("")
  api.cursor(1)
end

function code.redraw()
  api.cls(5)

  local buffer = lume.clone(
    lume.slice(
      code.lines, code.view.y,
      code.view.y + th - 2
    )
  )

  buffer = highlight(buffer)

  api.cursor(1, 9)

  for l in api.all(buffer) do
    colorPrint(l)
  end

  if cursorBlink() then
    api.rectfill(
      code.cursor.x * 4,
      code.cursor.y * 6 + 8,
      code.cursor.x * 4 + 4,
      code.cursor.y * 6 + 14,
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
    "line " .. code.cursor.x .. "/"
    .. #code.lines,
    1, config.canvas.height - 6,
    config.editors.ui.fg
  )
end

function code.close()

end

function code._keydown(k)
  if api.key("rctrl") or api.key("lctrl") then

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
      code.checkCursor()
    elseif k == "down" then
      code.cursor.y = code.cursor.y + 1
      t = 0
      code.checkCursor()
    elseif k == "return" or k == "kpenter" then
      t = 0
      --
      -- todo!
      --
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
        code.checkCursor()
      else
        table.remove(code.lines, code.cursor.y + 1)
      end
      code.cursor.y = code.cursor.y - 1
      code.checkCursor()
      code.cursor.x =
        #code.lines[code.cursor.y + 1]
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
      else
          table.remove(code.lines, code.cursor.y + 1)
      end
      t = 0
      code.redraw()
    end
  end
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
  code.redraw()
end

function code.checkCursor()
  code.cursor.y =
    api.mid(
      0, code.cursor.y,
      #code.lines
    )

  code.cursor.x =
    api.mid(
      0, code.cursor.x,
      #code.lines[code.cursor.y + 1]
    )

  code.redraw()
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