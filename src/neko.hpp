#ifndef neko_hpp
#define neko_hpp

#define NOT(o) o == NULL
#define CONFIG_NAME "config.lua"

typedef struct Config {
	// Canvas settings
	unsigned short canvasWidth = 224;
	unsigned short canvasHeight = 128;
	unsigned short canvasScale = 3;
	// Window settings
	unsigned short windowWidth = 672;
	unsigned short windowHeight = 384;
} Config;

#endif