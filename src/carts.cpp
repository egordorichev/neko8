#include <neko.hpp>
#include <api.hpp>
#include <iostream>

namespace carts {
	neko_carts *init(neko *machine) {
		neko_carts *carts = new neko_carts;

		carts->path = SDL_GetPrefPath("egordorichev", "neko8");
		std::cout << carts->path << "\n";
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

	void free(neko_carts *carts) {
		delete carts;
	}
}