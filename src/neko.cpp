#include <neko.hpp>

namespace machine {
	neko *init(neko_config *config) {
		neko *machine = new neko;

		machine->config = config;
		machine->ram = ram::init(machine);
		machine->carts = carts::init(machine);
		machine->graphics = graphics::init(machine);
		machine->prevState = STATE_CONSOLE;
		machine->state = STATE_CONSOLE;

		carts::run(machine);

		return machine;
	}

	void render(neko *machine) {
		switch (machine->state) {
			case STATE_RUNNING_CART:
				carts::render(machine);
				break;
			default:
				break;
		}

		// Render VRAM contents
		int s = machine->graphics->scale;

		for (unsigned int x = 0; x < NEKO_W; x++) {
			for (unsigned int y = 0; y < NEKO_H; y++) {
				// Get pixel at this position
				byte p = peek4(machine, VRAM_START + x + y * NEKO_W);
				int v = (int) p.to_ullong();

				SDL_SetRenderDrawColor(machine->graphics->renderer,
					static_cast<Uint8>(machine->config->palette[v][0]),
					static_cast<Uint8>(machine->config->palette[v][1]),
					static_cast<Uint8>(machine->config->palette[v][2]), 255
				);

				SDL_Rect rect = {(int) x * s, (int) y * s, s, s};
				// And draw it
				SDL_RenderFillRect(machine->graphics->renderer, &rect);
			}
		}
	}
};