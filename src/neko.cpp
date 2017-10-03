#include <neko.hpp>

neko machine;

void initNeko(neko_config *config) {
	machine.config = config;
	machine.ram = initRAM();
	machine.carts = initCarts();
	machine.graphics = initGraphics();
	machine.state = STATE_BOOTING;
}

void renderNeko() {
	switch (machine.state) {
		case STATE_BOOTING:
			break;
		case STATE_RUNNING_CART:
			renderCarts();
			break;
		default:
			break;
	}

	// Render VRAM contents
	int s = machine.config->canvasScale;

	for (unsigned int x = 0; x < machine.config->canvasWidth; x++) {
		for (unsigned int y = 0; y < machine.config->canvasHeight; y++) {
			// Get pixel at this position
			byte p = peek4(VRAM_START + x + y * machine.config->canvasWidth);
			int v = (int) p.to_ullong();

			SDL_SetRenderDrawColor(machine.graphics->renderer,
				static_cast<Uint8>(machine.config->palette[v][0]),
				static_cast<Uint8>(machine.config->palette[v][1]),
				static_cast<Uint8>(machine.config->palette[v][2]), 255
			);

			SDL_Rect rect = { (int) x * s, (int) y * s, s, s };
			// And draw it
			SDL_RenderFillRect(machine.graphics->renderer, &rect);
		}
	}
}