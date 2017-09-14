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
	return {
		pcall = pcall,
		loadstring = loadstring,
		setmetatable = setmetatable,
		require = require,

		-- this is required by the asm.lua callx operator
		unpck = table.unpack,

		ver = api.getversion,
		camera = api.camera,
		clip = api.clip,
		fget = api.fget,
		fset = api.fset,
		mget = api.mget,
		mset = api.mset,
		printh = print,
		csize = api.csize,
		rect = api.rect,
		rectfill = api.rectfill,
		brect = api.brect,
		brectfill = api.brectfill,
		color = api.color,
		cls = api.cls,
		circ = api.circ,
		circfill = api.circfill,
		pset = api.pset,
		pget = api.pget,
		line = api.line,
		print = api.print,
		flip = api.flip,
		cursor = api.cursor,
		cget = api.cget,
		scroll = api.scroll,
		spr = api.spr,
		sspr = api.sspr,
		sget = api.sget,
		sset = api.sset,
		pal = api.pal,
		palt = api.palt,
		map = api.map,
		ppget = api.ppget,
		sfx = api.sfx,
		music = api.music,

		tri = api.tri,
		trifill = api.trifill,
		poly = api.poly,
		polyfill = api.polyfill,

		memcpy = api.memcpy,

		btn = api.btn,
		btnp = api.btnp,
		key = api.key,

		flr = api.flr,
		ceil = api.ceil,
		cos = api.cos,
		sin = api.sin,
		rnd = api.rnd,
		srand = api.srand,
		max = api.max,
		min = api.min,
		mid = api.mid,
		abs = api.abs,
		sgn = api.sgn,
		atan2 = api.atan2,
		band = band,
		bnot = bnot,
		bor = bor,
		bxor = bxor,
		shl = shl,
		shr = shr,
		sqrt = api.sqrt,

		help = commands.help,
		folder = commands.folder,
		ls = commands.ls,
		run = commands.run,
		new = commands.new,
		mkdir = commands.mkdir,
		load = commands.load,
		save = commands.save,
		reboot = commands.reboot,
		shutdown = commands.shutdown,
		cd = commands.cd,
		rm = commands.rm,
		edit = commands.edit,
		minify = commands.minify,
		version = commands.version,

		pairs = pairs,
		ipairs = ipairs,
		string = string,
		add = api.add,
		del = api.del,
		all = api.all,
		count = api.count,
		foreach = api.foreach,

		smes = api.smes,
		nver = api.nver,
		mstat = api.mstat,
	}
end

function api.sfx(n, channel, offset)
	channel = channel or -1

	if n == -1 and channel >= 0 then
		audio.sfx[channel].sfx = nil
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
				if audio.currentMusic and neko.loadedCart.music[audio.currentMusic.music][i] < 64 then
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

				if slowestSpeed == nil or slowestSpeed > sfx.speed then
					slowestSpeed = sfx.speed
					slowestChannel = i
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


local function flip(byte, b)
  b = 2 ^ b
  return bit.bxor(byte, b)
end

function api.fset(n, v, f)
	-- fixme: implement
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

	ox = api.flr(ox)
	oy = api.flr(oy)
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

	cx = api.flr(cx)
	cy = api.flr(cy)
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
	if not pgetData or x < 0 or x > config.canvas.width - 1
		or y < 0 or y > config.canvas.height - 1 then
		return 0
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
		api.flr(x), api.flr(y),
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

function api.print(s, x, y, c)
	if c then
		api.color(c)
	end

	local scroll = (y == nil)

	if type(y) == "boolean" then
		scroll = y
		if not scroll then
			y = cursor.y
		end

		if scroll and type(x) == "boolean" and #s * 4 + cursor.x > config.canvas.width then
			local xy = api.flr(config.canvas.width - #s * 4 - 5 - cursor.x)
			api.print(s:sub(1, xy), x, y, c)
			api.print(s:sub(xy, -1), x, y, c)
			log.info(s)
			return
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
end

function api.flip()
	if gif then
		gif:frame(canvas.renderable:newImageData())
	end

	love.graphics.setScissor()
	love.graphics.origin()
	love.graphics.setCanvas(canvas.message)
	love.graphics.clear()

	if neko.message then
		api.rectfill(
			0, 0,
			config.canvas.width,
			7,
			config.messages.bg
		)

		api.print(
			neko.message.text,
			1, 1,
			config.messages.fg
		)
	end

	colors.displayShader:send(
		"palette",
		shaderUnpack(colors.display)
	)

	love.graphics.setShader(colors.displayShader)

	love.graphics.setCanvas()
	love.graphics.clear()

	love.graphics.draw(
		canvas.renderable,
		canvas.x, canvas.y, 0,
		canvas.scaleX, canvas.scaleY
	)

	if neko.message then
		love.graphics.draw(
			canvas.message, canvas.x,
			canvas.y + (config.canvas.height - 7)
			* canvas.scaleY,
			0, canvas.scaleX, canvas.scaleY
		)
	end

	if editors.opened and neko.cart == nil then
		local mx, my = api.mstat()
		neko.cart, neko.core = neko.core, neko.cart

		api.onCanvasSpr(
			neko.cursor.current,
			mx * canvas.scaleX
			+ canvas.x,
			my * canvas.scaleY
			+ canvas.y
		)

		neko.cart, neko.core = neko.core, neko.cart
	end

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

function api.onCanvasSpr(n, x, y, w, h, fx, fy)
	if neko.cart == nil then
		neko.cart = neko.loadedCart
			and neko.loadedCart or neko.core
	end

	n = api.flr(n)
	love.graphics.setShader(colors.onCanvasShader)


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
		0, api.flr((fx and -1 or 1) * canvas.scaleX),
		api.flr((fy and -1 or 1) * canvas.scaleY)
	)

	love.graphics.setShader(colors.displayShader)
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

	local q = love.graphics.newQuad(
		sx, sy, sw, sh,
		neko.cart.sprites.sheet:getDimensions()
	)

	love.graphics.setShader(colors.spriteShader)
	colors.spriteShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)

	love.graphics.draw(
		neko.cart.sprites.sheet, q,
		api.flr(dx) + (dw * (fx and 1 or 0)),
		api.flr(dy) + (dh * (fy and 1 or 0)),
		0, fx and -1 or 1 * (dw / sw),
		fy and -1 or 1 * (dh / sh)
	)

	love.graphics.setShader(colors.drawShader)
end

function api.sget(x, y)
	x = api.flr(x)
	y = api.flr(y)
	local r, g, b, a =
		neko.loadedCart.sprites.data:getPixel(x, y)
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
		if paletteModified == false then
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
		if t == false then
			colors.transparent[c + 1] = 1
		elseif t == true then
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

	if api.keyMap[p][b] then
		return api.keyPressed[p][b] ~= nil
	end

	return false
end

function api.btnp(b, p)
	p = p or 0

	if api.keyMap[p][b] then
		local v = api.keyPressed[p][b]
		if v and (v == 0 or (v >= 12 and v % 4 == 0)) then
			return true
		end
	end

	return false
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

function api.mstat(b)
	return api.flr((love.mouse.getX() - canvas.x)
		/ canvas.scaleX), api.flr((love.mouse.getY() - canvas.y)
		/ canvas.scaleY), love.mouse.isDown(b or 1),
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

function api.getversion(a)
	if a == "string" then return config.version.string
	elseif a == "minor" then return config.version.minor
	elseif a == "major" then return config.version.major
	elseif a == "name" then return config.version.name end
	return config.version.minor
end

return api
