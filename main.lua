-----------------------------------------
-- main callbacks
-----------------------------------------

local requirePath = love.filesystem.getRequirePath()
love.filesystem.setRequirePath(requirePath ..
                               ';src/?.lua;src/?/init.lua' ..
                               ';libs/?.lua;libs/?/init.lua')

OS = love.system.getOS()
mobile = OS == "Android" or OS == "iOS"

require "minify"
require "log"

-- DEBUG!
-- mobile = true

if mobile then
	keyboard = require "keyboard"
	keyboard.init()
end

giflib = require "gif"
QueueableSource = require "QueueableSource"
frameTime = 1 / config.fps
hostTime = 0

asm = require "asm-lua"

neko = require "neko8"
api = require "api"
carts = require "carts"
commands = require "commands"

function love.load(arg)
	if arg then
		DEBUG = arg[2] == "-d"

		if DEBUG then
			lurker = require "lurker"

			lurker.postswap = function(f)
				editors.current.forceDraw = true
				resizeCanvas(
					love.graphics.getWidth(),
					love.graphics.getHeight()
				)
			end
		end
	end

	log.info(
		"neko 8 " .. config.version.string
	)

	love.window.setDisplaySleepEnabled(false)
	neko.init()
end

function love.touchpressed()
	if editors.current == editors.modes[1] then
		love.keyboard.setTextInput(true)
	end
end

-- XXX Why is this in the global scope? Why isn't this part of some table?
mbt = 0

function love.update(dt)
	if not neko.focus then
		return
	end

	if DEBUG then
		lurker.update()
	end

	neko.update()

	if mobile then
		keyboard.update()
	end

	if love.mouse.isDown(1) then
		mbt = mbt + 1
	else
		mbt = 0
	end
end

function love.draw()
	love.graphics.setCanvas(
		canvas.renderable
	)

	love.graphics.setShader(
		colors.drawShader
	)

	setClip()
	setCamera()

	neko.draw()
	api.flip()

	if mobile then
		keyboard.update()
	end
end

function love.wheelmoved(x, y)
	triggerCallback("_wheel", y)
end

function love.resize(w, h)
	resizeCanvas(w,h)
end

function love.keypressed(
	key, scancode, isRepeat
)
	for p = 0, 1 do
		for i = 0, #api.keyMap[p] do
			for _, k
				in pairs(api.keyMap[p][i]) do
				if key == k then
					api.keyPressed[p][i] = -1
					break
				end
			end
		end
	end

	local handled = true

	if love.keyboard.isDown("rctrl") or
		love.keyboard.isDown("lctrl") then
		if key == "r" then
			if neko.loadedCart then
				carts.run(neko.loadedCart)
			end
		elseif key == "v" then
			love.textinput(
				love.system.getClipboardText()
			)
		elseif key == "c" then
			local text = triggerCallback("_copy")
			if text then
				love.system.setClipboardText(text)
			end
		elseif key == "x" then
			local text = triggerCallback("_cut")
			if text then
				love.system.setClipboardText(text)
			end
		else
			handled = false
		end
	elseif love.keyboard.isDown("lalt")
		or love.keyboard.isDown("ralt") then
		if (key == "return" or key == "kpenter")
			and not isRepeat then

			neko.fullscreen = not neko.fullscreen
			love.window.setFullscreen(neko.fullscreen)
		end
	else
		local shiftDown = love.keyboard.isDown("lshift")
					or love.keyboard.isDown("rshift")
		if (key == "escape" or (key == "return" and shiftDown))
			and not isRepeat then
			handled = false
			if neko.cart then
				neko.cart = nil
				api.camera(0, 0)
				api.clip()
			elseif editors.opened then
				editors.close()
			else
				editors.open()
			end
		elseif key == "f1" then
			local s =
				love.graphics.newScreenshot(false)
			local file = "neko8-"
				.. os.time() .. ".png"

			s:encode("png", file)
			api.smes("saved screenshot")
		elseif key == "f8" then
			-- gif = giflib.new("neko8.gif")
			-- api.smes("started recording gif")
			api.smes("gif recording is not supported")
		elseif key == "f9" then
			if not gif then return end
			gif:close()
			gif = nil
			api.smes("saved gif")
			love.filesystem.write(
				"neko8-" .. os.time() .. ".gif",
				love.filesystem.read("neko8.gif")
			)
			love.filesystem.remove("neko8.gif")
		else
			handled = false
		end
	end

	if not handled then
		triggerCallback(
			"_keydown", key, isRepeat
		)
	end
