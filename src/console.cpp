#include <console.hpp>
#include <api.hpp>
#include <iostream>

neko_console::neko_console(neko *machine) {
	this->input = "";
	this->forceDraw = true;

	api::color(machine, 7); // Just in case
	api::print(machine, "neko8 v0.1.0");
	api::print(machine, "");
	api::print(machine, "by @egordorichev and other");
	api::print(machine, "");
	api::print(machine, "type help for help");
	api::print(machine, "");
}

void neko_console::render(neko *machine) {
	if (this->forceDraw) {
		this->drawPrompt(machine);
		this->forceDraw = false;
	}
}

void neko_console::escape(neko *machine) {

}

void neko_console::event(neko *machine, SDL_Event *event) {
	switch (event->type) {
		case SDL_TEXTINPUT:
				this->input += event->text.text;
				this->forceDraw = true;
			break;
		case SDL_KEYDOWN:
			switch (event->key.type) {
				case SDLK_BACKSPACE:
					if (this->input.size() > 0) {
						this->input = this->input; // TODO
					}
					break;
			}
			break;
	}
}

void neko_console::drawPrompt(neko *machine) {
	int y = peek(machine, DRAW_START + 0x004); // Cursor Y

	api::rectfill(machine, 0, y - 1, NEKO_W, y + 6, 0);
	api::color(machine, 6);
	api::print(machine, (char *) std::string("> " + this->input).c_str()); // TODO

	poke(machine, DRAW_START + 0x004, y);
}