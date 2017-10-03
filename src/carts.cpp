#include <neko.hpp>
#include <iostream>

neko_carts *initCarts() {
	neko_carts *carts = new neko_carts;

	carts->path = SDL_GetPrefPath("egordorichev", "neko8");
	std::cout << carts->path << "\n";

	carts->loaded = createNewCart();

	return carts;
}

void renderCarts() {

}

void triggerCallbackInCart(char *name) {

}

neko_cart *createNewCart() {
	neko_cart *cart = new neko_cart;

	cart->code = (char *)
"-- cart name\n"
"-- @author\n"
"print('test')";

	// Create safe lua sandbox
	cart->lua = sol::state();
	cart->lua.open_libraries();
	cart->env = sol::environment(cart->lua, sol::create);

	// Add API

	cart->env["print"] = cart->lua["print"];

	return cart;
}

void runCart() {
	machine.state = STATE_RUNNING_CART;
	machine.carts->loaded->lua.script(machine.carts->loaded->code, machine.carts->loaded->env);
}