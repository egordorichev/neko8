-----------------------------------------
-- carts
-----------------------------------------

local carts = {}

require "libs.terran-basic.TBASEXEC"
require "libs.moonscript.moonscript"
moonscript = require "libs.moonscript.moonscript.base"

function carts.load(name)
	local cart = {}

	local pureName = name
	local extensions = { "", ".n8" }

	if name:sub(-3) == ".n8" then
		extensions = { ".n8" }
		pureName = name:sub(1, -4)
	end

	local found = false

	for i = 1, #extensions do
		local n = resolveFile(pureName .. extensions[i], neko.currentDirectory)
		local v = n:sub(1, 10) == "/programs/"

		if love.filesystem.isFile(n) and (v or isVisible(n, "/")) then
			found = true
			name = n
			break
		end
	end

	if not found then
		log.error("failed to load cart " .. name)
		if neko.core == nil then
			error("Failed to load neko.n8. Did you delete it, hacker?")
		end
		return nil
	end

	cart.name = name
	cart.pureName = pureName

	local data, size = love.filesystem.read(name)

	if not data then
		log.error("failed to open cart")
		return cart
	end

	-- FIXES CRLF file endings
	data = data:gsub("\r\n", "\n")
	data = data:gsub("\r", "\n")

	local loadData = cart.pureName:sub(1, 10) ~= "/programs/"
	local header = "neko8 cart"

	if not data:find(header) then
		log.error("invalid cart")
		return nil
	end

	cart.code, cart.lang = carts.loadCode(data, cart)
	cart.sandbox = createSandbox(cart.lang)

	if not cart.code then
		log.error("failed to load code")
		return cart
	end

	cart.sprites = carts.loadSprites(data, cart)

	if not cart.sprites then
		log.error("failed to load sprites")
		return cart
	end

	cart.map = carts.loadMap(data, cart)

	if not cart.map then
		log.error("failed to load map")
		return cart
	end

	cart.sfx = carts.loadSFX(data, cart)

	if not cart.sfx then
		log.error("failed to load sfx")
		return cart
	end

	cart.music = carts.loadMusic(data, cart)

	if not cart.music then
		log.error("failed to load music")
		return cart
	end

	if cart.lang == "basic" then
		cart.sandbox._TBASIC = _TBASIC
	end

	love.graphics.setShader(
		colors.drawShader
	)

	setCamera()
	setClip()


	if loadData then
		log.debug("loading data")
		editors.openEditor(1)

		neko.loadedCart = cart
		carts.import(cart)
	end

	return cart
end

function carts.import(cart)
	editors.code.import(cart.code)
	editors.sprites.import(cart.sprites)
	editors.map.import(cart.map)
	editors.sfx.import(cart.sfx)
	editors.music.import(cart.music)

	for _, m in pairs(editors.modes) do
		if m.postImport then
			m.postImport()
		end
	end
end

function carts.export()
	neko.loadedCart.code = editors.code.export()
end

function carts.create(lang)
	audio.currentMusic = nil

	local cart = {}
	cart.name = "new"
	cart.pureName = "new"
	cart.sandbox = createSandbox()
	cart.lang = lang or "lua"

	if cart.lang == "lua" then
		cart.code = [[
-- cart name
-- by @author

function _init()

end

function _update()

end

function _draw()
 cls()
end
]]
	elseif cart.lang == "asm" then
		cart.code = [[
-- cart name
-- by @author

section .data

section .text

extern _init
extern _update
extern _draw

init:
 ret
end

update:
 ret
end

draw:
 ret
end

mov [_init], [init]
mov [_update], [update]
mov [_draw], [draw]
]]
	elseif cart.lang == "basic" then
		cart.sandbox._TBASIC = _TBASIC
		initBasicAPI()
		-- todo: comments ??
		cart.code = [[
10 T=0
20 PRINTH("HELLO, WORLD")
30 PRINT("HELLO WORLD ",T)
40 T+=1
50 IF T<10 THEN GOTO 20
60 END

]]
	elseif cart.lang == "moonscript" then
		cart.code = [[
-- cart name
-- by @author

export _init=->

export _update=->

export _draw=->
]]
	end

	cart.sprites = {}
	cart.sprites.data = love.image.newImageData(128, 256)
	cart.sprites.sheet = love.graphics.newImage(cart.sprites.data)
	cart.sprites.quads = {}

	local sprite = 0

	for y = 0, 31 do
		for x = 0, 15 do
			cart.sprites.quads[sprite] =
				love.graphics.newQuad(
					8 * x, 8 * y, 8, 8, 128, 256
				)

			sprite = sprite + 1
		end
	end

	cart.sprites.flags = {}

	for i = 0, 511 do
		cart.sprites.flags[i] = 0
	end

	cart.map = {}

	for y = 0, 127 do
		cart.map[y] = {}
		for x = 0, 127 do
			cart.map[y][x] = 0
		end
	end

	cart.sfx = {}

	for i = 0, 63 do
		cart.sfx[i] = {
			speed = 16,
			loopStart = 0,
			loopEnd = 0
		}

		for j = 0, 31 do
			cart.sfx[i][j] = { 0, 0, 0, 0 }
		end
	end

	cart.music = {}

	for i = 0, 63 do
		cart.music[i] = {
			loop = 0,
			[0] = 0,
			[1] = 1,
			[2] = 2,
			[3] = 3
		}
	end

	return cart
