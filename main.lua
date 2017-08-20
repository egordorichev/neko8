-----------------------------------------
-- main callbacks
-----------------------------------------

function love.load()
	log.info(
		"neko 8 " .. config.version.string
	)

	initCanvas()
	neko.init()
end

function love.update(dt)
	neko.update()
end

function love.draw()
	love.graphics.setCanvas(
		canvas.renderable
	)

	neko.draw()

	love.graphics.setCanvas()
	love.graphics.clear()
	love.graphics.draw(
		canvas.renderable,
		canvas.x, canvas.y, 0,
		canvas.scaleX, canvas.scaleY
	)
end

function love.resize(w, h)
	resizeCanvas(w,h)
	log.debug(
		"new window size: " .. w
		.. "x" .. h .. "px"
	)
end

-----------------------------------------
-- canvas helpers
-----------------------------------------

canvas = {
	x = 0,
	y = 0,
	scaleX = 1,
	scaleY = 1,
	renderable = nil
}

function initCanvas()
	canvas.renderable =
		love.graphics.newCanvas(
			config.canvas.width,
			config.canvas.height
		)


	canvas.renderable:setFilter(
		"nearest", "nearest"
	)

	resizeCanvas(
		love.graphics.getWidth(),
		love.graphics.getHeight()
	)
end

function resizeCanvas(width, height)
	local size = math.floor(
		math.min(
			width / config.canvas.width,
			height / config.canvas.height
		)
	)

	canvas.scaleX = size
	canvas.scaleY = size

	canvas.x =
		(width - size * config.canvas.width)
		/ 2
	canvas.y =
		(height - size * config.canvas.height)
		/ 2
end

-----------------------------------------
-- neko8
-----------------------------------------

neko = {}

function neko.init()
	initApi()
	neko.core = loadCart("neko")
	runCart(neko.core)
end

function neko.update()
	if neko.cart then
		neko.cart.sandbox._update()
	else
		neko.core.sandbox._update()
	end
end

function neko.draw()
	if neko.cart then
		neko.cart.sandbox._draw()
	else
		neko.core.sandbox._draw()
	end
end

-----------------------------------------
-- carts
-----------------------------------------

function loadCart(name)
	local cart = createCart()
	log.debug("loading cart " .. name)

	local pureName = name
	local extensions = { "" }

	if name:sub(-3) == ".n8" then
		extensions = { ".n8" }
		pureName = name:sub(1, - 4)
	end

	local found = false
	for i = 1, #extensions do
		if love.filesystem.isFile(
			pureName .. extensions[i]
		) then
			found = true
			name = pureName .. extensions[i]
			break
		end
	end

	if not found then
		log.error("failed to load cart")
		return cart
	end

	cart.name = name
	cart.pureName = pureName

	local data, size =
		love.filesystem.read(name)

	if not data then
		log.error("failed to open cart")
		return cart
	end

	local header = "neko8 cart"

	if not data:find(header) then
		log.error("invalid cart")
	end

	cart.code = loadCode(data, cart)

	--
	-- possible futures:
	-- sprites
	-- maps
	-- music
	-- sfx
	--

	return cart
end

function createCart()
	local cart = {}
	cart.sandbox = createSandbox()

	return cart
end

function loadCode(data, cart)
	local codeStart = data:find("__lua__")
		+ 8
	local codeEnd = data:find("__end__")
		- 1

	local code = data:sub(
		codeStart, codeEnd
	)

	return code
end

function runCart(cart)
	if not cart or not cart.sandbox then
		return
	end

	log.info(
		"running cart " .. cart.pureName
	)

	local ok, f, e = pcall(
		load, cart.code, cart.name
	)

	if e then
		log.error("syntax error:")
		log.error(e)
		return
	end

	local result
	setfenv(f, cart.sandbox)
	ok, result = pcall(f)

	if not ok then
		log.error("runtime error:")
		log.error(result)
		return
	end

	if cart.sandbox._init then
		cart.sandbox._init()
	end
end

-----------------------------------------
-- api
-----------------------------------------

api = {}

function initApi()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
end

function createSandbox()
	return {
		printh = print,
		csize = api.csize,
		rect = api.rect,
		rectfill = api.rectfill,
		brect = api.brect,
		brectfill = api.brectfill,
		color = api.color
	}
end

function api.csize()
	return config.canvas.width,
		config.canvas.height
end

function api.rect(x1, y1, x2, y2, c)
	if c then
		api.color(c)
	end

	love.graphics.rectangle("line",
		api.flr(x0) + 1,
		api.flr(y0) + 1,
		api.flr(x1 - x0),
		api.flr(y1 - y0))
end

function api.rectfill(x1, y1, x2, y2, c)
	if c then color(c) end

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
		"fill", flr(x0),
		flr(y0), w, h
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
		api.flr(h))
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

function api.color()

end

function api.flr(n)
	return math.floor(n or 0)
end

-----------------------------------------
-- logging
-----------------------------------------

--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

log = { _version = "0.1.0" }

log.usecolor = true
log.outfile = nil
log.level = "trace"

local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)
    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    print(string.format("%s[%-6s%s]%s %s: %s",
      log.usecolor and x.color or "",
      nameupper,
      os.date("%H:%M:%S"),
      log.usecolor and "\27[0m" or "",
      lineinfo,
      msg))

    -- Output to log file
    if log.outfile then
      local fp = io.open(log.outfile, "a")
      local str = string.format("[%-6s%s] %s: %s\n",
        nameupper, os.date(), lineinfo, msg)

			fp:write(str)
      fp:close()
    end
  end
end