end

function love.keyreleased(key)
	for p = 0, 1 do
		for i = 0, #api.keyMap[p] do
			for _, k
				in pairs(api.keyMap[p][i]) do
				if key == k then
					api.keyPressed[p][i] = nil
					break
				end
			end
		end
	end

	triggerCallback("_keyup", key)
end

function try(f, catch, finally)
	local status, result = pcall(f)
	if not status then
		catch(result)
	elseif finally then
		return finally(result)
	end
end

function runtimeError(error)
	api.clip()
	api.camera(0, 0)

	log.error("runtime error:")
	log.error(error)
	editors.close()

	neko.cart = nil

	local pos = error:find("\"]:")
	if pos then
		error = "line " .. error:sub(pos + 3)
	end
	neko.core.sandbox.redraw_prompt(true)
	api.print("")
	api.color(8)
	api.print(error)
	neko.core.sandbox.redraw_prompt()
end

function syntaxError(error)
	api.camera(0, 0)
	api.clip()

	log.error("syntax error:")
	log.error(e)
	editors.close()

	neko.cart = nil
	local pos = error:find("\"]:")
	if pos then
		error = "line " .. error:sub(pos + 3)
	end
	neko.core.sandbox.redraw_prompt(true)
	api.print("")
	api.color(8)
	api.print(error)
	neko.core.sandbox.redraw_prompt()
end

function replaceChar(pos, str, r)
	return str:sub(1, pos - 1)
		.. r .. str:sub(pos + 1)
end

local function toUTF8(st)
	if st <= 0x7F then
		return string.char(st)
	end

	if st <= 0x7FF then
		local byte0 = 0xC0 + math.floor(st / 0x40)
		local byte1 = 0x80 + (st % 0x40)
		return string.char(byte0, byte1)
	end

	if st <= 0xFFFF then
		local byte0 = 0xE0 +  math.floor(st / 0x1000)
		local byte1 = 0x80 + (math.floor(st / 0x40) % 0x40)
		local byte2 = 0x80 + (st % 0x40)
		return string.char(byte0, byte1, byte2)
	end

	return ""
end

function validateText(text)
	for i = 1, #text do
		local c = text:sub(i, i)
		local valid = false
		for j = 1, #config.font.letters do
			local ch = config.font.letters:sub(j, j)
			if c == ch then
				valid = true
				break
			end
		end
		if not valid then
			text = replaceChar(i, text, "")
		end
	end

	if #text == 1 and api.key("ralt")
		or api.key("lalt") then
		local c = string.byte(text:sub(1, 1))

		if c >= 97
			and c <= 122 then
			text = replaceChar(
				1, text, toUTF8(c + 95)
			)
		end
	end

	return text
end

function love.textinput(text)
	text = validateText(text)
	triggerCallback("_text", text)
end

function love.focus(focus)
	neko.focus = focus
end

function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
		for i = 1, 3 do love.math.random() end
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end
	if love.timer then love.timer.step() end

	local dt = 0
	while true do
		if love.event then
			love.event.pump()
			for e, a, b, c, d in
				love.event.poll() do
				if e == "quit" then
					if not love.quit
						or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				love.handlers[e](a,b,c,d)
			end
		end
		if love.timer then
			love.timer.step()
			dt = dt + love.timer.getDelta()
		end
		local render = false
		while dt >= frameTime do
			hostTime = hostTime + dt
			if hostTime >= 65536 then
				hostTime = hostTime - 65536
			end
			if love.update then
				love.update(frameTime)
			end
			dt = dt - frameTime
			render = true
		end
		if render and love.window
			and love.graphics
			and love.window.isCreated() then

			love.graphics.origin()
			if love.draw then love.draw() end
		end
		if love.timer then
			love.timer.sleep(0.001)
		end
	end
end

function triggerCallback(c, ...)
	if neko.cart then
		if neko.cart.sandbox[c] then
			local v = nil
			local args = {...}

			try(function()
				v = neko.cart.sandbox[c](unpack(args))
			end, runtimeError)

			return v
		end
	elseif editors.opened then
		if editors.current[c] then
			return editors.current[c](...)
		end
	elseif neko.core.sandbox[c] then
		return neko.core.sandbox[c](...)
	end

	return nil
