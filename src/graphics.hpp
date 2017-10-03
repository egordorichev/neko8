#ifndef neko_graphics_hpp
#define neko_graphics_hpp

#include <SDL2/SDL.h>
#include <config.hpp>

typedef struct neko_graphics {
	SDL_Window *window;
	SDL_Renderer *renderer;
} neko_graphics;

neko_graphics *initGraphics();

#endif