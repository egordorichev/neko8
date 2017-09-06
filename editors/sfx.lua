local sfx = {}

function sfx.init()
	sfx.forceDraw = false
	sfx.icon = 11
	sfx.bg = config.editors.sfx.bg
end

function sfx.open()
	sfx.forceDraw = true
end

function sfx.close()

end

function sfx._draw()
	if sfx.forceDraw then
		sfx.redraw()
		sfx.forceDraw = false
	end
end

function sfx.redraw()
	api.cls(sfx.bg)
	api.print("work in progress", 1, 8, 7)
	editors.drawUI()
end

function sfx._update()

end

function sfx.import(data)
	sfx.data = data
end

function sfx.export()
	return sfx.data
end

return sfx