end

function carts.loadCode(data, cart)
	local codeTypes = { "lua", "asm", "basic", "moonscript" }

	local codeType
	local codeStart

	for _, v in ipairs(codeTypes) do
		_, codeStart = data:find(string.format("\n__%s__\n", v))
		if codeStart then
			codeType = v
		break
	end
	end

	if not codeStart then
		runtimeError("Could't find a valid code section in cart")
		return
	end

	local codeEnd = data:find("\n__gfx__\n") or data:find("__end__") - 1

	local code = data:sub(
		codeStart + 1, codeEnd
	)

	return code, codeType
end

function carts.loadSprites(cdata, cart)
	local sprites = {}

	sprites.data = love.image.newImageData(128, 256)

	sprites.quads = {}
	sprites.flags = {}

	local _, gfxStart = cdata:find("\n__gfx__\n")
	local gfxEnd = cdata:find("\n__gff__\n")

	if not gfxStart or not gfxEnd then
		sprites.data = love.image.newImageData(128, 256)
		sprites.sheet = love.graphics.newImage(sprites.data)
		sprites.quads = {}

		local sprite = 0

		for y = 0, 31 do
			for x = 0, 15 do
				sprites.quads[sprite] =
					love.graphics.newQuad(
						8 * x, 8 * y, 8, 8, 128, 256
					)

				sprite = sprite + 1
			end
		end

		sprites.flags = {}

		for i = 0, 511 do
			sprites.flags[i] = 0
		end

		log.info("old file")
		return sprites -- old versions
	end

	local data = cdata:sub(gfxStart, gfxEnd)

	local row = 0
	local col = 0
	local sprite = 0
	local shared = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = data:find("\n", nextLine)

		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = data:sub(nextLine, lineEnd)

		for i = 1, #line do
			-- fixme: windows fails?
			local v = line:sub(i, i)
			v = tonumber(v, 16) or 0
			sprites.data:setPixel(
				col, row, v * 16, v * 16,
				v * 16, 255
			)

			col = col + 1

			if col == 128 then
				col = 0
				row = row + 1
			end
		end

		nextLine = data:find("\n", lineEnd) + 1
	end

	for y = 0, 31 do
		for x = 0, 15 do
			sprites.quads[sprite] =
				love.graphics.newQuad(
					8 * x, 8 * y, 8, 8, 128, 256
				)

			sprite = sprite + 1
		end
	end

	if sprite ~= 512 then
		log.error(string.format("invalid sprite count: %d", sprite))
		return nil
	end

	sprites.sheet = love.graphics.newImage(sprites.data)

	local _, flagsStart = cdata:find("\n__gff__\n")
	local flagsEnd = cdata:find("\n__map__\n")
	local data = cdata:sub(
		flagsStart, flagsEnd
	)

	local sprite = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = data:find("\n", nextLine)

		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = data:sub(nextLine, lineEnd)

		for i = 1, #line, 2 do
			local v = line:sub(i, i + 1)
			v = tonumber(v, 16)
			sprites.flags[sprite] = v
			sprite = sprite + 1
		end

		nextLine = data:find("\n", lineEnd) + 1
	end

	if sprite ~= 512 then
		log.error(string.format("invalid flag count: %d", sprite))
		return nil
	end

	return sprites
end

function carts.loadMap(data, cart)
	local map = {}

	for y = 0, 127 do
		map[y] = {}
		for x = 0, 127 do
			map[y][x] = 0
		end
	end

	local _, mapStart = data:find("\n__map__\n")
	local mapEnd = data:find("\n__sfx__\n")

	if not mapStart then
		log.info("old file")
		return map -- old versions
	end

	if not mapEnd then -- older versions
		mapEnd = data:find("\n__end__\n") or #data - 1
	end

	data = data:sub(mapStart, mapEnd)


	local row = 0
	local col = 0
	local tiles = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = data:find("\n", nextLine)
		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = data:sub(nextLine, lineEnd)

		for i = 1, #line, 2 do
			local v = line:sub(i, i + 1)
			v = tonumber(v, 16)

			map[row][col] = v
			col = col + 1
			tiles = tiles + 1

			if col == 128 then
				col = 0
				row = row + 1
			end
		end
		nextLine = data:find("\n", lineEnd) + 1
	end

	assert(tiles == 128 * 128, string.format("invalid map size: %d", tiles))

	return map
