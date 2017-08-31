local map = {}

function map.init()
	map.forceDraw = false
	map.icon = 10
end

function map.open()
	map.forceDraw = true
end

function map.close()

end

function map._draw()
	if map.forceDraw then
		map.redraw()
		map.forceDraw = false
	end
end

function map.redraw()
	api.cls(0)
	editors.drawUI()
end

function map._update()

end

function map.import(data)
	map.data = data
end

function map.export()
	return map.data
end

return map