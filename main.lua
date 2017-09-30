-----------------------------------------
-- main callbacks
-----------------------------------------
local requirePath = love.filesystem.getRequirePath()
love.filesystem.setRequirePath(requirePath ..
	';src/?.lua;src/?/init.lua' ..
	';libs/?.lua;libs/?/init.lua'
)

OS = love.system.getOS()
mobile = OS == "Android" or OS == "iOS"

require "minify"
require "log"
require "error"

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

audio = require "audio"
carts = require "carts"
commands = require "commands"
api = require "api"
neko = require "neko8"

function love.load(arg)
	love.filesystem.unmount(love.filesystem.getSource())

	if arg then
		DEBUG = arg[2] == "-d"

		if DEBUG then
			lurker = require "lurker"
			lurker.protected = false
			lurker.quiet = true

			lurker.postswap = function(f)
				editors.current.init()
				carts.import(neko.loadedCart)
				resizeCanvas(
					love.graphics.getWidth(),
					love.graphics.getHeight()
				)
			end
		end
	end

	local joysticks = love.joystick.getJoysticks()

	if joysticks[0] then
		neko.joystick = joysticks[0]
	end

	log.info("neko 8 " .. config.version.string)

	love.window.setTitle("neko 8 " .. config.version.string)
	love.window.setDisplaySleepEnabled(false)
	neko.init()
end

function love.joystickadded(joystick)
	if not neko.joystick then
		neko.joystick = joystick
	end
end

function love.joystickremoved(joystick)
	if neko.joystick == joystick then
		neko.joystick = nil
	end
end

function love.touchpressed()
	-- open virtual keyboard when in code/sfx editor or command line on mobile
	if (editors.current == editors.modes[1] or editors.modes[4]) or editors.opened == false then
		love.keyboard.setTextInput(true)
	end
end

-- XXX Why is this in the global scope? Why isn't this part of some table?
mbt = 0

ss={up=true,x=0,c=0,isRunning=false}

function love.update(dt)
	if not neko.focus then -- screensaver
		return
	end

	neko.cursor.current = neko.cursor.default

	if DEBUG then
		lurker.update()
	end

	neko.update(dt)

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
	--if not neko.focus then
	--	api.flip()
	--	return
	--end

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

function love.joystickpressed(joystick, button)
	if button == 4 then
		love.keypressed("up", -1, false)
	elseif button == 2 then
		love.keypressed("down", -1, false)
	elseif button == 3 then
		love.keypressed("right", -1, false)
	elseif button == 1 then
		love.keypressed("left", -1, false)
	end
end

function love.joystickreleased(joystick, button)
	if button == 4 then
		love.keyreleased("up")
	elseif button == 2 then
		love.keyreleased("down")
	elseif button == 3 then
		love.keyreleased("right")
	elseif button == 1 then
		love.keyreleased("left")
	end
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
		elseif neko.cart == nil and editors.opened then
			if key == "f1" then
				editors.openEditor(1)
			elseif key == "f2" then
				editors.openEditor(2)
			elseif key == "f3" then
				editors.openEditor(3)
			elseif key == "f4" then
				editors.openEditor(4)
			elseif key == "f5" then
				editors.openEditor(5)
			elseif key == "f6" then
				editors.openEditor(6)
			else
				handled = false
			end
		end

		if key == "f7" then
			local s = love.graphics.newScreenshot(false)
			local file = string.format("neko8-%s.png", os.time())

			s:encode("png", file)
			api.smes("saved screenshot")
		elseif key == "f8" then
			gif = giflib.new(string.format("neko8-%s.gif", os.time()), config.palette)
			api.smes("started recording gif")
		elseif key == "f9" then
			if not gif then return end
			gif:close()
			gif = nil
			api.smes("saved gif")
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

	if error then
		local pos = string.find(error, "\"]:")
		if pos then
			error = string.format("line %s", error:sub(pos + 3))
		end

		neko.core.sandbox.redraw_prompt(true)
		api.print("")
		api.color(8)
		api.print(error)
	end
	api.print(debug.traceback("", 4):gsub("^%s*", ""), nil, nil, nil, true)
	neko.core.sandbox.redraw_prompt()
end

function syntaxError(error)
	api.camera(0, 0)
	api.clip()

	log.error("syntax error:")
	log.error(error)
	editors.close()

	neko.cart = nil
	if error then
		local pos = string.find(error, "\"]:")
		if pos then
			error = string.format("line %s", error:sub(pos + 3))
		end
		neko.core.sandbox.redraw_prompt(true)
		api.print("")
		api.color(8)
		api.print(error)
		neko.core.sandbox.redraw_prompt()
	end
end

function replaceChar(pos, str, r)
	return string.sub(str, 1, pos - 1) .. r .. string.sub(str, pos + 1)
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
		local c = string.sub(text, i, i)
		local valid = c == " " or c == "\n" or c == "\r" or c == "\t"

		if not valid then
			for j = 1, #config.font.letters do
				local ch = string.sub(config.font.letters, j, j)
				if c == ch then
					valid = true
					break
				end
			end
		end
		if not valid then
			text = ""
		end
	end

	--[[if #text == 1 and api.key("ralt")
		or api.key("lalt") then
		local c = string.byte(string.sub(text, 1, 1))

		if c and c >= 97
			and c <= 122 then
			text = replaceChar(
				1, text, toUTF8(c + 95)
			)
		end
	end--]]

	-- todo

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
				audio.update(frameTime)
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

	canvas.support =
		love.graphics.newCanvas(
			config.canvas.width,
			config.canvas.height
		)

	canvas.support:setFilter(
		"nearest", "nearest"
	)

	canvas.gif =
		love.graphics.newCanvas(
			config.canvas.width * config.canvas.gifScale,
			config.canvas.height * config.canvas.gifScale
		)

	canvas.gif:setFilter(
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

	canvas.x = (width - size * config.canvas.width) / 2

	if mobile then
		canvas.y = 0
	else
		canvas.y = (height - size * config.canvas.height) / 2
	end
end

-----------------------------------------
-- font
-----------------------------------------

function initFont()
	love.graphics.setDefaultFilter("nearest", "nearest")
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
	colors.palette = config.palette
	colors.display = {}
	colors.draw = {}
	colors.transparent = {}

	for i = 1, 16 do
		colors.draw[i] = i
		colors.transparent[i] = i == 1 and 0 or 1
		colors.display[i] = colors.palette[i]
	end

	colors.drawShader =
		love.graphics.newShader("assets/draw.frag")

	colors.drawShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.spriteShader =
		love.graphics.newShader("assets/sprite.frag")

	colors.spriteShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.spriteShader:send(
		"transparent",
		shaderUnpack(colors.transparent)
	)

	colors.textShader = love.graphics.newShader("assets/text.frag")

	colors.textShader:send(
		"palette",
		shaderUnpack(colors.draw)
	)

	colors.displayShader =
		love.graphics.newShader("assets/display.frag")

	colors.displayShader:send(
		"palette",
		shaderUnpack(colors.display)
	)

	colors.supportShader = love.graphics.newShader("assets/support.frag")
end