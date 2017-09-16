local UiManager = require "ui.manager"
local UiLabelButton = require "ui.label_button"
local UiComponent = require "ui.component"

local sfx = {}
local keyToNoteMap = {
	[ "z" ] = "c ",
	[ "x" ] = "d ",
	[ "c" ] = "e ",
	[ "v" ] = "f ",
	[ "b" ] = "g ",
	[ "n" ] = "a ",
	[ "m" ] = "b ",

	[ "s" ] = "c#",
	[ "d" ] = "d#",
	[ "g" ] = "f#",
	[ "h" ] = "g#",
	[ "j" ] = "a#"
}

function sfx.init()
	sfx.forceDraw = false
	sfx.icon = 11
	sfx.name = "sfx editor"
	sfx.bg = config.editors.sfx.bg
	sfx.sfx = 0
	sfx.volume = 5
	sfx.instrument = 0
	sfx.fx = 0
	sfx.octave = 2

	sfx.cursor = {
		x = 0,
		y = 0
	}

	sfx.ui = UiManager()
	sfx.ui:add(
		UiLabelButton(
			string.format("%02d", sfx.sfx), 17,
			8, 9, 7, config.editors.sfx.fg
		):onClick(function(self, b, rb)
			local v = rb and -1 or 1

			if api.key("lshift") or api.key("rshift") then
				v = v * 4
			end

			sfx.sfx = api.mid(0, 63, sfx.sfx + v)
			b.label = string.format("%02d", sfx.sfx)
			sfx.forceDraw = true

			-- todo: update other ui
		end), "sfx"
	)

	sfx.ui:add(
		UiLabelButton(
			"16", 42,
			8, 9, 7, config.editors.sfx.fg
		):onClick(function(b, rb)
			local v = rb and -1 or 1

			if api.key("lshift") or api.key("rshift") then
				v = v * 4
			end

			neko.loadedCart.sfx[sfx.sfx].speed = api.mid(1, 63, neko.loadedCart.sfx[sfx.sfx].speed + v)
			b.label = string.format("%02d", neko.loadedCart.sfx[sfx.sfx].speed)
			sfx.forceDraw = true
		end), "speed"
	)

	-- piano

	for i = 0, 11 do
		local x, y = i * 14 + 1, 58


		sfx.ui:add(
			UiComponent(
				x, 66, 13, h
			):onRender(function(self)
				api.brectfill(self.x, self.y, self.w, self.h, 7)
			end):onClick(function(self)
				sfx.typeNote(i + sfx.octave * 12)
			end), "white_button_" .. i
		)
	end
end

function sfx.open()
	sfx.forceDraw = true
end

function sfx.close()

end

local lof = -1

function sfx._draw()
	local of = audio.sfx[1].sfx == nil
		and -1 or api.flr(audio.sfx[1].offset)

	if sfx.forceDraw or of ~= lof then
		sfx.redraw()
		sfx.forceDraw = false
	end

	lof = of
	sfx.ui:draw()
	editors.drawUI()
end

function sfx.redraw()
	api.cls(sfx.bg)

	for i = 0, 3 do
		api.brectfill(1 + i * 26, 16, 25, 49, 0)
	end

	local c = config.editors.sfx.fg
	api.print("SFX", 1, 9, c)
	api.print("SPD", 27, 9, c)

	for i = 0, 31 do
		local s = sfx.data[sfx.sfx][i]
		local x = 2 + api.flr(i / 8) * 26
		local y = 17 + i % 8 * 6
		local isEmpty = s[3] == 0

		if audio.sfx[1].sfx ~= nil then
			if api.flr(audio.sfx[1].offset) == i then
				api.brectfill(
					x - 1, y - 1, 25, 7, 9
				)
			end
		end

		if sfx.cursor.y == i then
			api.brectfill(
				x - 1 + sfx.cursor.x * 4 + (sfx.cursor.x > 0 and 4 or 0),
				y - 1, sfx.cursor.x > 0 and 5 or 9, 7, 8
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

function sfx._keydown(k)
	if api.key("rctrl") or api.key("lctrl") then
		if k == "s" then
			commads.save()
		end
	else
		if k == "up" then
			sfx.cursor.y = sfx.cursor.y - 1
			if sfx.cursor.y < 0 then
				sfx.cursor.y = 31
			end
			sfx.forceDraw = true
		elseif k == "down" then
			sfx.cursor.y = sfx.cursor.y + 1
			if sfx.cursor.y > 31 then
				sfx.cursor.y = 0
			end
			sfx.forceDraw = true
		elseif k == "left" then
			sfx.cursor.x = sfx.cursor.x - 1
			if sfx.cursor.x < 0 then
				sfx.cursor.x = 4
				sfx.cursor.y = sfx.cursor.y - 8
				if sfx.cursor.y < 0 then
					sfx.cursor.y = sfx.cursor.y + 32
				end
			end
			sfx.forceDraw = true
		elseif k == "right" then
			sfx.cursor.x = sfx.cursor.x + 1
			if sfx.cursor.x > 4 then
				sfx.cursor.x = 0
				sfx.cursor.y = sfx.cursor.y + 8
				if sfx.cursor.y > 31 then
					sfx.cursor.y = sfx.cursor.y - 32
				end
			end
			sfx.forceDraw = true
		elseif k == "space" then
			api.sfx(sfx.sfx, 1)
		elseif sfx.cursor.x == 0 and (string.match("zxcvbnnmsdghj", k)) then
			sfx.typeNote(keyToNoteMap[k])
			sfx._keydown("down")
		elseif (string.match("01234567", k)) then
			local num = tonumber(k)

			if sfx.cursor.x == 1 then
				if num < 5 then
					local n = sfx.data[sfx.sfx][sfx.cursor.y][1]
					sfx.data[sfx.sfx][sfx.cursor.y][1] = n % 12 + num * 12
				end

				sfx._keydown("down")
			elseif sfx.cursor.x > 0 then
				sfx.data[sfx.sfx][sfx.cursor.y][sfx.cursor.x] = num
				sfx._keydown("down")
			end

			sfx.forceDraw = true
		end
	end
end

function sfx.typeNote(n)
	if type(n) == "string" then
		n = stringToNote(n, sfx.octave)
	end

	sfx.data[sfx.sfx][sfx.cursor.y][1] = n

	if sfx.data[sfx.sfx][sfx.cursor.y][3] == 0 then
		sfx.data[sfx.sfx][sfx.cursor.y][2] = sfx.instrument
		sfx.data[sfx.sfx][sfx.cursor.y][3] = sfx.volume
		sfx.data[sfx.sfx][sfx.cursor.y][4] = sfx.fx
	end

	sfx.forceDraw = true
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

-- vim: noet
