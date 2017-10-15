#ifndef neko_editors_hpp
#define neko_editors_hpp

#include <SDL_events.h>

#include <neko.hpp>

struct neko_code;

typedef struct neko_editor_state {
	bool forceDraw;

	virtual void escape(neko *machine) {};
	virtual void event(neko *machine, SDL_Event *event) {};
	virtual void render(neko *machine) {};
} neko_editor_state;

typedef enum neko_editor_id {
	CODE_EDITOR = 0,
	EDITORS_SIZE = 1
} neko_editor_id;

typedef struct neko_editors : neko_state {
	neko_editors(neko *machine);
	~neko_editors();

	void escape(neko *machine);
	void event(neko *machine, SDL_Event *event);
	void render(neko *machine);

	neko_editor_state **states;
	neko_editor_id state;
} neko_editors;

#endif