#include <globals.hpp>
#include <console.hpp>
#include <api.hpp>
#include <iostream>
#include <algorithm>
#include <carts.hpp>

neko_console::neko_console(neko *machine) {
	this->input = "";
	this->forceDraw = true;
	this->t = 0;
	this->cursorState = true;

	api::color(machine, 7); // Just in case
	api::print(machine, "neko8 v0.1.0");
	api::print(machine, "");
	api::print(machine, "by @egordorichev and other");
	api::print(machine, "");
	api::print(machine, "type help for help");
	api::print(machine, "");
}

void neko_console::render(neko *machine) {
	this->t += 1;

	bool newState = (t < 60 || t % 60 > 30);

	if (this->forceDraw || this->cursorState != newState) {
		this->cursorState = newState;
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
			switch (event->key.keysym.sym) {
				case SDLK_BACKSPACE:
					if (this->input.size() > 0) {
						this->input = this->input.substr(0, this->input.size() - 1);
						this->forceDraw = true;
					}
					break;
				case SDLK_RETURN:
					this->cursorState = false;
					this->drawPrompt(machine);

					std::string command = this->input;
					this->input = "";

					api::print(machine, "");
					api::color(machine, 7);

					this->runCommand(machine, command);
					this->forceDraw = true;
					break;
			}
			break;
	}
}

inline std::string trim(const std::string &s) {
	auto wsfront = std::find_if_not(s.begin(), s.end(), [](int c) { return std::isspace(c); });
	auto wsback = std::find_if_not(s.rbegin(), s.rend(), [](int c) { return std::isspace(c); }).base();
	return (wsback <= wsfront ? std::string() : std::string(wsfront, wsback));
}

void neko_console::runCommand(neko *machine, std::string command) {
	command = trim(command);

	if (command == "help") {
		api::print(machine, "Command        Description");
		api::print(machine, "-------        -----------");
		api::print(machine, "run            runs the loaded cart");
		api::print(machine, "help           prints this help");
	} else if (command == "run") {
		machine->carts->run(machine);
	} else if (command == "shutdown") {
		machine->running = false;
	} else {
		api::color(machine, 8);
		api::print(machine, "unknown command");
	}
}

void neko_console::drawPrompt(neko *machine) {
	int y = peek(machine, DRAW_START + 0x002); // Cursor Y
	int y1 = y - 1;

	if (y1 < 0) {
		y1 = 0;
	}

	api::rectfill(machine, 0, y1, this->input.size() * 4 + 16, y + 4, 0);

	if (this->cursorState) {
		api::rectfill(machine, this->input.size() * 4 + 8, y1, this->input.size() * 4 + 11, y + 4, 8);
	}

	api::print(machine, (char *) std::string("> " + this->input).c_str(), 0, y, 6);
}