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
		auto callback = machine.carts->loaded->env[name];
		if (callback != sol::nil) {
			try {
				callback();

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
"-- @author\n"
"t=0\n"
"function _draw()\n"
" for i=0,199 do\n"
"  x,y=rnd(223),rnd(127)\n"
"  c=t+x/30+y/30\n"
"  circ(x,y,1,c)\n"
" end\n"
"end\n"
"function _update()\n"
" t=t+0.01\n"
"end\n";

	// Create safe lua sandbox
	cart->lua = sol::state();
	cart->lua.open_libraries();
	cart->env = sol::environment(cart->lua, sol::create);

	// Add API
	cart->env["printh"] = cart->lua["print"];
	cart->env["cls"] = cls;
	cart->env["pget"] = pget;
	cart->env["pset"] = pset;
	cart->env["line"] = line;
	cart->env["rect"] = rect;
	cart->env["rectfill"] = rectfill;
	cart->env["circ"] = circ;
	cart->env["circfill"] = circfill;
	cart->env["rnd"] = rnd;

	return cart;
}

void runCart() {
	machine.prevState = machine.state;
	machine.state = STATE_RUNNING_CART;
	machine.carts->loaded->lua.script(machine.carts->loaded->code, machine.carts->loaded->env);

	if (machine.carts->loaded->env["_draw"] == sol::nil && machine.carts->loaded->env["_update"] == sol::nil) {
		machine.state = machine.prevState;
	}
}
