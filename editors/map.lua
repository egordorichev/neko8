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

	editors.drawUI()

	if map.redrawInfo then
		map.drawInfo()
		map.redrawInfo = true
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

		api.sspr(
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
end

local mx, my, mb, lmb, lmx, lmy

function map.drawInfo()
	if map.window.active and mx >= map.window.x
		and mx <= map.window.x + 66
		and my >= map.window.y and my <= map.window.y + 74 then

	else
		if my > 7 and my < config.canvas.height - 7 then
			local x = api.mid(0, 127, api.flr(mx / 8))
			local y = api.mid(0, 127, api.flr((my - 8) / 8))

			api.print(
				string.format("x: %d y: %d", x, y),
				1, config.canvas.height - 6,
				config.editors.sprites.fg
			)
		end
	end
end

function map._update()
	lmb = mb
	lmx = mx
	lmy = my
	mx, my, mb = api.mstat(1)

	if mx ~= lmx or my ~= lmy then
		map.redrawInfo = true
	end

	if mb then
		if map.window.active and mx >= map.window.x
			and mx <= map.window.x + 66
			and my >= map.window.y and my <= map.window.y + 74 then

			mx = mx - map.window.x
			my = my - map.window.y

			if mb then

			end
		else
			if my > 7 and my < config.canvas.height - 7 then
				local x = mx / 8
				local y = (my - 8) / 8

				api.mset(x, y, editors.sprites.sprite)
				map.forceDraw = true
			end
		end
	end
end

function map.import(data)
	map.data = data
end

function map.export()
	local data = {}

	for y = 0, 127 do
		for x = 0, 127 do
			table.insert(data, string.format("%02x", map.data[y][x]))
		end

		table.insert(data, "\n")
	end

	return table.concat(data)
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

-- vim: noet
