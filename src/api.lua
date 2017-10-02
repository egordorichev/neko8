-----------------------------------------
-- api
-----------------------------------------

local api = {}

local bit = require "bit"

band = bit.band
bor = bit.bor
bxor = bit.bxor
bnot = bit.bnot
shl = bit.lshift
shr = bit.rshift

camera = {
	x = 0,
	y = 0
}

function initApi()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.mouse.setVisible(false)
	love.keyboard.setKeyRepeat(true)
	api.color()

	api.keyPressed = {
		[0] = {},
		[1] = {}
	}

	api.keyMap = {
		[0] = {
			[0] = { "left" },
			[1] = { "right" },
			[2] = { "up" },
			[3] = { "down" },
			[4] = { "z", "n" },
			[5] = { "x", "m" }
		},
		[1] = {
			[0] = { "s" },
			[1] = { "f" },
			[2] = { "e" },
			[3] = { "d" },
			[4] = { "tab", "lshift" },
			[5] = { "q", "a" }
		}
	}
end

function createSandbox(lang)
	local sandbox = {}

	if lang ~= "basic" then
		for k, v in pairs(apiList) do
			sandbox[k] = v[1]
		end
	end

	return sandbox
end

function api.exit()
	neko.cart = nil
end

function api.unload()
	neko.cart = nil
	neko.loadedCart = nil
end

function api.sfx(n, channel, offset)
	channel = channel or -1

	if n == -1 and channel >= 0 then
		audio.sfx[channel].sfx = nil
		audio.sfx[channel].offset = -1
		return
	elseif n == -2 and channel >= 0 then
		audio.sfx[channel].loop = false
	end

	offset = offset or 0

	if channel == -1 then
		for i = 0, 3 do
			if audio.sfx[i].sfx == nil then
				channel = i
			end
		end
	end

	if channel == -1 then
		return
	end

	local ch = audio.sfx[channel]

	ch.sfx = n
	ch.offset = offset
	ch.lastStep = offset - 1
	ch.loop = true
end

function api.music(n, fadeLen, channelMask)
	if n == -1 then
			for i = 0, 3 do
				if audio.currentMusic
					and neko.loadedCart.music[audio.currentMusic.music][i] < 64 then
					audio.sfx[i].sfx = nil
					audio.sfx[i].offset = 0
					audio.sfx[i].lastStep = -1
				end
			end
			audio.currentMusic = nil
			return
		end

		local m = neko.loadedCart.music[n]

		if not m then
			return
		end

		local slowestSpeed = nil
		local slowestChannel = nil

		for i = 0, 3 do
			if m[i] < 64 then
				local sfx = neko.loadedCart.sfx[m[i]]
				if sfx then
					if slowestSpeed == nil or slowestSpeed > sfx.speed then
						slowestSpeed = sfx.speed
						slowestChannel = i
					end
				end
			end
		end

		audio.sfx[slowestChannel].loop = false
		audio.currentMusic = {
			music = n,
			offset = 0,
			channelMask = channelMask or 15,
			speed = slowestSpeed
		}

		for i = 0, 3 do
			if neko.loadedCart.music[n][i] < 64 then
				audio.sfx[i].sfx = neko.loadedCart.music[n][i]
				audio.sfx[i].offset = 0
				audio.sfx[i].lastStep = -1
			end
		end

end

function api.ppget()
	pgetData = canvas.renderable:newImageData()
end

function api.tri(x0, y0, x1, y1, x2, y2, c)
	if not x0 or not y0 or not x1 or not y1 or not x2 or not y2 then
		return
	end

	if c ~= nil then
		api.color(c)
	end

	love.graphics.polygon("line", x0, y0, x1, y1, x2, y2)
end

function api.trifill(x0, y0, x1, y1, x2, y2, c)
	if not x0 or not y0 or not x1 or not y1 or not x2 or not y2 then
		return
	end

	if c ~= nil then
		api.color(c)
	end

	love.graphics.polygon("fill", x0, y0, x1, y1, x2, y2)
