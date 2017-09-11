local editors = {}

function editors.init()
  editors.opened = false
  editors.code = require "editors.code"
  editors.sprites = require "editors.sprites"
  editors.map = require "editors.map"
  editors.sfx = require "editors.sfx"
  editors.music = require "editors.music"
  editors.docs = require "editors.docs"

  editors.modes = {
    editors.code,
		editors.sprites,
		editors.map,
		editors.sfx,
		editors.music,
		editors.docs
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
	local mx, my, mb = api.mstat(1)

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

	api.print("neko8", 1, 1, config.editors.ui.fg)

	neko.core, neko.cart = neko.cart, neko.core

	for i = 1, #editors.modes do
		local m = editors.modes[i]
		local c = m == editors.current and m.bg or
			config.editors.ui.bg

		if m == editors.current then
			api.pal(6, config.editors.ui.icons.selected)
		else
			api.pal(6, config.editors.ui.icons.default)
		end

		api.brectfill(21 + i * 7 - 7, 0, 7, 7, c)
		api.spr(m.icon, 21 + i * 7 - 7, 0)
		api.pal()
	end

	api.print(
		editors.current.name, config.canvas.width
		- 1 - #editors.current.name * 4,
		1, config.editors.ui.fg
	)

	api.spr(13, config.canvas.width - 7,
		config.canvas.height - 7)

	neko.core, neko.cart = neko.cart, neko.core
end

local lmb, mb, mx, my

function editors._update()
	lmb = mb
	mx, my, mb = api.mstat(1)

	if mb ~= lmb then
		for i = 1, #editors.modes do
			local m = editors.modes[i]
			local x = i * 7 - 7 + 21
			if mb and mx >= x and mx <= x + 7 and
				my >= 0 and my <= 7 then
				editors.current.close()
				editors.current = m
				m.open()
			end
		end

		if mx >= config.canvas.width - 7
			and mx <= config.canvas.width
			and my >= config.canvas.height - 7
			and my <= config.canvas.height then

			editors.close()
		end
	end
end

return editors
