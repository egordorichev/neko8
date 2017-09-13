local sfx = {}

function sfx.init()
	sfx.forceDraw = false
	sfx.icon = 11
	sfx.name = "sfx editor"
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

	editors.drawUI()
end

function sfx.redraw()
	api.cls(sfx.bg)
	api.print("work in progress", 1, 8, 7)
end

function sfx._update()

end

function sfx.import(data)
	sfx.data = data
end

function sfx.export()
	local data = ""

	for i = 0, 63 do
		data = data .. "00" .. string.format(
			"%02x", sfx.data[i].speed)

		data = data .. string.format(
			"%02x", sfx.data[i].loopStart)

		data = data .. string.format(
			"%02x", sfx.data[i].loopEnd)

		for j = 0, 31 do
			data = data .. string.format(
				"%02x", sfx.data[i][j][1])

			data = data .. string.format(
				"%01x", sfx.data[i][j][2])

			data = data .. string.format(
				"%01x", sfx.data[i][j][3])

			data = data .. string.format(
				"%01x", sfx.data[i][j][4])
		end

		data = data .. "\n"
	end

	return data
end

return sfx