#include <api.hpp>
#include <helpers.hpp>
#include <carts.hpp>

#include <iostream>
#include <sstream>
#include <zlib.h>
#include <csetjmp>

#define COMPRESSED_CODE_MAX_SIZE 16384

neko_carts::neko_carts(neko *machine) {
	this->loaded = this->createNew(machine);
}

void neko_carts::render(neko *machine) {
	if (!this->loaded->initDone) {
		this->loaded->initDone = true; // TODO
	} else {
		this->triggerCallback(machine, "_update");
		this->triggerCallback(machine, "_draw");
	}
}

bool neko_carts::checkForLuaFunction(neko *machine, const char *name) {
	lua_getglobal(this->loaded->thread, name);

	bool result = lua_isfunction(this->loaded->thread, -1);
	lua_pop(this->loaded->thread, 1);

	return result;
}

void neko_carts::triggerCallback(neko *machine, const char *name) {
	lua_getglobal(this->loaded->thread, name);

	if (lua_isfunction(this->loaded->thread, -1)) {
		int error = lua_pcall(this->loaded->thread, 0, 0, 0);

		if (error) {
			// Error :P
			std::cout << lua_tostring(this->loaded->thread, -1) << "\n";
		}
	}
}

static const luaL_Reg luaLibs[] = {
	{ "", luaopen_base },
	{ LUA_TABLIBNAME, luaopen_table },
	{ LUA_STRLIBNAME, luaopen_string },
	{ LUA_MATHLIBNAME, luaopen_math },
	{ NULL, NULL }
};

neko_cart *neko_carts::createNew(neko *machine) {
	neko_cart *cart = new neko_cart;

	cart->code = (char *) "t=0 function _draw() for i = 0, 399 do circ(rnd(224),rnd(128),1,0) end t=t+1 local c=(t/0.1)%8+8 circfill(sin(t+180)*50+64,cos(t+180)*50+64,3,c) circfill(sin(t+270)*50+64,cos(t+270)*50+64,3,c+1) circfill(sin(t+90)*50+64,cos(t+90)*50+64,3,c+2) circfill(sin(t)*50+64,cos(t)*50+64,3,c+3) end";

	// Create lua state
	cart->lua = luaL_newstate();

	// Default libs
	const luaL_Reg *lib;

	for (lib = luaLibs; lib->func; lib++) {
		lua_pushcfunction(cart->lua, lib->func);
		lua_pushstring(cart->lua, lib->name);
		lua_call(cart->lua, 1, 0);
	}

	lua_pop(cart->lua, 1);

	// Add API
	defineLuaAPI(machine, cart->lua);
	luaL_openlibs(cart->lua);

	static const struct luaL_Reg printLib[] = {
		{ "print", print },
		{ NULL, NULL }
	};

	lua_getglobal(cart->lua, "_G");
	luaL_register(cart->lua, NULL, printLib);
	lua_pop(cart->lua, 1);

	return cart;
}

void neko_carts::run(neko *machine) {
	machine->state = STATE_RUNNING_CART;

	this->loaded->thread = lua_newthread(this->loaded->lua);

	int error = luaL_loadstring(this->loaded->thread, this->loaded->code);

	if (error) {
		// Error :P
		std::cout << lua_tostring(this->loaded->thread, -1) << "\n";
		return;
	}

	error = lua_pcall(this->loaded->thread, 0, 0, 0);

	if (error) {
		// Error :P
		std::cout << lua_tostring(this->loaded->thread, -1) << "\n";
		return;
	}

	if (!checkForLuaFunction(machine, "_init") && !checkForLuaFunction(machine, "_draw") && !checkForLuaFunction(machine, "_update")) {
		machine->state = STATE_CONSOLE;
	} else {
		// this->triggerCallback(machine, "_init");
	}
}

char *compressString(char *str) {
	char *res = (char *) malloc(COMPRESSED_CODE_MAX_SIZE * sizeof(char));

	z_stream defstream;
	defstream.zalloc = Z_NULL;
	defstream.zfree = Z_NULL;
	defstream.opaque = Z_NULL;
	defstream.avail_in = (uInt) strlen(str) + 1;
	defstream.next_in = (Bytef *) str;
	defstream.avail_out = (uInt) COMPRESSED_CODE_MAX_SIZE;
	defstream.next_out = (Bytef *) res;

	deflateInit(&defstream, Z_BEST_COMPRESSION);
	deflate(&defstream, Z_FINISH);
	deflateEnd(&defstream);

	return res;
}

char *decompressString(char *str) {
	char *res = (char *) malloc(CODE_SIZE * sizeof(char));

	z_stream infstream;
	infstream.zalloc = Z_NULL;
	infstream.zfree = Z_NULL;
	infstream.opaque = Z_NULL;
	infstream.avail_in = (uInt) ((char *) 0 - str);
	infstream.next_in = (Bytef *) str;
	infstream.avail_out = (uInt) sizeof(res);
	infstream.next_out = (Bytef *) res;

	inflateInit(&infstream);
	inflate(&infstream, Z_NO_FLUSH);
	inflateEnd(&infstream);

	return res;
}

void neko_carts::load(neko *machine, char *name) {
	ram::reset(machine);

	char *data = fs::read(machine, helper::concat(machine->fs->dir, name));

	if (data == nullptr) {
		return;
	}

	memseta(machine, 0x0, (byte *) data, CART_SIZE);

	// Decompress code
	byte *compressed = memgeta(machine, CODE_START, COMPRESSED_CODE_MAX_SIZE);
	char *decompressed = decompressString((char *) compressed);

	this->loaded->code = decompressed;

	free(compressed);
}

void neko_carts::save(neko *machine, char *name) {
	// Compress code
	char *code = this->loaded->code;
	char *compressed = compressString(code);

	// Copy it to memory
	memseta(machine, CODE_START, (byte *) compressed, COMPRESSED_CODE_MAX_SIZE);

	// Write out cart data
	byte *data = memgeta(machine, 0x0, CART_SIZE);

	char *savepath = helper::concat(machine->fs->dir, name);

	fs::write(machine, savepath, (char *) data, RAM_SIZE);

	if (fs::exists(machine, savepath)) {
		std::cout << "saved" << std::endl;
	}

	delete[] savepath;

	free(compressed);
	free(data);
}

void neko_carts::escape(neko *machine) {

}

void neko_carts::event(neko *machine, SDL_Event *event) {

}