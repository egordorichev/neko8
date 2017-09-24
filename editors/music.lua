local UiManager = require "ui.manager"
local UiLabelButton = require "ui.label_button"
local UiCounter = require "ui.counter"
local UiButton = require "ui.button"
local UiComponent = require "ui.component"
local UiCheckbox = require "ui.checkbox"

local sfx = require "editors.sfx"

local music = {}

function music.init()
	music.forceDraw = true
	music.icon = 12
	music.name = "piano cat"
	music.bg = config.editors.music.bg
	music.track = 0
	music.ui = UiManager()

	music.ui:add(
		UiCounter(
			music.track, 127, 8, 9, 7,
			function(self)
				local v = -1

				if api.key("lshift") or api.key("rshift") then
					v = v * 4
				end

				music.track = api.mid(0, 63, music.track + v)
				self.v = music.track
				music.forceDraw = true
			end,
			function(self)
				local v = 1

				if api.key("lshift") or api.key("rshift") then
					v = v * 4
				end

				music.track = api.mid(0, 63, music.track + v)
				self.v = music.track
				music.forceDraw = true
			end
		), "track"
	)

	for i = 0, 3 do
		music.ui:add(
			UiCheckbox(
				10 + i * 26, 8, 7, 7, true
			):onUpdate(function(self)
				music.data[music.track][i] =
					music.data[music.track][i] == -1 and i
					or -1
				music.forceDraw = true
			end), "checkbox" .. i
		)

		music.ui:add(
			UiCounter(
				i, 1 + i * 26, 16, 9, 7,
				function(self)
					local v = -1

					if api.key("lshift") or api.key("rshift") then
						v = v * 4
					end

					music.data[music.track][i] = api.mid(0, 63, music.data[music.track][i] + v)
					self.v = music.data[music.track][i]
					music.forceDraw = true
				end,
				function(self)
					local v = 1

					if api.key("lshift") or api.key("rshift") then
						v = v * 4
					end

					music.data[music.track][i] = api.mid(0, 63, music.data[music.track][i] + v)
					self.v = music.data[music.track][i]
					music.forceDraw = true
				end
			), "track" .. i
		)
	end
end

function music.open()
	music.forceDraw = true
end

function music.close()

end

local lof = { -1, -1, -1, -1 }

function music._draw()
	local of = {}

	for i = 0, 3 do
		of[i] = audio.sfx[i].sfx == nil
			and -1 or api.flr(audio.sfx[i].offset)
	end

	if music.forceDraw or
	 	of[0] ~= lof[0] or
		of[1] ~= lof[1] or
		of[2] ~= lof[2] or
		of[3] ~= lof[3] then
		music.redraw()
		music.forceDraw = false
	end

	lof = of

	editors.drawUI()
	music.ui:draw()
end

function music.redraw()
	api.cls(music.bg)

	for i = 0, 3 do
		local si = music.data[music.track][i]

		if si == -1 then
			api.brect(1 + i * 26, 24, 24, 95, 0)
		else
			api.brectfill(1 + i * 26, 24, 25, 96, 0)

			for j = 0, 15 do
				local s = sfx.data[si][j]
				local x = 2 + i * 26
				local y = 25 + j * 6
				local isEmpty = s[3] == 0


				if audio.currentMusic and
					audio.currentMusic.music == music.track and
					audio.sfx[i].sfx ~= -1 then
					if api.flr(audio.sfx[i].offset) == j then
						api.brectfill(
							x - 1, y - 1, 25, 7, 9
						)
					end
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
	end
end

function music._update()

end

function music._keydown(key)
	if api.key("rctrl") or api.key("lctrl") then
		if k == "s" then
			commads.save()
		end
	else
		if key == "space" then
			api.music(music.track)
		end
	end
end

function music.import(data)
	music.data = data
end

function music.export()
	local data = {}

	for i = 0, 63 do
		table.insert(
			data, string.format(
				"%02x ", music.data[i].loop
			)
		)

		table.insert(
			data, string.format(
				"%02x", music.data[i][0]
			)
		)

		table.insert(
			data, string.format(
				"%02x", music.data[i][1]
			)
		)

		table.insert(
			data, string.format(
				"%02x", music.data[i][2]
			)
		)

		table.insert(
			data, string.format(
				"%02x", music.data[i][3]
			)
		)

		table.insert(data, "\n")
	end

	return table.concat(data)
end

return music


