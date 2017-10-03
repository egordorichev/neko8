#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>

void cls(unsigned int color) {
	color &= 0xf;
	color = color << 4 | color;

	memset(VRAM_START, (byte) color, VRAM_SIZE);
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