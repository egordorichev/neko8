#include <SDL2/SDL.h>
#include <iostream>

#include <neko.hpp>
#include <graphics.hpp>
#include <config.hpp>

namespace graphics {
	neko_graphics *init(neko *machine) {
		neko_graphics *graphics = new neko_graphics;

		// Attempt to open a centred window
		graphics->window = SDL_CreateWindow(
			"neko8", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
			machine->config->windowWidth, machine->config->windowHeight,
			SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
		);

		if (NOT(graphics->window)) {
			// We failed, so there is nothing to do for us, abort
			std::cerr << "Failed to open window, aborting\n";
			SDL_Quit();
			exit(1);
		}

		// Attempt to create renderer
		graphics->renderer = SDL_CreateRenderer(graphics->window, -1, SDL_RENDERER_ACCELERATED);

		if (NOT(graphics->renderer)) {
			// We failed, so there is nothing to do for us, abort
			std::cerr << "Failed to create a renderer, aborting\n";
			SDL_Quit();
			exit(2);
		}

		// Set minimum window size
		SDL_SetWindowMinimumSize(graphics->window, NEKO_W, NEKO_H);
		// Move window up
		SDL_RaiseWindow(graphics->window);

		graphics->scale = 3;
		graphics->x = 0;
		graphics->y = 0;

		return graphics;
	}

	void clean(neko_graphics *graphics) {
		// Free renderer
		SDL_DestroyRenderer(graphics->renderer);
		// Free window
		SDL_DestroyWindow(graphics->window);

		delete graphics;
	}
}