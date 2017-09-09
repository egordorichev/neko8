local map = {}
local sprites = require "editors.sprites"

function map.init()
	map.forceDraw = false
	map.icon = 10
	map.bg = config.editors.map.bg
	map.name = "map editor"
	map.window = {
		active = true,
		x = 110, -- fixme: better start pos
		y = 44
	}
end

function map.open()
	map.forceDraw = true

	if sprites.page > 1 then
		sprites.page = 0
		sprites.sprite = 0
	end
end

function map.close()

end

function map._draw()
	if map.forceDraw then
		map.redraw()
		map.forceDraw = false
	end
end

function map.redraw()
	api.cls(0)
	api.map(0, 0, 0, 7)

	-- draw window
	if map.window.active then
		api.brectfill(
			map.window.x, map.window.y,
			66, 74, 5
		)

		-- sprites
		api.brectfill(
			map.window.x + 1, map.window.y + 9,
			64, 64, 0
		)

		api.spr(
			0, 0, -- todo: page
			64, 64,
			map.window.x + 1, map.window.y + 9,
			64, 64
		)

		neko.cart = nil

		-- current sprite
		local bs = sprites.sprite - sprites.page * 64
		local bx = bs % 16
		local by = api.flr(bs / 16)

		if by >= 0 and by <= 7
		 	and bx >= 0 and bx <= 7 then
				api.brect(
					map.window.x + 1 + bx * 8,
					map.window.y + 9 + by * 8,
					8 * sprites.scale - 1, 8 * sprites.scale - 1, 0
				)

				api.brect(
					map.window.x + bx * 8,
					map.window.y + 8 + by * 8,
					8 * sprites.scale + 1, 8 * sprites.scale + 1, 7
				)
		end

		neko.cart, neko.core = neko.core, neko.cart

		for i = 0, 3 do
			api.spr(
				i == sprites.page and 22 or 23,
				map.window.x + i * 8 + 12, map.window.y + 1
			)

			api.print(
				i, map.window.x + i * 8 + 14, map.window.y + 2, 13
			)
		end

		api.spr(24, map.window.x + 1, map.window.y + 1)

		neko.cart, neko.core = neko.core, neko.cart
	end

	editors.drawUI()
end

local mx, my, mb, lmb

function map._update()
	lmb = mb
	mx, my, mb = api.mstat(1)
end

function map.import(data)
	map.data = data
end

function map.export()
	local data = ""

	for y = 0, 127 do
		for x = 0, 127 do
			data = data .. string.format("%02x", map.data[y][x])
		end
		data = data .. "\n"
	end

	return data
end

function map._keydown(k)
	if api.key("rctrl") or api.key("lctrl") then
		if k == "s" then
			commands.save()
		end
	else
		if k == "lshift" or k == "rshift" then
			map.window.active = not map.window.active
			map.forceDraw = true
		end
	end
end

return map