end

function api.poly(...)
	love.graphics.polygon("line", ...)
end

function api.polyfill(...)
	love.graphics.polygon("fill", ...)
end

function setCamera()
	love.graphics.origin()
	love.graphics.translate(-camera.x, -camera.y)
end

function api.camera(x, y)
	camera.x = x or 0
	camera.y = y or 0
end

function setClip()
	if clip then
		love.graphics.setScissor(unpack(clip))
	else
		love.graphics.setScissor(
			0, 0, config.canvas.width,
			config.canvas.height
		)
	end
end

function api.clip(x, y, w, h)
	if type(x) == "number" then
		love.graphics.setScissor(x, y, w, h)
		clip = { x, y, w, h }
	else
		love.graphics.setScissor(
			0, 0, config.canvas.width,
			config.canvas.height
		)

		clip = nil
	end
end

function api.fget(n, f)
	if n == nil then return nil end
	n = api.flr(n)

	if f ~= nil then
		if not neko.loadedCart.sprites.flags[n] then
			return 0
		end

		return band(neko.loadedCart.sprites.flags[n], shl(1, f)) ~= 0
	end

	return neko.loadedCart.sprites.flags[n]
end

function api.fset(n, v, f)
	if v == nil then
		v, f = f, nil
	end

	if f ~= nil then
		if type(f) == "boolean" then
			f = f == true and 1 or 0
		end

		if f == 1 then
			neko.loadedCart.sprites.flags[n] = bit.bor(
				neko.loadedCart.sprites.flags[n], (bit.lshift(1, v))
			)
		else
			neko.loadedCart.sprites.flags[n] = bit.band(
			neko.loadedCart.sprites.flags[n],
				(bit.lshift(1, v)) == 1 and 0 or 1
			)
		end
	else
		neko.loadedCart.sprites.flags[n] = v
	end
end

function api.mget(x, y)
	if x == nil or y == nil
		or x < 0 or x > 127 or y < 0
		or y > 127 then
		return 0
	end

	return neko.loadedCart.map
		[api.flr(y)]
		[api.flr(x)]
end

function api.mset(x, y, v)
	if x == nil or y == nil
		or x < 0 or x > 127 or y < 0
		or y > 127 then
		return
	end

	neko.loadedCart.map
		[api.flr(y)]
		[api.flr(x)] = v or 0
end

function api.csize()
	return config.canvas.width,
		config.canvas.height
end

