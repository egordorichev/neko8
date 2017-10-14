#include <SDL2/SDL.h>
#include <iostream>

#include <globals.hpp>
#include <neko.hpp>
#include <api.hpp>

#undef main

int main(int argc, char *argv[]) {
	// Parse args
	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], (strlen(argv[i]) > 2 ? "--help" : "-h")) == 0) {
			return 0;
		} else if (strcmp(argv[i], (strlen(argv[i]) > 2 ? "--debug" : "-d")) == 0) {
			globals::debug = 1;
		} else if (strcmp(argv[i], (strlen(argv[i]) > 2 ? "--cart" : "-c")) == 0) {

		}
	}

	// Set random seed based on system time
	srand(time(NULL));

	// Init SDL video system
	SDL_Init(SDL_INIT_VIDEO);

	// Open config
	neko_config config;

	// Init neko8
	neko *machine = machine::init(&config);

	// Used to get info about events
	SDL_Event event;

	// Prints debug state
	std::cout << "Running with DEBUG mode " << ((globals::debug) ? "ON" : "OFF") << "\n";

	while (machine->running) {
		while (SDL_PollEvent(&event)) {
			machine->running = machine::handleEvent(machine, &event) & machine->running;
		}

		api::flip(machine);
	}

	// Free neko
	machine::free(machine);
	// And exit
	SDL_Quit();

	return 0;
}
