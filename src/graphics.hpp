#ifndef neko_graphics_hpp
#define neko_graphics_hpp

#include <SDL2/SDL.h>
#include <config.hpp>

typedef struct neko_graphics {
	SDL_Window *window;
	SDL_Renderer *renderer;
	unsigned int scale = 3;
} neko_graphics;

struct neko;

namespace graphics {
	neko_graphics *init(neko *machine);
}

#endif