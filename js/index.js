WIDTH = 192
HEIGHT = 128

var neko = {}

neko.init = function() {
	initCanvas(document.getElementById("container"))
}

function initCanvas(container) {
	neko.canvas = document.createElement("canvas");

	window.onresize()

	neko.canvas.tabIndex = 1
	neko.canvas.setAttribute("id", "canvas")
	container.appendChild(neko.canvas);

	neko.canvas.focus();
}

window.onresize = function() {
	var size = Math.floor(
		Math.min(window.innerWidth, window.innerHeight) / 128
	)

	neko.canvas.width = size * WIDTH
	neko.canvas.height = size * HEIGHT
}

function render() {

}

function run() {
	neko.init()

	requestAnimationFrame(render)
}