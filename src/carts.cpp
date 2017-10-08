#include <neko.hpp>
#include <api.hpp>

#include <iostream>
#include <sstream>
#include <zlib.h>

#include <helpers.hpp>

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

	bool checkForLuaFunction(neko *machine, const char *name) {
		lua_getglobal(machine->carts->loaded->thread, name);

		bool result = lua_isfunction(machine->carts->loaded->thread, -1);
		lua_pop(machine->carts->loaded->thread, 1);

		return result;
	}

	void triggerCallback(neko *machine, const char *name) {
		lua_getglobal(machine->carts->loaded->thread, name);

		if (lua_isfunction(machine->carts->loaded->thread, -1)) {
			int error = lua_pcall(machine->carts->loaded->thread, 0, 0, 0);

			if (error) {
				// Error :P
				std::cout << lua_tostring(machine->carts->loaded->thread, -1) << "\n";
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

	neko_cart *createNew(neko *machine) {
		neko_cart *cart = new neko_cart;

		cart->code = (char *) "camera() cls(0) t=0 function _draw() for i = 0, 399 do circ(rnd(224),rnd(128),1,0) end t=t+1 circfill(sin(t)*64+64,cos(t)*64+64,3,t%8+8) end";
		
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
			{ "print", print},
			{ NULL, NULL }
		};

		lua_getglobal(cart->lua, "_G");
		luaL_register(cart->lua, NULL, printLib);
		lua_pop(cart->lua, 1);

		return cart;
	}

	void run(neko *machine) {
		machine->prevState = machine->state;
		machine->state = STATE_RUNNING_CART;

		machine->carts->loaded->thread = lua_newthread(machine->carts->loaded->lua);

		int error = luaL_loadstring(machine->carts->loaded->thread, machine->carts->loaded->code);

		if (error) {
			// Error :P
			std::cout << lua_tostring(machine->carts->loaded->thread, -1) << "\n";
			return;
		}

		error = lua_pcall(machine->carts->loaded->thread, 0, 0, 0);

		if (error) {
			// Error :P
			std::cout << lua_tostring(machine->carts->loaded->thread, -1) << "\n";
			return;
		}

		if (!checkForLuaFunction(machine, "_draw") && !checkForLuaFunction(machine, "_update")) {
			machine->state = machine->prevState;
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
		defstream.next_out = (Bytef *)res;

		deflateInit(&defstream, Z_BEST_COMPRESSION);
		deflate(&defstream, Z_FINISH);
		deflateEnd(&defstream);

		return res;
	}

	char *decompressString(char *str)	{
		char *res = (char *) malloc(CODE_SIZE * sizeof(char));

		z_stream infstream;
		infstream.zalloc = Z_NULL;
		infstream.zfree = Z_NULL;
		infstream.opaque = Z_NULL;
		infstream.avail_in = (uInt)((char *) 0 - str);
		infstream.next_in = (Bytef *)str;
		infstream.avail_out = (uInt)sizeof(res);
		infstream.next_out = (Bytef *)res;

		inflateInit(&infstream);
		inflate(&infstream, Z_NO_FLUSH);
		inflateEnd(&infstream);

		return res;
	}

	void load(neko *machine, char *name) {
		ram::reset(machine);

		char *data = fs::read(machine, helper::concat(machine->fs->dir, name));

		if (data == nullptr) {
			return;
		}

		memseta(machine, 0x0, (byte *) data, CART_SIZE);

		// Decompress code
		byte *compressed = memgeta(machine, CODE_START, COMPRESSED_CODE_MAX_SIZE);
		char *decompressed = decompressString((char *) compressed);

		machine->carts->loaded->code = decompressed;

		free(compressed);
	}

	void save(neko *machine, char *name) {
		// Compress code
		char *code = machine->carts->loaded->code;
		char *compressed = compressString(code);

		// Copy it to memory
		memseta(machine, CODE_START, (byte *) compressed, COMPRESSED_CODE_MAX_SIZE);

		// Write out cart data
		byte *data = memgeta(machine, 0x0, CART_SIZE);

		char* savepath = helper::concat(machine->fs->dir, name);

		fs::write(machine, savepath, (char *) data, RAM_SIZE);

		if(fs::exists(machine, savepath)){
			std::cout << "saved" << std::endl;
		}

		delete[] savepath;

		free(compressed);
		free(data);
	}

	void clean(neko_carts *carts) {
		delete carts;
	}
}
