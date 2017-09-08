local neko8 = {
	code = {
		bg = 2,
		fg = 6,
		cursor = 8,

		colors = {
			select = 1,
			text = 6,
			keyword = 8,
			number = 12,
			comment = 13,
			str = 12,
			selection = 7
			-- todo: tokens
		}
	},

	sprites = {
		bg = 5,
		fg = 7
	},

	map = {
		bg = 0,
		fg = 7
	},

	sfx = {
		bg = 5,
		fg = 7
	},

	music = {
		bg = 5,
		fg = 7
	},

	ui = {
		bg = 1,
		fg = 7,
		icons = {
			selected = 6,
			default = 7
		}
	}
}

config = {
	version = {
		major = 0,
		minor = 0.1,
		name = "kitten",
		string = "v0.0.3 kitten"
	},

	window = {
		width = 576,
		height = 384
	},

	canvas = {
		width = 192,
		height = 128
	},

	font = {
		file = "font.ttf",
		letters = "abcdefghijklmnopqrstuvwxyz"
		.. "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		.. "1234567890!?[](){}.,;:<>+=%#^*~/\\|$"
		.. "@&`\"'-_ "
	},

	messages = {
		fg = 7,
		bg = 8
	},

	fps = 60,

	palette = {
		{ 0, 0, 0, 255 },
		{ 29, 43, 83, 255 },
		{ 126, 37, 83, 255 },
		{ 0, 135, 81, 255 },
		{ 171, 82, 54, 255 },
		{ 95, 87, 79, 255 },
		{ 194, 195, 199, 255 },
		{ 255, 241, 232, 255 },
		{ 255, 0, 77, 255 },
		{ 255, 163, 0, 255 },
		{ 255, 240, 36, 255 },
		{ 0, 231, 86, 255 },
		{ 41, 173, 255, 255 },
		{ 131, 118, 156, 255 },
		{ 255, 119, 168, 255 },
		{ 255, 204, 170, 255 }
	},

	editors = neko8,

	audio = {
		bufferSize = 1024,
		sampleRate = 22050
	}
}

function love.conf(t)
	t.window.width = config.window.width
	t.window.height = config.window.height
	t.window.resizable = true
	t.window.title =
		"neko8 " .. config.version.string
	t.console = true
	t.window.minwidth = config.canvas.width
	t.window.minheight = config.canvas.height
	t.identity = "neko8"

	return t
end
