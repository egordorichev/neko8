#include <console.hpp>
#include <api.hpp>
#include <neko.hpp>

namespace console {
	static void drawPrompt(neko *machine) {
		api::print(machine, (char *) std::string("> " + machine->console->input).c_str()); // TODO
	}

	neko_console *init(neko *machine) {
		neko_console *console = new neko_console;

		console->input = "";
		console->forceDraw = true;

		api::color(machine, 7); // Just in case
		api::print(machine, "neko8 v0.1.0");
		api::print(machine, "");
		api::print(machine, "by @egordorichev and other");
		api::print(machine, "");
		api::print(machine, "type help for help");
		api::print(machine, "");

		return console;
	}

	void render(neko *machine) {
		if (machine->console->forceDraw) {
			drawPrompt(machine);
			machine->console->forceDraw = false;
		}
	}

	void clean(neko_console *console) {
		delete console;
	}
}