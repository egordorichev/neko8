#include <api.hpp>
#include <iostream>
#include <vector>

neko *machine; // Lil hack :P

static int cls(lua_State *state) {
	api::cls(machine, luaL_checkinteger(state, 1));
	return 0;
}

static int pset(lua_State *state) {
	s32 x = luaL_checkinteger(state, 1);
	s32 y = luaL_checkinteger(state, 2);
	s32 c = luaL_checkinteger(state, 3);

	api::pset(machine, x, y, c);

	return 0;
}

static int pget(lua_State *state) {
	s32 x = luaL_checkinteger(state, 1);
	s32 y = luaL_checkinteger(state, 2);

	lua_pushnumber(state, api::pget(machine, x, y));

	return 1;
}

std::vector<luaL_Reg> luaAPI = {
	{ "cls", cls },
	{ "pset", pset },
	{ "pget", pget }
};

LUALIB_API int defineLuaAPI(neko *n, lua_State *state) {
	machine = n;

	for (auto fn : luaAPI) {
		lua_pushcfunction(state, fn.func);
		lua_setglobal(state, fn.name);
	}

	return 1;
}