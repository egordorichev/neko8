#ifndef neko_hpp
#define neko_hpp

#include <time.h>

#include <config.hpp>
#include <ram.hpp>
#include <console.hpp>
#include <graphics.hpp>
#include <fs.hpp>
#include <carts.hpp>

typedef enum neko_state {
	STATE_CONSOLE = 0,
	STATE_RUNNING_CART = 1,
	STATE_CODE_EDITOR = 2
} neko_state;

typedef struct neko {
	neko_ram *ram;
	neko_graphics *graphics;
	neko_carts *carts;
	neko_state state;
	neko_state prevState;
	neko_config *config;
	neko_fs *fs;

	neko_console *console;
} neko;

namespace machine {
	neko *init(neko_config *config);
	void free(neko *machine);
	void render(neko *machine);
	void updateCanvas(neko *machine);
	bool handleEvent(neko *machine, SDL_Event *event);
};

#endif
