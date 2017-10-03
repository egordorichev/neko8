#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>

void cls(unsigned int color) {
	color &= 0xf;
	color = color << 4 | color;

	memset(VRAM_START, (byte) color, VRAM_SIZE);
}

void color(unsigned int c) {

}

void rect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, unsigned int c) {
	color(c);

	if (x0 > x1) {
		unsigned int tmp = x0;
		x0 = x1;
		x1 = tmp;
	}

	if (y0 > y1) {
		unsigned int tmp = y0;
		y0 = y1;
		y1 = tmp;
	}
}

unsigned int pget(unsigned int x, unsigned int y) {
	if (x < 0 || y < 0 || x > machine.config->canvasWidth || y > machine.config->canvasHeight) {
		return 0;
	}

	return peek4(VRAM_START + x + y * machine.config->canvasWidth).to_ulong();
}

void pset(unsigned int x, unsigned int y, unsigned int color) {
	if (x < 0 || y < 0 || x > machine.config->canvasWidth || y > machine.config->canvasHeight) {
			return;
	}

	poke4(VRAM_START + x + y * machine.config->canvasWidth, color);
}