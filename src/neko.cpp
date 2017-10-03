#include <neko.hpp>
#include <iostream>

neko machine;

void initNeko(neko_config *config) {
	machine.config = config;
	machine.ram = initRAM();
	machine.graphics = initGraphics();

	for (unsigned int x = 0; x < machine.config->canvasWidth; x++) {
		for (unsigned int y = 0; y < machine.config->canvasHeight; y++) {
			poke4(VRAM_START + x + y * machine.config->canvasWidth, rand() % 16);
		}
	}
}

void renderNeko() {
	unsigned int s = machine.config->canvasScale;

	for (unsigned int x = 0; x < machine.config->canvasWidth; x++) {
		for (unsigned int y = 0; y < machine.config->canvasHeight; y++) {
			byte p = peek4(VRAM_START + x + y * machine.config->canvasWidth);
			int v = p.to_ulong() * 16;

			SDL_SetRenderDrawColor(machine.graphics->renderer, v, v, v, 255);
			SDL_Rect rect = { x * s, y * s, s, s };
			SDL_RenderFillRect(machine.graphics->renderer, &rect);
		}
	}
}