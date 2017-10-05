#ifndef neko_ram_hpp
#define neko_ram_hpp

#include <config.hpp>

// Sprite memory
#define SPRITE_START 0x0
#define SPRITE_SIZE 0x8000
#define SPRITE_END (SPRITE_START + SPRITE_SIZE)

// Map memory
#define MAP_START SPRITE_END
#define MAP_SIZE 0x4000
#define MAP_END (MAP_START + MAP_SIZE)

// Sprite flags memory
#define FLAGS_START MAP_END
#define FLAGS_SIZE 0x0200
#define FLAGS_END (FLAGS_START + FLAGS_SIZE)

// Sfx memory
#define SFX_START FLAGS_END
#define SFX_SIZE 0x10FF
#define SFX_END (SFX_START + SFX_SIZE)

// Music memory
#define MUSIC_START SFX_END
#define MUSIC_SIZE 0x00FF
#define MUSIC_END (MUSIC_START + MUSIC_SIZE)

// Persistent data memory
#define PERSISTENT_START MUSIC_END
#define PERSISTENT_SIZE 0x00FF
#define PERSISTENT_END (PERSISTENT_START + PERSISTENT_SIZE)

// Code memory
#define CODE_START PERSISTENT_END
#define CODE_SIZE 0x4000
#define CODE_END (CODE_START + CODE_SIZE)

// Draw state memory
#define DRAW_START CODE_END
#define DRAW_SIZE 0x00FF
#define DRAW_END (DRAW_START + DRAW_SIZE)

/*
 * Draw state memory layout:
 * 0x0000 - pen color (1 byte)
 * 0x0001 - camera position (2 bytes)
 * 0x0003 - cursor position (2 bytes)
 * 0x0005 - clip rect (4 bytes)
 * 0x0009 - palette (48 bytes)
 * 0x0039 - palette mapping (8 bytes)
 */

// Video memory
#define VRAM_START DRAW_END
#define VRAM_SIZE 0x3800
#define VRAM_END (VRAM_START + VRAM_SIZE)

// Other memory
#define OTHER_START VRAM_END
#define OTHER_SIZE 0x00FF
#define OTHER_END (OTHER_START + OTHER_SIZE)

/*
 * -- TODO: mouse
 */

// Total memory size
#define RAM_SIZE (SPRITE_END + MAP_SIZE \
	+ FLAGS_SIZE + MUSIC_SIZE + PERSISTENT_SIZE + CODE_SIZE + DRAW_SIZE \
	+VRAM_SIZE + OTHER_SIZE)

// Cart size
#define CART_SIZE (SPRITE_END + MAP_SIZE \
	+ FLAGS_SIZE + MUSIC_SIZE + PERSISTENT_SIZE + CODE_SIZE)

typedef struct neko_ram {
	// The actual memory
	byte *string;
} neko_ram;

struct neko;

// Basic memory operations
void memcpy(neko *machine, u32 destination, u32 src, u32 len);
void memset(neko *machine, u32 destination, byte value, u32 len);
void memseta(neko *machine, u32 destination, byte *value, u32 len);
byte *memgeta(neko *machine, u32 start, u32 len);
byte peek(neko *machine, u32 address);
byte peek4(neko *machine, u32 address);
void poke(neko *machine, u32 address, byte value);
void poke4(neko *machine, u32 address, byte value);

namespace ram {
	// Creates RAM instance
	neko_ram *init(neko *machine);
	// Resets RAM
	void reset(neko *machine);
	// Free stuff
	void clean(neko_ram *ram);
};

#endif
