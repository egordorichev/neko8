#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>
#include <iostream>

void cls(unsigned int color) {
	color &= 0xf;
	color = color << 4 | color;

	std::cout << color << "\n";

	memset(VRAM_START, (byte) color, VRAM_SIZE);
}

unsigned int pget(unsigned int x, unsigned int y) {
	return peek4(x + y * machine.config->canvasWidth).to_ulong();
}