end

function carts.loadSFX(data, cart)
	local sfx = {}

	for i = 0, 63 do
		sfx[i] = {
			speed = 16,
			loopStart = 0,
			loopEnd = 0
		}

		for j = 0, 31 do
			sfx[i][j] = { 0, 0, 0, 0 }
		end
	end

	local sfxStart = data:find("__sfx__")
	local sfxEnd = data:find("__music__")

	if not sfxStart or not sfxEnd then
		log.info("old file")
		return sfx -- old versions
	end

	sfxStart = sfxStart + 8
	sfxEnd = sfxEnd - 1

	local sfxData = data:sub(sfxStart, sfxEnd)
	local _sfx = 0
	local step = 0

	local nextLine = 1

	while nextLine do
		local lineEnd = sfxData:find('\n', nextLine)

		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = sfxData:sub(nextLine, lineEnd)

		sfx[_sfx].speed = tonumber(line:sub(3, 4), 16)
		sfx[_sfx].loopStart = tonumber(line:sub(5, 6), 16)
		sfx[_sfx].loopEnd = tonumber(line:sub(7, 8), 16)

		for i = 9, #line, 5 do
			local v = line:sub(i, i + 4)
			assert(#v == 5)
			local note = tonumber(line:sub(i, i + 1), 16)
			local instr = tonumber(line:sub(i + 2, i + 2), 16)
			local vol = tonumber(line:sub(i + 3, i + 3), 16)
			local fx = tonumber(line:sub(i + 4, i + 4), 16)

			sfx[_sfx][step] = { note, instr, vol, fx }
			step = step + 1
		end

		_sfx = _sfx + 1
		step = 0
		nextLine = sfxData:find('\n', lineEnd) + 1
	end

	assert(_sfx == 64)

	return sfx
end

function carts.loadMusic(data, cart)
	local music = {}

	for i = 0, 63 do
		music[i] = {
			loop = 0,
			[0] = 1,
			[1] = 2,
			[2] = 3,
			[3] = 4
		}
	end

	local musicStart = data:find("__music__")
	local musicEnd = data:find("\n__end__\n") or #data - 1

	if not musicStart or not musicEnd then
		log.info("old file")
		return music -- old versions
	end

	musicStart = musicStart + 10
	musicEnd = musicEnd - 1

	local musicData = data:sub(musicStart, musicEnd)

	local _music = 0
	local nextLine = 1

	while nextLine do
		local lineEnd = musicData:find('\n', nextLine)

		if lineEnd == nil then
			break
		end

		lineEnd = lineEnd - 1
		local line = musicData:sub(nextLine, lineEnd)

		music[_music] = {
			loop = tonumber(line:sub(1, 2), 16),
			[0] = tonumber(line:sub(4, 5), 16),
			[1] = tonumber(line:sub(6, 7), 16),
			[2] = tonumber(line:sub(8, 9), 16),
			[3] = tonumber(line:sub(10, 11), 16)
		}

		_music = _music + 1
		nextLine = musicData:find('\n', lineEnd) + 1
	end

	return music
end

function carts.patchLua(code)

	code = code:gsub("!=","~=")
	code = code:gsub(
		"if%s*(%b())%s*([^\n]*)\n",
		function(a,b)
			local nl = a:find("\n",nil,true)
			local th = b:find(
				"%f[%w]then%f[%W]"
			)
			local an = b:find("%f[%w]and%f[%W]")
			local o = b:find("%f[%w]or%f[%W]")
			local ce = b:find("--", nil, true)
			if not (nl or th or an or o) then
				if ce then
					local c,t = b:match(
						"(.-)(%s-%-%-.*)"
					)
					return string.format(
							"if %s then %s end %s\n",
							a:sub(2, -2),
							c,
							t
						)
				else
					return string.format(
							"if %s then %s end\n",
							a:sub(2, -2),
							b
						)
				end
			end
		end)

	code = code:gsub(
		"(%S+)%s*([%+%-%*/%%])=",
		"%1=%1%2 "
	)

	return code
end

function carts.run(cart, ...)
	if not cart then
		cart = neko.loadedCart
	end

	if not cart or not cart.sandbox then
		return
	end

	editors.close()

	local name = cart.name

	if not cart.pureName or
		cart ~= neko.core and cart.pureName:sub(1, 10) ~= "/programs/" then
		-- carts.save(cart.pureName)
		carts.export()
	end

	log.info(string.format("running cart %s", name))

	local code
	local ok, f, e

	if cart.lang == "lua" then
		code = cart.code

		ok, f, e = pcall(
			load, carts.patchLua(code), name
		)

		g = gamepad:new()
	elseif cart.lang == "asm" then
		local std = {}
		local asm_std = require "asm-lua.include.std"
		-- createSandbox is used because it's guaranteed to have every symbol
		-- in _G, 'cause it IS _G
		for k, _ in pairs(createSandbox()) do
			local _k = "_" .. k
			std[_k] = string.format("local %s=%s", _k, k)
		end
		std.memset = asm_std.memset
		std.memcpy = asm_std.memcpy
		std.memcmp = asm_std.memcmp

		local ports = {}
		local mmap = {
			{min = 0x14001, max = 0x14400, set = "function(_, v) _printh(v) end"},
			{min = 0x14401, max = 0x14800, set = "function(p, v)" ..
													"p=p-0x14401\n" ..
													"local x=p%32\n" ..
													"local y=_flr(p/32)\n" ..
													"_print(v,x*4,y*6)" ..
												 "end"},
			{min = 0x16001, max = 0x1c000, set = "function(p, v)\n" ..
													"p=p-0x16001\n" ..
													"local x=p%192\n" ..
													"local y=_flr(p/192)\n" ..
													"pset(x,y+1,v)" ..
												 "end"},
		}

		code = try(function()
				return asm.compile(cart.code, DEBUG or false, std, ports, mmap)
			end,
			runtimeError,
			function(result)
				return result
		end)

		if not code then
			return false
		end

		api.print(string.format("successfully compiled %s", cart.pureName or "cart"))

		ok, f, e = pcall(
			load, carts.patchLua(code), name
		)
	elseif cart.lang == "basic" then
		--require "TBASEXEC"
		ok = true
		f = function()
			_TBASIC.EXEC(cart.code)
		end
	elseif cart.lang == "moonscript" then
		parse = require "libs.moonscript.moonscript.parse"
		compile = require "libs.moonscript.moonscript.compile"

		tree, e = parse.string(cart.code)

		if tree then
			luaCode, e, pos = compile.tree(tree)
			if luaCode then
				ok, f, e = pcall(
					load, luaCode, name
				)
			end
		end
	else
		runtimeError("unrecognized language tag")
	end

	if not ok or f == nil then
		syntaxError(e)
		return
	end

	love.graphics.setCanvas(
		canvas.renderable
	)

	love.graphics.setShader(
		colors.drawShader
	)

	setClip()
	setCamera()

	cart.sandbox.args = unpack({ ... })

	local result
	setfenv(f, cart.sandbox)
	ok, result = pcall(f)

	if not ok then
		runtimeError(result)
		return
	end

	try(function()
		if cart.sandbox._draw or
			cart.sandbox._update then
			neko.cart = cart
		end

		if cart.sandbox._init then
			cart.sandbox._init()
		end
	end, runtimeError)

	api.flip()

	return (cart.sandbox._draw or
		cart.sandbox._update) and true or false
end

function carts.save(name)
	if not name and neko.loadedCart == nil then
		log.info("name missing")
		return false
	end

	name = name or neko.loadedCart.name
	name = resolveFile(name, neko.currentDirectory)
	log.info(string.format("saving %s", name))

	carts.export()

	if #neko.loadedCart.code > 65536 then
		-- :P
		return false, "char count is bigger then 65536"
	end

	local data = {}

	table.insert(data, "neko8 cart\n")

	table.insert(data, string.format("__%s__\n", neko.loadedCart.lang))
	table.insert(data, neko.loadedCart.code)
	table.insert(data, "__gfx__\n")
	table.insert(data, editors.sprites.exportGFX())
	table.insert(data, "__gff__\n")
	table.insert(data, editors.sprites.exportGFF())
	table.insert(data, "__map__\n")
	table.insert(data, editors.map.export())
	table.insert(data, "__sfx__\n")
	table.insert(data, editors.sfx.export())
	table.insert(data, "__music__\n")
	table.insert(data, editors.music.export())
	table.insert(data, "__end__")

	love.filesystem.write(
		string.format("%s.n8", name),
		table.concat(data)
	)

	neko.loadedCart.pureName = name

	return true
end

return carts