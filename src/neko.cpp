#include <neko.hpp>
#include <api.hpp>
#include <carts.hpp>
#include <code.hpp>
#include <console.hpp>

namespace machine {
	neko *init(neko_config *config) {
		neko *machine = new neko;

		machine->config = config;
		machine->ram = ram::init(machine);
		machine->prevState = STATE_CONSOLE;
		machine->state = STATE_CONSOLE;
		machine->running = true;

		api::cls(machine, 0);

		machine->graphics = graphics::init(machine);
		machine->fs = fs::init(machine);

		machine->states = new neko_state *[STATE_SIZE];
		machine->states[STATE_CONSOLE] = new neko_console(machine);
		machine->states[STATE_RUNNING_CART] = machine->carts = new neko_carts(machine);
		machine->states[STATE_CODE_EDITOR] = new neko_code(machine);

		updateCanvas(machine);
		SDL_StartTextInput();

		return machine;
	}

	void free(neko *machine) {
		for (int i = 0; i < STATE_SIZE; i++) {
			if (machine->states[i] != nullptr) {
				delete machine->states[i];
			}
		}

		delete [] machine->states;

		ram::clean(machine->ram);
		graphics::clean(machine->graphics); // Last! Because of SDL stuff
	}

	void render(neko *machine) {
		machine->states[machine->state]->render(machine);

		// Clear the window
		SDL_SetRenderDrawColor(machine->graphics->renderer, 0, 0, 0, 255);
		SDL_RenderClear(machine->graphics->renderer);

		// Get palette
		Uint8 palette[48] = {};

		for (int i = 0; i < 48; i++) {
			palette[i] = peek(machine, DRAW_START + 0x0009 + i);
		}

		// Render VRAM contents to texture
		int pitch = 0;

		Uint8 *pixels = NULL;
		Uint32 *px;

		SDL_LockTexture(machine->graphics->buffer, NULL, (void**) &px, &pitch);

		for (u32 y = peek(machine, DRAW_START + 0x0006); y < peek(machine, DRAW_START + 0x0008); y++) {
			pixels = (Uint8 *) px + (y * pitch);

			for (u32 x = peek(machine, DRAW_START + 0x0005); x < peek(machine, DRAW_START + 0x0007); x++) {
				// Get pixel at this position
				byte p = peek4(machine, (DRAW_START + 0x0039) * 2 + peek4(machine, VRAM_START * 2 + x + y * NEKO_W));

				pixels[x * 4 + 2] = palette[p * 3];
				pixels[x * 4 + 1] = palette[p * 3 + 1];
				pixels[x * 4] = palette[p * 3 + 2];
				pixels[x * 4 + 3] = 255;
			}
		}

		SDL_UnlockTexture(machine->graphics->buffer);

		// Draw the texture
		SDL_Rect nativeSize = { 0, 0, NEKO_W, NEKO_H };
		SDL_Rect outSize = { machine->graphics->x, machine->graphics->y, machine->graphics->scale * NEKO_W, machine->graphics->scale * NEKO_H };

		SDL_RenderCopy(machine->graphics->renderer, machine->graphics->buffer, &nativeSize, &outSize);
	}

	void updateCanvas(neko *machine) {
		int width;
		int height;

		SDL_GetWindowSize(machine->graphics->window, &width, &height);

		int size = floor(api::min(
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
				switch (event->key.keysym.sym) {
					case SDLK_ESCAPE:
						machine->states[machine->state]->escape(machine);
						machine->prevState = machine->state;

						if (machine->state == STATE_RUNNING_CART) {
							machine->state = STATE_CONSOLE;
						} else if (machine->state == STATE_CONSOLE) {
							machine->state = STATE_CODE_EDITOR;
						} else if (machine->state == STATE_CODE_EDITOR) {
							machine->state = STATE_CONSOLE;
						}

						machine->states[machine->state]->forceDraw = true;
						break;
				}
				break;
			case SDL_WINDOWEVENT:
				switch(event->window.event) {
					// User resized window
					case SDL_WINDOWEVENT_RESIZED:
						updateCanvas(machine);
						break;
				}
				break;
		}

		machine->states[machine->state]->event(machine, event);

		return true;
	}
}