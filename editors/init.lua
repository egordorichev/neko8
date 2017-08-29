local editors = {}

function editors.init()
  editors.opened = false
  editors.code = require "editors.code"
  editors.sprites = require "editors.sprites"

  editors.modes = {
    editors.code,
		editors.sprites
  }

  editors.current = editors.modes[1]

  for e in api.all(editors.modes) do
    e.init()
  end
end

function editors.open()
  if editors.opened then
    return
  end

  editors.opened = true
  editors.current.open()
end

function editors.close()
  if not editors.opened then
    return
  end

  editors.opened = false
  editors.current.close()
  api.cls()
end

function editors.toggle()
  if editors.opened then
    editors.close()
  else
    editors.open()
  end
end

function editors.drawUI()
  api.rectfill(
    0, 0, config.canvas.width,
    6, config.editors.ui.bg
  )

  api.rectfill(
    0, config.canvas.height - 7,
    config.canvas.width,
    config.canvas.height,
    config.editors.ui.bg
  )

	for i = 1, #editors.modes do
		local m = editors.modes[i]
		local c = m == editors.current and
			config.editors.sprites.bg or
			config.editors.sprites.fg

		local x = config.canvas.width -
			(#editors.modes + 1 - i) * 7
		api.brectfill(x, 0, 7, 7, c)
	end
end

function editors._update()
	local mx, my, mb = api.mstat(1)
	for i = 1, #editors.modes do
		local m = editors.modes[i]
		local x = config.canvas.width -
			(#editors.modes + 1 - i) * 7
		if mb and mx >= x and mx <= x + 7 and
			my >= 0 and my <= 7 then
			editors.current.close()
			editors.current = m
			m.open()
		end
	end
end

return editors