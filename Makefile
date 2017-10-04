
include config.mk

INCLUDE:=$(INCLUDE) -I src -I libs/include -I libs/include/LuaJIT
LDFLAGS:=$(LDFLAGS) $(shell sdl2-config --libs) -lluajit-5.1
CFLAGS:=$(CFLAGS) $(shell sdl2-config --cflags)

SRCDIR=src
BIN=target/$(ARCH)-$(OS)-$(TARGET)
OBJDIR=$(BIN)/obj

SRC:=$(SRC) $(shell find $(SRCDIR) -type f -name '*.cpp')
OBJECTS:=$(OBJECTS) $(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%.cpp.o,$(SRC)) $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.c.o,$(SRC))

.PHONY: default build help mrproper clean

default: build

build: $(BINARY)

run: build
	./$(BINARY)

$(OBJDIR)/%.cpp.o: $(SRCDIR)/%.cpp
	@mkdir -p $(OBJDIR)
	$(CXX) $(INCLUDE) $(CFLAGS) $(CXXFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.o: $(SRCDIR)/%.cpp
	@mkdir -p $(OBJDIR)
	$(CC) $(INCLUDE) $(CFLAGS) -c -o $@ $<

$(BIN)/$(BINARY): $(OBJECTS)
	@mkdir -p $(BIN)
	$(CXX) $(LDFLAGS) $(CFLAGS) $(CXXFLAGS) -o $@ $< $(LIBS)

$(BINARY): $(BIN)/$(BINARY)
	cp $(BIN)/$(BINARY) $(BINARY)

help:
	@echo "Available targets are:"
	@echo " default 	- equivalent to build"
	@echo " build 		- builds $(BINARY)"
	@echo " help 		- shows this message"
	@echo " clean 		- removes all files, except for the executables"
	@echo " mrproper 	- removes all files"
	@echo "Available options are:"
	@echo " ARCH 	- sets the target architecture"
	@echo " OS 		- sets the target operating system"
	@echo " TARGET 	- sets the target (debug/release)"

clean:
	rm -rf target/**/obj

mrproper: clean
	rm -rf target
	rm -f $(BINARY)
