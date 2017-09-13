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
		pointer = 5,
		hand = 21,
		holding_hand = 22 -- todo: draw it
	}

	neko.cursor.current = neko.cursor.pointer

	audio.init()

	initCanvas()
	initFont()
	initPalette()
	initApi()

	editors = require "editors"
	editors.init()

	neko.core = carts.load("neko")
	carts.run(neko.core)
	neko.cart = nil
	neko.loadedCart = carts.create()
	carts.import(neko.loadedCart)
end

function neko.showMessage(s)
	neko.message = {
		text = s or "invalid message",
		t = config.fps * 2
	}
end

function neko.update()
	audio.update()

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

	triggerCallback("_update")
end

function neko.draw()
	triggerCallback("_draw")
end

return neko
