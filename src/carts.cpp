#include <neko.hpp>
#include <api.hpp>
#include <iostream>

neko_carts *initCarts() {
	neko_carts *carts = new neko_carts;

	carts->path = SDL_GetPrefPath("egordorichev", "neko8");
	std::cout << carts->path << "\n";
	carts->loaded = createNewCart();

	return carts;
}

void renderCarts() {
	triggerCallbackInCart("_update");
	triggerCallbackInCart("_draw");
}

void triggerCallbackInCart(const char *name) {
	if (machine.state == STATE_RUNNING_CART) {
		if (machine.carts->loaded->env[name]) {
			try {
				machine.carts->loaded->env[name]();
			} catch (sol::error error) {
				machine.state = STATE_CONSOLE;
				std::cout << error.what() << "\n";
				// TODO: output the error in the console
			}
		}
	}
}

neko_cart *createNewCart() {
	neko_cart *cart = new neko_cart;

	cart->code = (char *)
"-- cart name\n"
"-- @author\n";
"cls(0)";

	// Create safe lua sandbox
	cart->lua = sol::state();
	cart->lua.open_libraries();
	cart->lua.new_usertype<byte>("byte");
	cart->env = sol::environment(cart->lua, sol::create);

	// Add API
	cart->env["printh"] = cart->lua["print"];
	cart->env["cls"] = cls;
	cart->env["pget"] = pget;

	return cart;
}

void runCart() {
	machine.prevState = machine.state;
	machine.state = STATE_RUNNING_CART;
	machine.carts->loaded->lua.script(machine.carts->loaded->code, machine.carts->loaded->env);

	if (!machine.carts->loaded->env["_draw"] && !machine.carts->loaded->env["_update"]) {
		machine.state = machine.prevState;
	}
}