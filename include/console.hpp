#ifndef neko_console_hpp
#define neko_console_hpp

#include <string>
#include <neko.hpp>
#include <SDL_events.h>

typedef struct neko_console : neko_state {
	neko_console(neko *machine);

	void escape(neko *machine);
	void event(neko *machine, SDL_Event *);
	void render(neko *machine);
	void drawPrompt(neko *machine);
	void runCommand(neko *machine, std::string command);

	std::string input;
	bool forceDraw;
	bool cursorState;
	int t;
} neko_console;

#endif