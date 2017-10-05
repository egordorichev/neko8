
#include <SDL2/SDL.h>
#undef main
#include <LuaJIT/lua.hpp>
#include <iostream>
#include <sol.hpp>

#include <neko.hpp>

int main() {
	// Set random seed based on system time
	srand(time(NULL));

	// Init SDL video system
	SDL_Init(SDL_INIT_VIDEO);

	// Open config

	sol::state lua;
	neko_config config;

	try {
		// Run config
		sol::load_result configState = lua.load_file(CONFIG_NAME);
		configState();

		if (lua["config"]) {
			// Config is ok
			// Read window width
			if (lua["config"]["window"]["width"]) {
				config.windowWidth = lua["config"]["window"]["width"];
			}

			// Read window height
			if (lua["config"]["window"]["height"]) {
				config.windowHeight = lua["config"]["window"]["height"];
			}
		} else {
			std::cerr << "Invalid config file\n";
		}
	} catch (sol::error error) {
		std::cout << error.what() << "\n";
	}

	// Init neko8
	neko *machine = machine::init(&config);

	// Used to get info about events
	SDL_Event event;
	// If true, neko8 should draw next frame
	bool running = true;
	// Used for capping FPS
	float nextFrame = SDL_GetPerformanceCounter();
	float timePerFrame = SDL_GetPerformanceFrequency() / 60.0f;

	while (running) {
		while (SDL_PollEvent(&event)) {
			// We got some kind-of an event
			switch (event.type) {
				case SDL_QUIT:
					// User closes the window
					running = false;
					// TODO: save here
					break;
				default:
					// Something else, that we don't care about
					break;
			}
		}

		// Clear the window
		SDL_RenderClear(machine->graphics->renderer);
		// Render neko8
		machine::render(machine);
		// Sync window
		SDL_RenderPresent(machine->graphics->renderer);
		// Calculate FPS
		float delay = nextFrame - SDL_GetPerformanceCounter();

		if (delay > 0) {
			SDL_Delay(delay * 1000 / SDL_GetPerformanceFrequency());
		} else {
			nextFrame -= delay;
		}
	}

	// Free neko
	machine::free(machine);
	// And exit
	SDL_Quit();

	return 0;
}
