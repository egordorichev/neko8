#ifndef neko_config_hpp
#define neko_config_hpp

#include <types.hpp>

#define NOT(o) o == NULL
#define CONFIG_NAME "config.lua"

#define NEKO_W 224
#define NEKO_H 128

typedef struct neko_config {
	// Window settings
	unsigned short windowWidth = 672;
	unsigned short windowHeight = 384;

	unsigned short palette[16][3] = {
		{ 0, 0, 0 },
		{ 29, 43, 83 },
		{ 126, 37, 83 },
		{ 0, 135, 81 },
		{ 171, 82, 54 },
		{ 95, 87, 79 },
		{ 194, 195, 199 },
		{ 255, 241, 232 },
		{ 255, 0, 77 },
		{ 255, 163, 0 },
		{ 255, 240, 36 },
		{ 0, 231, 86 },
		{ 41, 173, 255 },
		{ 131, 118, 156 },
		{ 255, 119, 168 },
		{ 255, 204, 170 }
	};
} neko_config;

#endif
