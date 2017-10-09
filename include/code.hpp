#ifndef neko_code_hpp
#define neko_code_hpp

#include <string>
#include <neko.hpp>
#include <SDL_events.h>

typedef struct neko_code : neko_state {
	neko_code(neko *machine);

	void escape(neko *machine);
	void event(neko *machine, SDL_Event *event);
	void render(neko *machine);

	bool cursorState;
	int t;
} neko_code;

#endif