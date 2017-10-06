#ifndef neko_carts_hpp
#define neko_carts_hpp

#include <LuaJIT/lua.hpp>

typedef struct neko_cart {
	char *code;
	lua_State *lua;
	lua_State *thread;
} neko_cart;

typedef struct neko_carts {
	neko_cart *loaded;
} neko_carts;

struct neko;

namespace carts {
	// Inits carts
	neko_carts *init(neko *machine);
	// Renders current
	void render(neko *machine);
	// Attemps to call a callback in cart
	void triggerCallback(neko *machine, const char *callback); // TODO: add args
	// Creates new cart
	neko_cart *createNew(neko *machine);
	// Runs current loaded cart
	void run(neko *machine);
	// Loads a cart
	void load(neko *machine, char *name);
	// Saves a cart
	void save(neko *machine, char *name);
	// Free all
	void clean(neko_carts *carts);
}

#endif
