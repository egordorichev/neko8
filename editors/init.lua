local UiManager = require "ui.manager"
local UiButton = require "ui.button"
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
	editors.ui = UiManager()

	for i, e in ipairs(editors.modes) do
		e.init()
		editors.ui:add(UiButton(
			e.icon, 21 + i * 7 - 7, 0, 8, 8, 6,
			e.bg
		):onClick(function()
			editors.openEditor(i)
		end), e.name)
	end

	editors.ui.components[editors.code.name].active = true

	-- exit button
	editors.ui:add(UiButton(
		14, config.canvas.width - 7,
		config.canvas.height - 7, 8, 8, 6
	):onClick(function(b)
		editors.close()
	end), "exit")
end

function editors.openEditor(i)
	for i, e in ipairs(editors.modes) do
		editors.ui.components[e.name].active = false
	end

	editors.current.close()
	editors.current = editors.modes[i]
	editors.ui.components[editors.current.name].active = true
	editors.current.open()
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
	if not editors.opened then
		return
	end

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

	editors.ui:draw()

	api.print(
		editors.current.name, config.canvas.width
		- 1 - #editors.current.name * 4,
		1, config.editors.ui.fg
	)

	neko.core, neko.cart = neko.cart, neko.core
end

return editors


