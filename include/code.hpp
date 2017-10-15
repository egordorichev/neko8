#ifndef neko_code_hpp
#define neko_code_hpp

#include <string>
#include <SDL_events.h>

#include <neko.hpp>
#include <editors.hpp>

typedef struct neko_code : neko_editor_state {
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