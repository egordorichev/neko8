local sfx = {}

function sfx.init()
	sfx.forceDraw = false
	sfx.icon = 11
	sfx.name = "sfx editor"
	sfx.bg = config.editors.sfx.bg
	sfx.sfx = 0

	sfx.cursor = {
		x = 0,
		y = 0
	}
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

	for i = 0, 3 do
		api.brectfill(1 + i * 26, 8, 25, 49, 0)
	end

	for i = 0, 31 do
		local s = sfx.data[sfx.sfx][i]
		local x = 2 + api.flr(i / 8) * 26
		local y = 9 + i % 8 * 6
		local isEmpty = s[3] == 0

		if sfx.cursor.y == i then
			api.brectfill(
				x - 1 + sfx.cursor.x * 4, y - 1,
				5, 7, 8
			)
		end

		if isEmpty then
			api.print(
				"......", x, y, 2
			)
		else
			api.print(
				noteToString(s[1]), x, y, 7
			)

			api.print(
				noteToOctave(s[1]), x + 8, y, 6
			)

			api.print(
				s[2], x + 12, y, 11
			)

			api.print(
				s[3], x + 16, y, 12
			)

			api.print(
				s[4], x + 20, y, 13
			)
		end
	end
end

function sfx._update()

end

function sfx.import(data)
	sfx.data = data
end

function sfx.export()
	local data = {}

	for i = 0, 63 do
		table.insert(data, "00")

		table.insert(
			data, string.format(
				"%02x", sfx.data[i].speed
			)
		)

		table.insert(
			data, string.format(
				"%02x", sfx.data[i].loopStart
			)
		)

		table.insert(
			data, string.format(
				"%02x", sfx.data[i].loopEnd
			)
		)

		for j = 0, 31 do
			table.insert(
				data, string.format(
					"%02x", sfx.data[i][j][1]
				)
			)

			table.insert(
				data, string.format(
					"%01x", sfx.data[i][j][2]
				)
			)

			table.insert(
				data, string.format(
					"%01x", sfx.data[i][j][3]
				)
			)

			table.insert(
				data, string.format(
					"%01x", sfx.data[i][j][4]
				)
			)
		end

		table.insert(data, "\n")
	end

	return table.concat(data)
end

return sfx