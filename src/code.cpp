#include <code.hpp>
#include <api.hpp>
#include <carts.hpp>

neko_code::neko_code(neko *machine) {

}

void neko_code::escape(neko *machine) {
	api::cls(machine, 0);
}

void neko_code::event(neko *machine, SDL_Event *event) {

}

void neko_code::render(neko *machine) {
	api::cls(machine, 2);
	api::rectfill(machine, 0, 0, NEKO_W, 6, 1);
	api::print(machine, "neko8", 1, 1, 7);
	api::rectfill(machine, 0, NEKO_H - 6, NEKO_W, NEKO_H, 1);

	s32 x = 0;
	s32 y = 0;

	char *pointer = machine->carts->loaded->code;

	while (*pointer) {
		char c = *pointer;

		api::print(machine, &c, x + 1, y + 7, 7);

		if (c == '\n') {
			x = 0;
			y += 6;
		}	else {
			x += 4;
		}

		*pointer++;
	}
}