#ifndef neko_hpp
#define neko_hpp

#include <time.h>

#include <config.hpp>
#include <ram.hpp>
#include <graphics.hpp>
#include <fs.hpp>

struct neko_carts;
struct neko_console;

typedef enum neko_state_id {
	STATE_CONSOLE = 0,
	STATE_RUNNING_CART = 1,

	STATE_SIZE = 2
} neko_state_id;

typedef struct neko_state {
	bool forceDraw;

	virtual void escape(neko *machine) {};
	virtual void event(neko *machine, SDL_Event *event) {};
	virtual void render(neko *machine) {};
} neko_state;

typedef struct neko {
	neko_ram *ram;
	neko_graphics *graphics;
	neko_state_id state;
	neko_state_id prevState;
	neko_state **states;
	neko_config *config;
	neko_fs *fs;
	neko_carts *carts;
} neko;

namespace machine {
	neko *init(neko_config *config);
	void free(neko *machine);
	void render(neko *machine);
	void updateCanvas(neko *machine);
	bool handleEvent(neko *machine, SDL_Event *event);
};

#endif
