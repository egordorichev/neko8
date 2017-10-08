set(prefix "/usr/i686-w64-mingw32") 
set(exec_prefix "${prefix}")
set(libdir "/usr/i686-w64-mingw32/lib")
set(SDL2_PREFIX "/usr/i686-w64-mingw32")
set(SDL2_EXEC_PREFIX "/usr/i686-w64-mingw32")
set(LIBDIR "/usr/i686-w64-mingw32/lib")
set(SDL2_INCLUDE_DIRS "/usr/i686-w64-mingw32/include/SDL2")
set(SDL2_LIBRARIES "-L${LIBDIR}  -lmingw32 -lSDL2main -lSDL2  -mwindows")
set(SDL2_LIBRARY "-L${LIBDIR}  -lmingw32 -lSDL2main -lSDL2  -mwindows")
string(STRIP "${SDL2_LIBRARIES}" SDL2_LIBRARIES)


set(LUAJIT_LIBRARIES "-lluajit")

SET(CMAKE_SYSTEM_NAME Windows)

SET(CMAKE_C_COMPILER i686-w64-mingw32-gcc)
SET(CMAKE_CXX_COMPILER i686-w64-mingw32-g++)