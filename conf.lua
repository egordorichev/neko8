config = {}
config.version = {}
config.version.major = 0
config.version.minor = 0.1
config.version.name = "bunny"
config.version.string =
	"v." .. config.version.major .. "."
	.. config.version.minor .. " "
	.. config.version.name
config.window = {}
config.window.width = 588
config.window.height = 384
config.canvas = {}
config.canvas.width = 196
config.canvas.height = 128
config.fps = 30

function love.conf(t)
	t.window.width = config.window.width
	t.window.height = config.window.height
	t.window.resizable = true
	t.window.title =
		"neko8 " .. config.version.string
	t.console = true
	t.window.minwidth = config.canvas.width
	t.window.minheight = config.canvas.height

	return t
end