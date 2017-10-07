#include <ram.hpp>
#include <neko.hpp>
#include <iostream>

void memcpy(neko *machine, u32 destination, u32 src, u32 len) {
	if (destination < 0 || destination > RAM_SIZE - 1
			|| src < 0 || src > RAM_SIZE - 1) {
		return;
	}

	for (u32 i = 0; (i < len && src + i < RAM_SIZE
			&& destination + i < RAM_SIZE); i++) {
		machine->ram->string[destination + i] = machine->ram->string[src + i];
	}
}

void memset(neko *machine, u32 destination, byte value, u32 len) {
	if (destination < 0 || destination > RAM_SIZE - 1) {
		return;
	}

	for (u32 i = 0; (i < len && destination + i < RAM_SIZE); i++) {
		machine->ram->string[destination + i] = value;
	}
}

void memseta(neko *machine, u32 destination, byte *value, u32 len) {
	if (destination < 0 || destination > RAM_SIZE - 1) {
		return;
	}

	for (u32 i = 0; (i < len && destination + i < RAM_SIZE); i++) {
		machine->ram->string[destination + i] = value[i];
	}
}

byte *memgeta(neko *machine, u32 start, u32 len) {
	if (start < 0 || start > RAM_SIZE - 1) {
		return NULL;
	}

	byte *data = (byte *) malloc(sizeof(byte) * len);

	for (u32 i = 0; (i < len && start + i < RAM_SIZE); i++) {
		data[i] = machine->ram->string[start + i];
	}

	return data;
}

byte peek(neko *machine, u32 address) {
	if (address < 0 || address > RAM_SIZE - 1) {
		return 0;
	}

	return machine->ram->string[address];
}

byte peek4(neko *machine, u32 address) {
	if (address < 0 || address > RAM_SIZE * 2 - 1) {
		return 0;
	}

	byte value = machine->ram->string[address / 2];

	if (address % 2 == 0) {
		return value >> 4;
	} else {
		return value & (byte) 0x0F;
	}
}

void poke(neko *machine, u32 address, byte value) {
	if (address < 0 || address > RAM_SIZE - 1) {
		return;
	}

	machine->ram->string[address] = value;
}

void poke4(neko *machine, u32 address, byte value) {
	if (address < 0 || address > RAM_SIZE * 2 - 1) {
		return;
	}

	byte b = machine->ram->string[address / 2];

	if (address % 2 == 0) {
		b = b & (byte) 0x0F;
		value = value << 4;
		b = b | value;
	} else {
		b = b & (byte) 0xF0;
		b = b | value;
	}

	machine->ram->string[address / 2] = b;
}

namespace ram {
	neko_ram *init(neko *machine) {
		ram::reset(machine);
		return machine->ram;
	}

	void reset(neko *machine) {
		if (machine->ram != nullptr) {
			// delete machine->ram;
			// FIXME!
		}

		neko_ram *ram = new neko_ram;
		ram->string = new byte[RAM_SIZE];
		machine->ram = ram; // Lil hack

		// Poke some data into memory
		poke(machine, DRAW_START, 0); // Pen color
		poke(machine, DRAW_START + 0x0003, 0); // Cursor X
		poke(machine, DRAW_START + 0x0004, 0); // Cursor Y
		poke(machine, DRAW_START + 0x0005, 0); // Clip X
		poke(machine, DRAW_START + 0x0006, 0); // Clip Y
		poke(machine, DRAW_START + 0x0007, NEKO_W); // Clip W
		poke(machine, DRAW_START + 0x0008, NEKO_H); // Clip H
		poke(machine, DRAW_START + 0x0043, 0); // Camera X (1 byte)
		poke(machine, DRAW_START + 0x0044, 0); // Camera X (1 byte)
		poke(machine, DRAW_START + 0x0005, 0); // Camera Y (1 byte)
		poke(machine, DRAW_START + 0x0006, 0); // Camera Y (2 byte)
		poke(machine, DRAW_START + 0x0047, 0); // Camera pos inverted

		// Palette
		for (u32 i = 0; i < 16; i++) {
			for (u32 j = 0; j < 3; j++) {
				poke(machine, DRAW_START + 0x0009 + i * 3 + j, machine->config->palette[i][j]);
			}

			// Color mapping
			poke4(machine, (DRAW_START + 0x0039) * 2 + i, i);
		}

		// Setup transparent colors
		byte n = 0;
		n |= 1 << 7; // 0 is transparent by default

		poke(machine, DRAW_START + 0x0041, n);
		poke(machine, DRAW_START + 0x0042, 0);
	}

	void clean(neko_ram *ram) {
		free(ram->string);
		delete ram;
	}
}