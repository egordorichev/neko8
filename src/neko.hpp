#ifndef neko_hpp
#define neko_hpp

#include <ram.hpp>

#define NOT(o) o == NULL
#define CONFIG_NAME "config.lua"

typedef struct neko_config {
	// Canvas settings
	unsigned short canvasWidth = 224;
	unsigned short canvasHeight = 128;
	unsigned short canvasScale = 3;
	// Window settings
	unsigned short windowWidth = 672;
	unsigned short windowHeight = 384;
} neko_config;

typedef struct neko {
	neko_ram *ram;
	neko_config *config;
} neko;

extern neko machine;
// Inits neko
void initNeko(neko_config *config);

#endif