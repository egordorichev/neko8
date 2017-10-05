#include <neko.hpp>
#include <api.hpp>
#include <iostream>

#define COMPRESSED_CODE_MAX_SIZE 16384

namespace carts {
	neko_carts *init(neko *machine) {
		neko_carts *carts = new neko_carts;

		carts->loaded = carts::createNew(machine);

		return carts;
	}

	void render(neko *machine) {
		carts::triggerCallback(machine, "_update");
		carts::triggerCallback(machine, "_draw");
	}

	void triggerCallback(neko *machine, const char *name) {
		if (machine->state == STATE_RUNNING_CART) {
			auto callback = machine->carts->loaded->env[name];
			if (callback != sol::nil) {
				try {
					callback();

				} catch (sol::error error) {
					machine->state = STATE_CONSOLE;
					std::cout << error.what() << "\n";
					// TODO: output the error in the console
				}
			}
		}
	}

	neko_cart *createNew(neko *machine) {
		neko_cart *cart = new neko_cart;

		cart->code = (char *) "-- cart name\n"
			"-- @author\n";

		// Create safe lua sandbox
		cart->lua = sol::state();
		cart->lua.open_libraries();
		cart->env = sol::environment(cart->lua, sol::create);

		// Add API
		// TODO: define it :D

		return cart;
	}

	void run(neko *machine) {
		machine->prevState = machine->state;
		machine->state = STATE_RUNNING_CART;
		machine->carts->loaded->lua.script(machine->carts->loaded->code, machine->carts->loaded->env);

		if (machine->carts->loaded->env["_draw"] == sol::nil && machine->carts->loaded->env["_update"] == sol::nil) {
			machine->state = machine->prevState;
		}
	}

	void load(neko *machine, char *name) {
		char *data = (char *) fs::read(machine, name);

		if (data == nullptr) {
			return;
		}
	}

	void save(neko *machine, char *name) {
		byte compressedCode[COMPRESSED_CODE_MAX_SIZE] = { 0 };

		// Compress code
		for (int i = 0; i < COMPRESSED_CODE_MAX_SIZE; i++) {
			// TODO: compress :P
			compressedCode[i] = machine->ram->string[CODE_START + i];
		}

		// Copy it to memory
		memseta(machine, CODE_START, (byte *) compressedCode, COMPRESSED_CODE_MAX_SIZE);

		char buffer[RAM_SIZE] = { 0 };

		for (int i = 0; i < RAM_SIZE; i++) {
			buffer[i] = machine->ram->string[i].to_ulong();
		}

		fs::write(machine, name, buffer, RAM_SIZE);
	}

	void free(neko_carts *carts) {
		delete carts;
	}
}
