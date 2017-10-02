#include <ram.hpp>
#include <neko.hpp>
#include <cstdlib>

void memcpy(unsigned int destination, unsigned int src, unsigned int len) {
	if (destination < 0 || destination > RAM_SIZE - 1
			|| src < 0 || src > RAM_SIZE - 1) {
		return;
	}

	for (unsigned int i = 0; (i < len && src + i < RAM_SIZE
			&& destination + i < RAM_SIZE); i++) {
		machine.ram->string[destination + i] = machine.ram->string[src + i];
	}
}

void memset(unsigned int destination, char value, unsigned int len) {
	if (destination < 0 || destination > RAM_SIZE - 1) {
		return;
	}

	for (unsigned int i = 0; (i < len && destination + i < RAM_SIZE); i++) {
		machine.ram->string[destination + i] = value;
	}
}

char peek(unsigned int address) {
	if (address < 0 || address > RAM_SIZE - 1) {
		return 0;
	}

	return machine.ram->string[address];
}

void poke(unsigned int address, char value) {
	if (address < 0 || address > RAM_SIZE - 1) {
		return;
	}

	machine.ram->string[address] = value;
}

neko_ram *initRAM() {
	neko_ram *ram = (neko_ram *) malloc(sizeof(neko_ram));
	ram->string = (char *) malloc(RAM_SIZE * sizeof(char));

	return ram;
}