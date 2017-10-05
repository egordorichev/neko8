#include <neko.hpp>
#include <iostream>

namespace machine {
	neko *init(neko_config *config) {
		neko *machine = new neko;

		machine->config = config;
		machine->ram = ram::init(machine);
		machine->carts = carts::init(machine);
		machine->graphics = graphics::init(machine);
		machine->fs = fs::init(machine);
		machine->prevState = STATE_CONSOLE;
		machine->state = STATE_CONSOLE;

		carts::run(machine);
		// carts::save(machine, "test.txt");

		return machine;
	}

	void free(neko *machine) {
		ram::free(machine->ram);
		carts::free(machine->carts);
		graphics::free(machine->graphics); // Last! Because of SDL stuff
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
					static_cast<Uint8>(peek(machine, DRAW_START + 0x0009 + v * 3),
					static_cast<Uint8>(peek(machine, DRAW_START + 0x0009 + v * 3 + 1),
					static_cast<Uint8>(peek(machine, DRAW_START + 0x0009 + v * 3 + 2), 255
				);

				SDL_Rect rect = {(int) x * s, (int) y * s, s, s};
				// And draw it
				SDL_RenderFillRect(machine->graphics->renderer, &rect);
			}
		}
	}
}