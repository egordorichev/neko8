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

		return graphics;
	}
}