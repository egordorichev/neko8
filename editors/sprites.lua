local sprites = {}

function sprites.init()
	sprites.color = 7
	sprites.sprite = 0
	sprites.page = 0
	sprites.scale = 1
	sprites.icon = 9
	sprites.name = "sprite editor"
	sprites.bg = config.editors.sprites.bg

	local pencil = {
		icon = 32
	}

	pencil.use = function(x, y)
		local v = sprites.color * 16
		local s = sprites.sprite

		x = api.flr(x / (8 * sprites.scale))
		y = api.flr(y / (8 * sprites.scale))

		sprites.data.data:setPixel(
			api.mid(x, 0, 7) + s % 16 * 8,
			api.mid(y, 0, 7) + api.flr(s / 16) * 8,
			v, v, v
		)
	end

	local stamp = {
		icon = 33
	}

	stamp.use = function(x, y)

	end

	local select = {
		icon = 34
	}

	select.use = function(x, y)

	end

	local move = {
		icon = 35
	}

	move.use = function(x, y)

	end

	local fill = {
		icon = 36
	}

	fill.setPixel = function(x, y, c)
			sprites.data.data:setPixel(x, y, c * 16, c * 16, c * 16, 255)
	end

	fill.getPixel = function(x, y)
		if x < 0 or x > 7 or
			y < 0 or y > 7 then -- fixme: bounds
			return -1
		end

		return sprites.data.data:getPixel(x, y) / 16
	end

	fill.fillPixel = function(x, y, t, f)
		local c = fill.getPixel(x, y)

		if c == -1 or c ~= t then
			return
		end

		fill.setPixel(x, y, f)
	end

	fill.use = function(x, y, t, f)
		if t == nil or f == nil then
			t = fill.getPixel(x, y)
			f = sprites.color
			print(t)
		end

		print(x, y)

		fill.fillPixel(x, y, t, f)

		if fill.getPixel(x + 1, y) == t then
			fill.use(x + 1, y, t, f)
		end

		if fill.getPixel(x - 1, y) == t then
			fill.use(x - 1, y, t, f)
		end

		if fill.getPixel(x, y + 1) == t then
			fill.use(x, y + 1, t, f)
		end

		if fill.getPixel(x, y - 1) == t then
			fill.use(x, y - 1, t, f)
		end
	end

	sprites.tools = {
		pencil, stamp,
		select, move, fill
	}

	sprites.tools[1] = pencil
	sprites.tools[2] = stamp
	sprites.tools[3] = select
	sprites.tools[4] = move
	sprites.tools[5] = fill
	sprites.tool = pencil
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

	neko.cart, neko.core = neko.core, neko.cart

	-- tools

	for i, t in ipairs(sprites.tools) do
		if t == sprites.tool then
			api.pal(7, 15)
		else
			api.pal(7, 6)
		end

		api.spr(t.icon, 1, 63 + i * 10)
		i = i + 1
	end

	api.pal(7, 7)

	-- page buttons

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

	-- sprites
	api.brectfill(
		64, 8, 128,
		64, 0
	)

	api.sspr(
		0, sprites.page * 64,
		128, 64, 64, 8, 128, 64
	)

	-- sprite flags
	for i = 0, 7 do
		local f = sprites.data.flags[
				sprites.sprite
			]

		local c =	bit.band(bit.rshift(f, i), 1) == 1
			and i + 8 or 1

		api.circfill(13, 76 + i * 6, 2, c)
		api.circ(13, 76 + i * 6, 2, 0)
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
			64 + x * 8, 7 + y * 8,
			8 * sprites.scale, 8 * sprites.scale, 0
		)

		api.brect(
			63 + x * 8, 6 + y * 8,
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

			sprites.tool.use(mx, my - 8)

			sprites.data.sheet:refresh()
			sprites.forceDraw = true
		elseif my > 72 and my < 120 and
			mx > 15 and mx < 47 + 16 then
			mx = api.flr((mx - 16) / 12)
			my = api.flr((my - 72) / 12)

			sprites.color = api.mid(0, 15, mx + my * 4)
			sprites.forceDraw = true
		elseif lmb == false then
			if mx >= 10 and mx <= 18 then
				for i = 0, 7 do
					if my >= 68 + i * 6 and my <= 76 + i * 6 then
						local b = sprites.data.flags[sprites.sprite]
						sprites.data.flags[sprites.sprite] = flip(b, i)
						sprites.forceDraw = true
						return
					end
				end
			end

			if my >= 72 and my <= 80 then
				for i = 0, 3 do
					if mx >= 85 + i * 8 and mx <= 85 + 8 + i * 8 then
						sprites.page = i
						sprites.forceDraw = true
						return
					end
				end
			end

			if mx >= 1 and mx <= 9 then
				for i, t in ipairs(sprites.tools) do
					if my >= 63 + i * 10
						and my <= 71 + i * 10 then
						sprites.tool = t
						sprites.forceDraw = true
						return
					end
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

function sprites._cut()
	local data = sprites._copy()

	for y = api.flr(sprites.sprite / 16) * 8,
		api.flr(sprites.sprite / 16) * 8 + 7 do
		for x = (sprites.sprite % 16) * 8,
			(sprites.sprite % 16) * 8 + 7 do

			sprites.data.data:setPixel(x, y, 0, 0, 0, 255)
		end
	end

	sprites.data.sheet:refresh()
	sprites.forceDraw = true

	return data
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
				sprites.data.data:setPixel(x, y, v, v, v, 255)
				i = i + 1
			end
		end

		sprites.data.sheet:refresh()
		sprites.forceDraw = true
	end
end

return sprites