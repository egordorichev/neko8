#ifndef neko_carts_hpp
#define neko_carts_hpp

typedef struct neko_cart {
	char *code;
} neko_cart;

typedef struct neko_carts {
	neko_cart *loaded;
} neko_carts;

// Inits carts
neko_carts *initCarts();
// Renders current
void renderCarts();
// Attemps to call a callback in cart
void triggerCallbackInCart(char *callback); // TODO: add args

#endif