end

-----------------------------------------
-- canvas helpers
-----------------------------------------

canvas = {
	x = 0,
	y = 0,
	scaleX = 1,
	scaleY = 1
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

	canvas.message =
		love.graphics.newCanvas(
			config.canvas.width,
			7
		)

	canvas.message:setFilter(
		"nearest", "nearest"
	)

	resizeCanvas(
		love.graphics.getWidth(),
		love.graphics.getHeight()
	)
end

function resizeCanvas(width, height)
	local size = math.min(
			width / config.canvas.width,
			height / config.canvas.height
	)

	if not mobile then
		size = math.floor(size)
	end

	canvas.scaleX = size
	canvas.scaleY = size

	canvas.x =
		(width - size * config.canvas.width) / 2

	if mobile then
		canvas.y = 0
	else
		canvas.y =
			(height - size * config.canvas.height)
			/ 2
	end
end

-----------------------------------------
-- font
-----------------------------------------

function initFont()
	love.graphics.setDefaultFilter("nearest")
	font = love.graphics.newFont(
		config.font.file, 4
	)

	font:setFilter("nearest", "nearest")

	love.graphics.setFont(font)
end

-----------------------------------------
-- shaders
-----------------------------------------

colors = {}
colors.current = 7

function shaderUnpack(t)
	return unpack(t, 1, 17)
	-- change to 16 once love2d
	-- shader bug is fixed
end

function initPalette()
	colors.palette = {
		{0, 0, 0, 255},
		{29, 43, 83, 255},
		{126, 37, 83, 255},
		{0, 135, 81, 255},
		{171, 82, 54, 255},
		{95, 87, 79, 255},
		{194, 195, 199, 255},
		{255, 241, 232, 255},
		{255, 0, 77, 255},
		{255, 163, 0, 255},
		{255, 240, 36, 255},
		{0, 231, 86, 255},
		{41, 173, 255, 255},
		{131, 118, 156, 255},
		{255, 119, 168, 255},
		{255, 204, 170, 255}
	}

	colors.display = {}
	colors.draw = {}
	colors.transparent = {}

	for i = 1, 16 do
		colors.draw[i] = i
		colors.transparent[i] =
			i == 1 and 0 or 1
		colors.display[i] = colors.palette[i]
	end

	colors.drawShader =
		love.graphics.newShader([[
extern float palette[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords,
			vec2 screen_coords) {
	int index = int(color.r*16.0);
	return vec4(vec3(palette[index]/16.0),1.0);
}]])

	colors.drawShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.spriteShader =
		love.graphics.newShader([[
extern float palette[16];
extern float transparent[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords, vec2 screen_coords) {
	int index = int(floor(Texel(texture, texture_coords).r*16.0));
	float alpha = transparent[index];
	return vec4(vec3(palette[index]/16.0),alpha);
}]])

	colors.spriteShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.spriteShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)

	colors.textShader =
		love.graphics.newShader([[
extern float palette[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords, vec2 screen_coords) {
	vec4 texcolor = Texel(texture, texture_coords);
	if(texcolor.a == 0.0) {
		return vec4(0.0,0.0,0.0,0.0);
	}
	int index = int(color.r*16.0);
	return vec4(vec3(palette[index]/16.0),1.0);
}]])

	colors.textShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.displayShader =
		love.graphics.newShader([[
extern vec4 palette[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords, vec2 screen_coords) {
	int index = int(Texel(texture, texture_coords).r*15.0);
	return palette[index]/256.0;
}]])

	colors.displayShader:send(
		"palette",
		shaderUnpack(colors.display)
	)

	colors.onCanvasShader =
		love.graphics.newShader([[
extern vec4 palette[16];
extern float transparent[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords, vec2 screen_coords) {
	int index = int(floor(Texel(texture, texture_coords).r*16.0));
	float alpha = transparent[index];
	vec3 clr = vec3(palette[index]/16.0);
  return vec4(clr/16.0,alpha);
}]])

	colors.onCanvasShader:send(
		"palette",
		shaderUnpack(colors.display)
	)

	colors.onCanvasShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)
end
