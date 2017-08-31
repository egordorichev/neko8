local music = {}

function music.init()
	music.forceDraw = false
	music.icon = 12
end

function music.open()
	music.forceDraw = true
end

function music.close()

end

function music._draw()
	if music.forceDraw then
		music.redraw()
		music.forceDraw = false
	end
end

function music.redraw()
	api.cls(0)
	editors.drawUI()
end

function music._update()

end

function music.import(data)
	music.data = data
end

function music.export()
	return music.data
end

return music