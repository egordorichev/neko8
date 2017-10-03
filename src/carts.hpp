#ifndef neko_carts_hpp
#define neko_carts_hpp
#include <sol.hpp>

typedef struct neko_cart {
	char *code;
	sol::state lua;
	sol::environment env;
} neko_cart;

typedef struct neko_carts {
	neko_cart *loaded;
	char *path;
} neko_carts;

// Inits carts
neko_carts *initCarts();
// Renders current
void renderCarts();
// Attemps to call a callback in cart
void triggerCallbackInCart(char *callback); // TODO: add args
// Creates new cart
neko_cart *createNewCart();
// Runs current loaded cart
void runCart();

#endif