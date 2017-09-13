local music = {}

function music.init()
	music.forceDraw = false
	music.icon = 12
	music.name = "music editor"
	music.bg = config.editors.music.bg
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

	editors.drawUI()
end

function music.redraw()
	api.cls(music.bg)
	api.print("work in progress", 1, 8, 7)
end

function music._update()

end

function music.import(data)
	music.data = data
end

function music.export()
	local data = ""

	for i = 0, 63 do
		data = data .. "00 " ..  string.format(
			"%02x", music.data[i][0])

		data = data ..  string.format(
			"%02x", music.data[i][1])

		data = data ..  string.format(
			"%02x", music.data[i][2])

		data = data ..  string.format(
			"%02x", music.data[i][3])

		data = data .. "\n"
	end

	return data
end

return music