function api.rect(x0, y0, x1, y1, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("line",
		api.flr(x0) + 1,
		api.flr(y0) + 1,
		api.flr(x1 - x0),
		api.flr(y1 - y0)
	)
end

function api.rectfill(x0, y0, x1, y1, c)
	if c then
		api.color(c)
	end

	local w = (x1 - x0) + 1
	local h = (y1 - y0) + 1

	if w < 0 then
		w = -w
		x0 = x0 - w
	end

	if h < 0 then
		h = -h
		y0 = y0 - h
	end

	love.graphics.rectangle(
		"fill", api.flr(x0),
		api.flr(y0), w, h
	)
end

function api.brect(x, y, w, h, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("line",
		api.flr(x) + 1,
		api.flr(y) + 1,
		api.flr(w),
		api.flr(h)
	)
end

function api.brectfill(x, y, w, h, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("fill",
		api.flr(x),
		api.flr(y),
		api.flr(w),
		api.flr(h))
end

function api.color(c)
	if not c then
		c = 7
	else
		c = api.flr(c % 16)
	end

	love.graphics.setColor(
		c * 16, 0, 0, 255
	)

	colors.current = c
end

function api.circ(ox, oy, r, c)
	if c then
		api.color(c)
	end

	ox = api.flr(ox) + 1
	oy = api.flr(oy) + 1
	r = api.flr(r)

	local points = {}
	local x = r
	local y = 0
	local decisionOver2 = 1 - x

	while y <= x do
		table.insert(points, {ox + x, oy + y})
		table.insert(points, {ox + y, oy + x})
		table.insert(points, {ox - x, oy + y})
		table.insert(points, {ox - y, oy + x})

		table.insert(points, {ox - x, oy - y})
		table.insert(points, {ox - y, oy - x})
		table.insert(points, {ox + x, oy - y})
		table.insert(points, {ox + y, oy - x})

		y = y + 1
		if decisionOver2 < 0 then
			decisionOver2 = decisionOver2
				+ 2 * y + 1
		else
			x = x - 1
			decisionOver2 = decisionOver2
				+ 2 * (y - x) + 1
		end
	end
	if #points > 0 then
		love.graphics.points(points)
	end
end

function _plot4points(
	points, cx, cy, x, y
)
	_horizontal_line(points, cx - x,
		cy + y, cx + x)
	if y ~= 0 then
		_horizontal_line(points, cx - x,
			cy - y, cx + x)
	end
end

function _horizontal_line(
	points, x0, y, x1
)
	for x = x0, x1 do
		table.insert(points, {x, y})
	end
end

function api.circfill(cx, cy, r, c)
	if c then
		api.color(c)
	end

	cx = api.flr(cx) + 1
	cy = api.flr(cy) + 1
	r = api.flr(r)

	local x = r
	local y = 0
	local err = 1 - r

	local points = {}

	while y <= x do
		_plot4points(points, cx, cy, x, y)

		if err < 0 then
			err = err + 2 * y + 3
		else
			if x ~= y then
				_plot4points(points, cx, cy, y, x)
			end

			x = x - 1
			err = err + 2 * (y - x) + 3
		end
		y = y + 1
	end

	if #points > 0 then
		love.graphics.points(points)
	end
end

function api.pget(x, y)
	x = x
	y = y
	if not pgetData or x < 0 or x > config.canvas.width
		or y < 0 or y > config.canvas.height then
		return 10
	end

	x = api.flr(x)
	y = api.flr(y)

	return api.flr(pgetData:getPixel(x, y) / 17)
end

function api.pset(x, y, c)
	if not c then
		return
	end

	api.color(c)
	love.graphics.points(
		api.flr(x) + 0.5, api.flr(y) + 0.5,
		c * 16, 0, 0, 255
	)
end

function api.line(x1, y1, x2, y2, c)
	if c then
		api.color(c)
	end

	love.graphics.line(x1, y1, x2, y2)
end

cursor = {
	x = 0,
	y = 0
}

function api.print(s, x, y, c, i)
	if s == nil then return end

	if c then
		api.color(c)
	end

	if type(s) == "number" then
		s = tostring(s)
	end

	local parts = {}

	for p in string.gmatch(s, "([^\n]+)") do
		table.insert(parts, p)
	end

	if #parts > 1 then
		if y == nil then
			y = cursor.y
			scroll = true
		end

		if x == nil then
			x = cursor.x
		end

		local n = 0

		for i, p in ipairs(parts) do
			n = n + api.print(p, x, y)
			y = y + 6

			if scroll and y >= 120 then
				local c = c or colors.current
				api.scroll(12)
				y = 108

				api.color(c)
				api.cursor(0, y)
				api.flip()
			end
		end

		if scroll then
			cursor.y = cursor.y + n * 6
		end

		return n
	end

	local scroll = (y == nil)

	if s ~= "" and type(x) ~= "boolean" and type(y) ~= "boolean"
		and #s * 4 + cursor.x > config.canvas.width and not i then
		local dx = api.flr((config.canvas.width - cursor.x) / 4)
		local s1 = s:sub(1, dx)
		local s2 = s:sub(dx + 1, -1)

		api.print(s1, x, y, c)

		if type(y) == "number" then
			y = y + 6
		end

		return api.print(s2, 0, y, c) + 1
	end

	if type(y) == "boolean" then
		scroll = y
		if not scroll then
			y = cursor.y
		end
	end

	if type(x) == "boolean" then
		x = cursor.x
		cursor.x = cursor.x + #s * 4
	end

	if scroll then
		y = cursor.y
		cursor.y = cursor.y + 6
	end

	if x == nil or type(x) == "boolean" then
		x = cursor.x
	end

	if scroll and y >= 120 then
		local c = c or colors.current
		api.scroll(6)
		y = 114

		api.color(c)
		api.cursor(0, y + 6)
		api.flip()
	end

	if scroll then
		local c = colors.current
		api.brectfill(api.flr(x), api.flr(y) - 1, #s * 4, 7, 0)
		api.color(c)
	end

	love.graphics.setShader(
		colors.textShader
	)

	love.graphics.print(
		s, api.flr(x), api.flr(y) + 1
		-- watch out that +1!
	)

	return 0
end

function api.flip()
	colors.displayShader:send(
		"palette",
		shaderUnpack(colors.display)
	)

	love.graphics.setScissor()
	love.graphics.origin()

	-- FIXME
	if gif then
		love.graphics.setCanvas(canvas.gif)
		love.graphics.setShader()
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.clear(0, 0, 0, 255)

		love.graphics.draw(
			canvas.renderable,
			0, 0, 0, config.canvas.gifScale, config.canvas.gifScale
		)

		gif:frame(canvas.gif:newImageData())
	end

	love.graphics.setCanvas(canvas.support)

	love.graphics.setShader(colors.supportShader)
	love.graphics.draw(
		canvas.renderable, 0, 0
	)

	love.graphics.setShader(colors.drawShader)

	if not neko.focus then
		-- love.graphics.clear()
		-- api.print("click to focus", 68, 62, 7)
	end

	if neko.message then
		api.brectfill(
			0, config.canvas.height - 7,
			config.canvas.width,
			7,
			config.messages.bg
		)

		api.print(
			neko.message.text,
			1, config.canvas.height - 6,
			config.messages.fg
		)
	end

	if not mobile and editors.opened and neko.cart == nil then
		local mx, my = api.mstat()
		neko.cart, neko.core = neko.core, neko.cart

		for i = 0, 15 do
			api.pal(i, 1)
		end

		for x = -1, 1 do
			for y = x == 0 and -1 or 0, x == 0 and 1 or 0 do
				api.spr(
					neko.cursor.current,
					mx + x,
					my + y
				)
			end
		end

		api.pal()

		api.spr(
			neko.cursor.current,
			mx,
			my
		)

		neko.cart, neko.core = neko.core, neko.cart
	end

	love.graphics.setShader(
		colors.displayShader
	)

	love.graphics.setCanvas()
	love.graphics.clear()

	love.graphics.draw(
		canvas.support,
		canvas.x, canvas.y, 0,
		canvas.scaleX, canvas.scaleY
	)

	love.graphics.present()
	love.graphics.setShader(colors.drawShader)
	love.graphics.setCanvas(canvas.renderable)

	setClip()
	setCamera()
end

function api.cursor(x, y)
	cursor.x = x or cursor.x
	cursor.y = y or cursor.y
end

function api.cget()
	return cursor.x, cursor.y
end

function api.scroll(pixels)
	local sc = canvas.renderable:newImageData()

	sc:mapPixel(function(x, y, r, g, b, a)
		return r - 1, g, b, a
	end)

	local i = love.graphics.newImage(sc)
	i:setFilter("nearest")

	api.cls()
	love.graphics.setShader(colors.spriteShader)
	love.graphics.draw(i, 0, -pixels)
	love.graphics.setShader(colors.drawShader)
end

function api.spr(n, x, y, w, h, fx, fy)
	if neko.cart == nil then
		neko.cart = neko.loadedCart
			and neko.loadedCart or neko.core
	end

	n = api.flr(n)
	love.graphics.setShader(colors.spriteShader)
	colors.spriteShader:send(
		"transparent", shaderUnpack(colors.transparent)
	)

	w = w or 1
	h = h or 1

	local q
	if w == 1 and h == 1 then
		q = neko.cart.sprites.quads[n]
	else
		local id = string.format('%d-%d-%d', n, w, h)
		if neko.cart.sprites.quads[id] then
			q = neko.cart.sprites.quads[id]
		else
			q = love.graphics.newQuad(
				api.flr(n % 16) * 8,
				api.flr(n / 32) * 8, 8 * w,
				8 * h, 128, 256
			)

			neko.cart.sprites.quads[id] = q
		end
	end

	love.graphics.draw(
		neko.cart.sprites.sheet, q,
		api.flr(x) + (w * 8 * (fx and 1 or 0)),
		api.flr(y) + (h * 8 * (fy and 1 or 0)),
		0, fx and -1 or 1,
		fy and -1 or 1
	)

	love.graphics.setShader(colors.drawShader)
end

function api.sspr(
	sx, sy, sw, sh, dx, dy, dw, dh, fx,fy
)
	if neko.cart == nil then
		neko.cart = neko.loadedCart
			and neko.loadedCart or neko.core
	end

	dw = dw or sw
	dh = dh or sh

	-- todo: cache this quad

	local q = (not coresprites) and love.graphics.newQuad(
		sx, sy, sw, sh,
		neko.cart.sprites.sheet:getDimensions()
	) or love.graphics.newQuad(
		sx, sy, sw, sh,
		neko.core.sprites.sheet:getDimensions()
	)

	love.graphics.setShader(colors.spriteShader)
	colors.spriteShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)


	if not coresprites then
		love.graphics.draw(
			neko.cart.sprites.sheet, q,
			api.flr(dx) + (dw * (fx and 1 or 0)),
			api.flr(dy) + (dh * (fy and 1 or 0)),
			0, fx and -1 or 1 * (dw / sw),
			fy and -1 or 1 * (dh / sh)
		)
	else
		love.graphics.draw(
			neko.core.sprites.sheet, q,
			api.flr(dx) + (dw * (fx and 1 or 0)),
			api.flr(dy) + (dh * (fy and 1 or 0)),
			0, fx and -1 or 1 * (dw / sw),
			fy and -1 or 1 * (dh / sh)
		)
	end

	love.graphics.setShader(colors.drawShader)
end

function api.sget(x, y)
	x = api.flr(x)
	y = api.flr(y)
	local r, g, b, a = neko.loadedCart.sprites.data:getPixel(x, y)
	return api.flr(r / 16)
end

function api.sset(x, y, c)
	x = api.flr(x)
	y = api.flr(y)
	neko.loadedCart.sprites.data:setPixel(
		x, y, c * 16, 0, 0, 255
	)
	neko.loadedCart.sprites.sheet:refresh()
end

local paletteModified = false

function api.pal(c0,c1,p)
	if type(c0) ~= "number" then
		if not paletteModified then
			return
		end

		for i = 1, 16 do
			colors.draw[i] = i
			colors.display[i] = colors.palette[i]
		end

		colors.drawShader:send(
			"palette", shaderUnpack(colors.draw)
		)

		colors.spriteShader:send(
			"palette", shaderUnpack(colors.draw)
		)

		colors.textShader:send(
			"palette", shaderUnpack(colors.draw)
		)

		colors.displayShader:send(
			"palette", shaderUnpack(colors.display)
		)

		paletteModified = false

		api.palt()
		api.palt()
	elseif p == 1 and c1 ~= nil then
		c0 = api.flr(c0) % 16
		c1 = api.flr(c1) % 16
		c1 = c1 + 1
		c0 = c0 + 1
		colors.display[c0] = colors.palette[c1]

		colors.displayShader:send(
			"palette", shaderUnpack(colors.display)
		)

		paletteModified = true
	elseif c1 ~= nil then
		c0 = api.flr(c0) % 16
		c1 = api.flr(c1) % 16
		c1 = c1 + 1
		c0 = c0 + 1
		colors.draw[c0] = c1

		colors.drawShader:send(
			"palette", shaderUnpack(colors.draw)
		)

		colors.spriteShader:send(
			"palette", shaderUnpack(colors.draw)
		)

		colors.textShader:send(
			"palette", shaderUnpack(colors.draw)
		)

		paletteModified = true
	end
end

function api.palt(c, t)
	if type(c) ~= "number" then
		for i= 1, 16 do
			colors.transparent[i] = i == 1 and 0 or 1
		end
	else
		c = api.flr(c) % 16
		if not t then
			colors.transparent[c + 1] = 1
		else
			colors.transparent[c + 1] = 0
		end
	end

	colors.spriteShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)
end

function api.map(
	cx, cy, sx, sy, cw, ch, bitmask
)

	love.graphics.setShader(colors.spriteShader)
	love.graphics.setColor(255, 255, 255, 255)

	cx = cx and api.flr(cx) or 0
	cy = cy and api.flr(cy) or 0
	sx = cx and api.flr(sx) or 0
	sy = cy and api.flr(sy) or 0
	cw = cw and api.flr(cw) or 24
	ch = ch and api.flr(ch) or 16

	for y = 0, ch - 1 do
		if cy + y < 64 and cy + y >= 0 then
			for x = 0, cw - 1 do
				if cx + x < 128 and cx + x >= 0 then
					local v = api.mget(cx + x, cy + y)

					if v > 0 then
						if bitmask == nil or bitmask == 0 then
							love.graphics.draw(
								neko.loadedCart.sprites.sheet,
								neko.loadedCart.sprites.quads[v],
								sx + 8 * x,
								sy + 8 * y
							)
						else
							if band(neko.loadedCart.sprites.flags[v], bitmask) ~= 0 then
								love.graphics.draw(
									neko.loadedCart.sprites.sheet,
									neko.loadedCart.sprites.quads[v],
									sx + 8 * x,
									sy + 8 * y
								)
							end
						end
					end
				end
			end
		end
	end

	love.graphics.setShader(colors.drawShader)
end

function api.memcpy(dest, source, len)
	-- todo
end

function api.btn(b, p)
	p = p or 0
	b = b + 2

	if b < 1 or b > 7 or p < 0 or p > 1 then return false end

	if p == 1 then
		if api.keyMap[p][b] then
			return api.keyPressed[p][b] ~= nil
		end
		return false
	else
		if g then
			return g.b[b].ispressed
		else
			return false
		end
	end
end

function api.btnp(b, p)
	p = p or 0
	b = b + 2

	if b < 1 or b > 7 or p < 0 or p > 1 then return false end

	if p == 1 then
		if api.keyMap[p][b] then
			local v = api.keyPressed[p][b]
			if v and (v == 0 or (v >= 12 and v % 4 == 0)) then
				return true
			end
		end
		return false
	else
		if g then
			return g.b[b].isnewpress
		else
			return false
		end
	end
end

function api.gdisable()
	exg = g
	g = null
end

function api.genable()
	g = g or exg
end

function api.btnkpressed(b)
	b = b + 2

	if b < 1 or b > 7 then return end

	if g then
		return g.b[b]:keeppressed()
	else
		return
	end
end

function api.btnkreleased(b)
	b = b + 2

	if b < 1 or b > 7 then return end

	if g then
		return g.b[b]:keepreleased()
	else
		return
	end
end

function api.btnrelease(b)
	b = b + 2

	if b < 1 or b > 7 then return end

	if g then
		return g.b[b]:release()
	else
		return
	end
end

function api.key(k)
	return love.keyboard.isDown(k)
end

function api.cls(c)
	if c then
		api.color(c)
	end

	c = c or 0

	love.graphics.clear(
		(c + 1) * 16, 0, 0, 255
	)

	cursor.x = 0
	cursor.y = 0
end

function api.flr(n)
	return math.floor(n or 0)
end

function api.sqrt(n)
	return math.sqrt(n or 0)
end

function api.ceil(n)
	return math.ceil(n or 0)
end

function api.cos(n)
	return math.cos(
		(n or 0) * (math.pi * 2)
	)
end

function api.sin(n)
	return math.sin(
		-(n or 0) * (math.pi * 2)
	)
end

function api.atan2(x, y)
	x = x or 0
	y = y or 0

	return (0.75 + math.atan2(x, y) / (math.pi * 2)) % 1.0
end

function api.rnd(min, max)
	min = min or 1
	if max then
		return math.random(min, max)
	else
		return math.random() * min
	end
end

function api.srand(s)
	math.randomseed(s or 0)
end

function api.min(a, b)
	return a < b and a or b
end

function api.max(a, b)
	return a > b and a or b
end

function api.mid(x, y, z)
	x, y, z = x or 0, y or 0, z or 0
	if x > y then
		x, y = y, x
	end

	return api.max(x, api.min(y, z))
end

function api.abs(n)
	return n and math.abs(n) or 0
end

function api.sgn(n)
	if n == nil then
		return 1
	end

	return n < 0 and -1 or 1
end

function api.add(a, v)
	if a == nil then
		return
	end
	table.insert(a, v)
end

function api.del(a, dv)
	if a == nil then
		return
	end
	for i, v in ipairs(a) do
		if v == dv then
			table.remove(a,i)
		end
	end
end

function api.foreach(a, f)
	if not a then
		return
	end
	for i, v in ipairs(a) do
		f(v)
	end
end

function api.smes(s)
	neko.showMessage(s)
end

function api.nver()
	return config.version.string
end

function api.mstat(...)
	return api.flr((love.mouse.getX() - canvas.x)
		/ canvas.scaleX), api.flr((love.mouse.getY() - canvas.y)
		/ canvas.scaleY), love.mouse.isDown(...),
	mbt > 1
end

function api.count(a)
	return #a
end

function api.all(a)
	local i = 0
	local n = table.getn(a)
	return function()
		i = i + 1
		if i <= n then return a[i] end
	end
end

apiList = {
	[ "pcall" ] = { pcall, 1 },
	[ "string" ] = { string, 0 },
	[ "math" ] = { math, 0 },
	[ "setmetatable" ] = { setmetatable, 2 },
	[ "getmetatable" ] = { getmetatable, 1 },
	[ "table" ] = { table, 0 },
	[ "type" ] = { type, 1 },
	[ "require" ] = { require, 1 },
	[ "tostring" ] = { tostring, 1 },
	[ "tonumber" ] = { tonumber, 1 },
	[ "assert" ] = { assert, 1 },
	[ "unpck" ] = { table.unpack, 1 },
	[ "next" ] = { next, 1 },
	[ "nextvar" ] = { nextvar, 1 },
	[ "error" ] = { runtimeError, 1 },

	[ "camera" ] = { api.camera, 2 },
	[ "clip" ] = { api.clip, 4 },
	[ "fget" ] = { api.fget, 2 },
	[ "fset" ] = { api.fset, 3 },
	[ "mget" ] = { api.mget, 2 },
	[ "mset" ] = { api.mset, 3 },
	[ "printh" ] = { print, vararg },
	[ "csize" ] = { api.csize, 0 },
	[ "rect" ] = { api.rect, 5 },
	[ "rectfill" ] = { api.rectfill, 5 },
	[ "brect" ] = { api.brect, 5 },
	[ "brectfill" ] = { api.brectfill, 5 },
	[ "color" ] = { api.color, 1 },
	[ "cls" ] = { api.cls, 1 },
	[ "circ" ] = { api.circ, 4 },
	[ "circfill" ] = { api.circfill, 4 },
	[ "pset" ] = { api.pset, 3 },
	[ "pget" ] = { api.pget, 2 },
	[ "line" ] = { api.line, 5 },
	[ "print" ] = { api.print, vararg },
	[ "flip" ] = { api.flip, 0 },
	[ "cursor" ] = { api.cursor, 2 },
	[ "cget" ] = { api.cget, 0 },
	[ "scroll" ] = { api.scroll, 1 },
	[ "spr" ] = { api.spr, vararg },
	[ "sspr" ] = { api.sspr, vararg },
	[ "sget" ] = { api.sget, 2 },
	[ "sset" ] = { api.sset, 3 },
	[ "pal" ] = { api.pal, 2 },
	[ "palt" ] = { api.palt, 2 },
	[ "map" ] = { api.map, vararg },
	[ "ppget" ] = { api.ppget, 0 },
	[ "sfx" ] = { api.sfx, 1 },
	[ "music" ] = { api.music, 1 },

	[ "tri" ] = { api.tri, 6 },
	[ "trifill" ] = { api.trifill, 6 },
	[ "poly" ] = { api.poly, vararg },
	[ "polyfill" ] = { api.polyfill, vararg },

	[ "btn" ] = { api.btn, 1 },
	[ "btnp" ] = { api.btnp, 1 },
	[ "btnkpressed" ] = { api.btnkpressed, 1 },
	[ "btnkreleased" ] = { api.btnkreleased, 1 },
	[ "btnrelease" ] = { api.btnrelease, 1 },
	[ "genable" ] = { api.genable, 0 },
	[ "gdisable" ] = { api.gdisable, 0 },
	[ "key" ] = { api.key, 1 },

	[ "flr" ] = { api.flr, 1 },
	[ "ceil" ] = { api.ceil, 1 },
	[ "cos" ] = { api.cos, 1 },
	[ "sin" ] = { api.sin, 1 },
	[ "rnd" ] = { api.rnd, 1 },
	[ "srand" ] = { api.srand, 1 },
	[ "max" ] = { api.max, 2 },
	[ "min" ] = { api.min, 2 },
	[ "mid" ] = { api.mid, 3 },
	[ "abs" ] = { api.abs, 1 },
	[ "sgn" ] = { api.sgn, 1 },
	[ "atan2" ] = { api.atan2, 1 },
	[ "band" ] = { band, 2 },
	[ "bnot" ] = { bnot, 2 },
	[ "bor" ] = { bor, 2 },
	[ "bxor" ] = { bxor, 2 },
	[ "shl" ] = { shl, 2 },
	[ "shr" ] = { shr, 2 },
	[ "sqrt" ] = { api.sqrt, 1 },

	[ "load" ] = { carts.load, 0 },
	[ "run" ] = { carts.run, 0 },
	[ "new" ] = { commands.new, 0 },
	[ "mkdir" ] = { commands.mkdir, 0 },
	[ "save" ] = { commands.save, 0 },
	[ "reboot" ] = { commands.reboot, 0 },
	[ "shutdown" ] = { commands.shutdown, 0 },
	[ "folder" ] = { commands.folder, 0 },
	[ "cd" ] = { commands.cd, 0 },
	[ "rm" ] = { commands.rm, 0 },
	[ "edit" ] = { commands.edit, 0 },
	[ "minify" ] = { commands.minify, 0 },
	[ "pwd" ] = { commands.pwd, 0 },
	[ "ls" ] = { commands.ls, 0 },
	[ "install_demos" ] = { commands.installDemos, 0 },
	[ "exit" ] = { api.exit, 0 },
	[ "unload" ] = { api.unload, 0 },

	[ "pairs" ] = { pairs, 1 },
	[ "ipairs" ] = { ipairs, 1 },
	[ "add" ] = { api.add, 2 },
	[ "del" ] = { api.del, 2 },
	[ "all" ] = { api.all, 1 },
	[ "count" ] = { api.count, 1 },
	[ "foreach" ] = { api.foreach, 2 },

	[ "smes" ] = { api.smes, 2 },
	[ "nver" ] = { api.nver, 0 },
	[ "mstat" ] = { api.mstat, 0 }
}

_TBASIC.INIT()

apiNamesOnly = {}
apiNamesOnlyUpperCase = {}

for k, v in pairs(apiList) do
	table.insert(apiNamesOnly, k)
	table.insert(apiNamesOnlyUpperCase, string.upper(k))
end

return api