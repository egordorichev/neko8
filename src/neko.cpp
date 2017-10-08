#include <neko.hpp>
#include <iostream>
#include <api.hpp>

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

		updateCanvas(machine);

		api::cls(machine, 0);

		machine->console = console::init(machine);

		return machine;
	}

	void free(neko *machine) {
		ram::clean(machine->ram);
		carts::clean(machine->carts);
		console::clean(machine->console);
		graphics::clean(machine->graphics); // Last! Because of SDL stuff
	}

	void render(neko *machine) {
		switch (machine->state) {
			case STATE_RUNNING_CART:
				carts::render(machine);
				break;
			case STATE_CONSOLE:
				console::render(machine);
				break;
			default:
				break;
		}

		// Clear the window
		SDL_SetRenderDrawColor(machine->graphics->renderer, 0, 0, 0, 255);
		SDL_RenderClear(machine->graphics->renderer);

		// Render VRAM contents
		int s = machine->graphics->scale;

		for (u32 x = peek(machine, DRAW_START + 0x0005); x < peek(machine, DRAW_START + 0x0007); x++) {
			for (u32 y = peek(machine, DRAW_START + 0x0006); y < peek(machine, DRAW_START + 0x0008); y++) {
				// Get pixel at this position
				byte p = peek4(machine, (DRAW_START + 0x0039) * 2 + peek4(machine, VRAM_START * 2 + x + y * NEKO_W));

				SDL_SetRenderDrawColor(machine->graphics->renderer,
					static_cast<Uint8>(peek(machine, DRAW_START + 0x0009 + p * 3)),
					static_cast<Uint8>(peek(machine, DRAW_START + 0x0009 + p * 3 + 1)),
					static_cast<Uint8>(peek(machine, DRAW_START + 0x0009 + p * 3 + 2)), 255
				);

				SDL_Rect rect = {(int) x * s + machine->graphics->x, (int) y * s + machine->graphics->y, s, s};
				// And draw it
				SDL_RenderFillRect(machine->graphics->renderer, &rect);
			}
		}
	}

	void updateCanvas(neko *machine) {
		int width;
		int height;

		SDL_GetWindowSize(machine->graphics->window, &width, &height);

		float size = floor(api::min(
			machine,
			((float) width) / NEKO_W,
			((float) height) / NEKO_H
		));

		machine->graphics->scale = size;
		machine->graphics->x = (width - size * NEKO_W) / 2;
		machine->graphics->y = (height - size * NEKO_H) / 2;
	}

	bool handleEvent(neko *machine, SDL_Event *event) {
		// We got some kind-of an event
		switch (event->type) {
			case SDL_QUIT:
				// User closes the window
				return false;
			case SDL_KEYDOWN:
				// Text input

				break;
			case SDL_WINDOWEVENT:
				switch(event->window.event) {
					// User resized window
					case SDL_WINDOWEVENT_RESIZED:
						updateCanvas(machine);
						break;
				}
				break;
			default:
				// Something else, that we don't care about
				break;
		}

		return true;
	}
}
