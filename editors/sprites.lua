local sprites = {}

function sprites.init()
	sprites.color = 7
	sprites.sprite = 0
	sprites.page = 0
	sprites.scale = 1
	sprites.icon = 9
	sprites.name = "sprite editor"
	sprites.bg = config.editors.sprites.bg
end

function sprites.open()
	sprites.forceDraw = true
end

function sprites.close()

end

function sprites._draw()
	if sprites.forceDraw then
		sprites.redraw()
		sprites.forceDraw = false
	end
end

function sprites.redraw()
	api.cls(config.editors.sprites.bg)

	-- sprite space
	api.brectfill(0, 8, 64, 64, 0)

	api.sspr(
		sprites.sprite % 16 * 8,
		api.flr(sprites.sprite / 16) * 8,
		8 * sprites.scale, 8 * sprites.scale,
		0, 8, 64, 64
	)

	api.line(64, 7, 64, 72, config.editors.sprites.bg)

	-- sprite id

	api.brectfill(64, 73, 13, 7, 6)

	api.print(
		string.format(
			"%03d", sprites.sprite
		), 65, 74, 13
	)

	-- sprites
	api.brectfill(
		64, 8, 128,
		64, 0
	)

	api.sspr(
		0, sprites.page * 64,
		128, 64, 64, 8, 128, 64
	)

	-- page buttons

	neko.cart, neko.core = neko.core, neko.cart

	for i = 0, 3 do
		api.spr(
			i == sprites.page and 7 or 6,
			87 + i * 8, 72
		)

		api.print(
			i, 89 + i * 8, 74, 13
		)
	end

	neko.cart, neko.core = neko.core, neko.cart

	-- sprite flags
	for i = 0, 7 do
		local f = sprites.data.flags[
				sprites.sprite
			]

		local c =	bit.band(bit.rshift(f, i), 1) == 1
			and i + 8 or 1

		api.circfill(8, 76 + i * 6, 2, c)
		api.circ(8, 76 + i * 6, 2, 0)
	end

	-- palette
	for x = 0, 3 do
		for y = 0, 3 do
			local c = x + y * 4
			api.brectfill(
				15 + x * 12, 72 + y * 12,
				12, 12, c
			)
		end
	end

	api.brect(15, 72, 48, 48, config.editors.sprites.bg)

	-- current color

	local x = sprites.color % 4
	local y = api.flr(sprites.color / 4)

	api.brect(
		15 + x * 12, 72 + y * 12,
		12, 12, 0
	)

	api.brect(
		15 + x * 12 - 1, 71 + y * 12,
		14, 14, 7
	)

	-- current sprite
	local s = sprites.sprite - sprites.page * 128
	x = s % 16
	y = api.flr(s / 16)

	if y >= 0 and y <= 8 then
		api.brect(
			64 + x * 8, 8 + y * 8,
			8 * sprites.scale, 8 * sprites.scale, 0
		)

		api.brect(
			63 + x * 8, 7 + y * 8,
			8 * sprites.scale + 2, 8 * sprites.scale + 2, 7,
			8 * sprites.scale + 2, 8 * sprites.scale + 2, 7
		)
	end

	editors.drawUI()
	neko.cart = nil -- see spr and sspr
end

local function flip(byte, b)
  b = 2 ^ b
  return bit.bxor(byte, b)
end

local mx, my, mb, lmb

function sprites._update()
	lmb = mb
	mx, my, mb = api.mstat(1)

	if mb then
		if mx > 64 and mx < 192
			and my > 8 and my < 72 then

			my = my - 8
			mx = mx - 64

			sprites.sprite = api.mid(0, 511, api.flr(mx / 8)
				+ api.flr(my / 8) * 16 + sprites.page * 128)

			sprites.forceDraw = true
		elseif mx > 0 and mx < 64
			and my > 8 and my < 72 then

			mx = api.flr(mx / (8 * sprites.scale))
			my = api.flr((my - 8) / (8 * sprites.scale))

			local v = sprites.color * 16
			local s = sprites.sprite

			sprites.data.data:setPixel(
				api.mid(mx, 0, 7) + s % 16 * 8,
				api.mid(my, 0, 7) + api.flr(s / 16) * 8,
				v, v, v
			)

			sprites.data.sheet:refresh()
			sprites.forceDraw = true
		elseif my > 72 and my < 120 and
			mx > 15 and mx < 47 + 16 then
			mx = api.flr((mx - 16) / 12)
			my = api.flr((my - 72) / 12)

			sprites.color = api.mid(0, 15, mx + my * 4)
			sprites.forceDraw = true
		elseif lmb == false and mx >= 5 and mx <= 13 then
			for i = 0, 7 do
				if my >= 68 + i * 6 and my <= 76 + i * 6 then
					local b = sprites.data.flags[sprites.sprite]
					sprites.data.flags[sprites.sprite] = flip(b, i)
					sprites.forceDraw = true
					return
				end
			end
		elseif lmb == false and my >= 72 and my <= 80 then
			for i = 0, 3 do
				if mx >= 85 + i * 8 and mx <= 85 + 8 + i * 8 then
					sprites.page = i
					sprites.forceDraw = true
					return
				end
			end
		end
	end
end

function sprites.import(data)
	sprites.data = data
end

function sprites.export()
	return sprites.data
end

function sprites.exportGFX()
	local d = ""

	for y = 0, 127 do
		for x = 0, 127 do
			local v = sprites.data.data:getPixel(x, y)
			v = string.format("%x", v / 16)
			d = d .. v
		end

		d = d .. "\n"
	end

	return d
end

function sprites.exportGFF()
	local d = ""

	for s = 0, 511 do
		d = d .. string.format("%02x", sprites.data.flags[s])
		if s ~= 1 and (s + 1) % 128 == 0 then
			d = d .. "\n"
		end
	end

	return d
end

function sprites._keydown(k, r)
	if api.key("rctrl") or api.key("lctrl") then
    if k == "s" then
      commands.save()
    end
	else

	end
end

function sprites._copy()
	local data = ""

	for y = api.flr(sprites.sprite / 16) * 8,
		api.flr(sprites.sprite / 16) * 8 + 7 do
		for x = (sprites.sprite % 16) * 8,
			(sprites.sprite % 16) * 8 + 7 do

			local r = sprites.data.data:getPixel(x, y) / 16
			data = data .. string.format("%x", r)
		end
	end

	return "[gfx]" .. data .. "[/gfx]"
end

function sprites._text(text)
	if text:sub(0, 5) == "[gfx]" and
		text:sub(#text - 5, #text) == "[/gfx]" then

		local i = 6

		for y = api.flr(sprites.sprite / 16) * 8,
			api.flr(sprites.sprite / 16) * 8 + 7 do
			for x = (sprites.sprite % 16) * 8,
				(sprites.sprite % 16) * 8 + 7 do

				local v = tonumber(text:sub(i, i), 10) * 16

				local r = sprites.data.data:setPixel(x, y, v, v, v, 255)
				i = i + 1
			end
		end

		sprites.data.sheet:refresh()
		sprites.forceDraw = true
	end
end

return sprites