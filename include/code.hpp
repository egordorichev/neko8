#ifndef neko_code_hpp
#define neko_code_hpp

#include <string>
#include <neko.hpp>
#include <SDL_events.h>

typedef struct neko_code : neko_state {
	neko_code(neko *machine);
	~neko_code();

	void escape(neko *machine);
	void event(neko *machine, SDL_Event *event);
	void render(neko *machine);
	void onEdit(neko *machine);

	bool cursorState;
	int t;
	s32 cursorX;
	s32 cursorY;
	char *cursorPosition;
	byte *colors = nullptr;
	char *code;
} neko_code;

#endif