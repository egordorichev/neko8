#include <SDL2/SDL.h>
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

			// Read canvas width
			if (lua["config"]["window"]["width"]) {
				config.canvasWidth = lua["config"]["canvas"]["width"];
			}

			// Read canvas height
			if (lua["config"]["window"]["height"]) {
				config.canvasHeight = lua["config"]["canvas"]["height"];
			}

			// Read canvas scale
			if (lua["config"]["window"]["scale"]) {
				config.windowWidth = lua["config"]["canvas"]["scale"];
			}
		} else {
			std::cerr << "Invalid config file\n";
		}
	} catch (sol::error error) {
		std::cout << error.what() << "\n";
	}

	// Init neko8
	initNeko(&config);

	// Used to get info about events
	SDL_Event event;
	// If true, neko8 should draw next frame
	bool running = true;
	// Used for capping FPS
	float startTime = SDL_GetTicks();
	float deltaTime = 0;
	float fps = 0;
	float timePerFrame = 1000.0f / 60.0f;

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
		SDL_RenderClear(machine.graphics->renderer);
		// Render neko8
		renderNeko();
		// Sync window
		SDL_RenderPresent(machine.graphics->renderer);
		// Calculate FPS
		int time = SDL_GetTicks();
		deltaTime = time - startTime;
		startTime = time;

		if (deltaTime != 0) {
			fps = 1000 / deltaTime;
		}

		// TODO: better cap algorithm
		SDL_Delay(timePerFrame);
	}

	// Free renderer
	SDL_DestroyRenderer(machine.graphics->renderer);
	// Free window
	SDL_DestroyWindow(machine.graphics->window);
	// And exit
	SDL_Quit();

	return 0;
}