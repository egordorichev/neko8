local sprites = {}
local editors = require "editors"

function sprites.init()

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
	-- nav buttons!
end

function sprites.redraw()
	api.cls(config.editors.sprites.bg)
	editors.drawUI()
end

function sprites.import(data)
	sprites.data = data
end

function sprites.export()
	return sprites.data
end

return sprites