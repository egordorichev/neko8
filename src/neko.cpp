#include <neko.hpp>

neko machine;

void initNeko(neko_config *config) {
	machine.config = config;
	machine.ram = initRAM();
}