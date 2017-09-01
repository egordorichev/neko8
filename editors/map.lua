local map = {}
local sprites = require "editors.sprites"

function map.init()
	map.forceDraw = false
	map.icon = 10
	map.bg = config.editors.map.bg
	map.showTiles = true
end

function map.open()
	map.forceDraw = true

	if sprites.page > 3 then
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

	if map.showTiles then
		-- tools

		api.brectfill(
			0, 75, config.canvas.width,
			75, 5
		)
		-- sprite select

		api.brectfill(
			3, 78, 13,
			7, 6
		)

		api.print(
			string.format(
				"%03d", sprites.sprite
			), 4, 79, 13
		)

		-- page buttons

		neko.cart, neko.core = neko.core, neko.cart

		for i = 0, 3 do
			api.spr(
				i == sprites.page and 7 or 6,
				19 + i * 8, 80
			)

			api.print(
				i, 21 + i * 8, 81, 13
			)
		end

		neko.cart, neko.core = neko.core, neko.cart
		-- sprites
		api.brectfill(
			0, 88, 129,
			33, 0
		)

		api.sspr(
			0, sprites.page * 32,
			128, 32, 0, 89
		)

		-- current sprite
		local s = sprites.sprite - sprites.page * 64
		x = s % 16
		y = api.flr(s / 16)

		if y >= 0 then
			api.brect(
				x * 8, 89 + y * 8,
				8 * sprites.scale, 8 * sprites.scale, 0
			)

			api.brect(
				-1 + x * 8, 88 + y * 8,
				8 * sprites.scale + 2, 8 * sprites.scale + 2, 7,
				8 * sprites.scale + 2, 8 * sprites.scale + 2, 7
			)
		end
	end

	editors.drawUI()
end

function map._update()
	lmb = mb
	mx, my, mb = api.mstat(1)

	if mb then
		if map.showTiles and mx >= 0 and mx <= 128
			and my >= 88 and my <= 88 + 32 then

			my = my - 88
			sprites.sprite = api.mid(0, 511, api.flr(mx / 8)
				+ api.flr(my / 8) * 16 + sprites.page * 64)

			map.forceDraw = true
		elseif map.showTiles and lmb == false and my >= 80 and my <= 88 then
			for i = 0, 3 do
				if mx >= 19 + i * 8 and mx <= 26 + i * 8 then
					sprites.page = i
					map.forceDraw = true
					return
				end
			end
		elseif my >= 8
			and my <= (map.showTiles and 75 or 120) then
			mx = api.mid(0, 127, api.flr(mx / 8 + 0.5))
			my = api.mid(0, 127, api.flr(my / 8 - 1))
			neko.loadedCart.map[my][mx] = sprites.sprite
			map.forceDraw = true
		end
	end
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
		if k == "lshift" then
			map.showTiles = not map.showTiles
			map.forceDraw = true
		end
	end
end

return map