-----------------------------------------
-- neko8
-----------------------------------------

local neko = {}

function neko.init()
	neko.core = nil
	neko.fullscreen = false
	neko.focus = true
	neko.currentDirectory = "/"

	neko.cursor = {
		default = 5,
		pointer = 21,
		pointer_down = 37,
		hand = 38 -- todo: draw it
	}

	neko.cursor.current = neko.cursor.default

	audio.init()

	initCanvas()
	initFont()
	initPalette()
	initApi()

	if not isVisible("neko.n8", "/") then
		log.info("installing core")

		love.filesystem.write(
			"neko.n8",
			love.filesystem.read("neko.n8")
		)
	end

	gamepad = require "gamepad"

	editors = require "editors"
	editors.init()

	neko.core = carts.load("neko")
	carts.run(neko.core)
	neko.cart = nil
	neko.loadedCart = carts.create()
	-- todo: sfx doesn't play, if we create new cart
	carts.import(neko.loadedCart)
end

function neko.showMessage(s)
	neko.message = {
		text = s or "invalid message",
		t = config.fps * 2
	}
end

function neko.update(dt)
	for p = 0, 1 do
		for i = 0, #api.keyMap[p] do
			for _, key in pairs(
				api.keyMap[p][i]
			) do
				local v = api.keyPressed[p][i]
				if v then
					v = v + 1
					api.keyPressed[p][i] = v
					break
				end
			end
		end
	end

	if neko.message then
		neko.message.t = neko.message.t - 1
		if neko.message.t <= 0 then
			neko.message = nil
		end
	end

	if g and neko.cart ~= nil and neko.cart ~= neko.core then
		if g.b[1].ispressed then
			api.exit()
		end
		g:update()  --gamepad
	end

	triggerCallback("_update")
end

function neko.draw()
	triggerCallback("_draw")
	if mobile and g and neko.cart ~= nil and neko.cart ~= neko.core then
			coresprites=true g:draw() coresprites=false --gamepad
	end
end

return neko


