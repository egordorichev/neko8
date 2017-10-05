
include config.mk

INCLUDE:=$(INCLUDE) -I src -I libs/include -I libs/include/LuaJIT

SRCDIR=src
BIN=target/$(ARCH)-$(OS)-$(TARGET)
OBJDIR=$(BIN)/obj

CXXFILES:=$(CXXFILES) $(wildcard $(SRCDIR)/*.cpp)
CFILES:=$(CFILES) $(wildcard $(SRCDIR)/*.c)
OBJECTS:=$(OBJECTS) $(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%.cpp.o,$(CXXFILES)) $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.c.o,$(CFILES))

.PHONY: default build help mrproper clean

default: build

build: $(BINARY)

run: build
	./$(BINARY)

$(OBJDIR)/%.cpp.o: $(SRCDIR)/%.cpp
	@mkdir -p $(OBJDIR)
	$(CXX) $(INCLUDE) $(CFLAGS) $(CXXFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(INCLUDE) $(CFLAGS) -c -o $@ $<

$(BIN)/$(BINARY): $(OBJECTS) $(LIBS)
	@mkdir -p $(BIN)
	$(CXX) $(LDFLAGS) $(CFLAGS) $(CXXFLAGS) -o $@ $^
	@if [ "$(OS)" = "windows" ]; then cp libs/**/*.dll $(BIN)/; fi

$(BINARY): $(BIN)/$(BINARY)
	cp $(BIN)/$(BINARY) ./$(BINARY)
	@cp $(BIN)/*.dll ./

help:
	@echo "Available targets are:"
	@echo " default     - equivalent to build"
	@echo " build       - builds $(BINARY)"
	@echo " help        - shows this message"
	@echo " clean       - removes all built files, except for the executables"
	@echo " mrproper    - removes all built files"
	@echo "Available options are:"
	@echo " CC      - sets the target architecture"
	@echo " ARCH    - sets the target architecture"
	@echo " OS      - sets the target operating system (linux/windows/macos)"
	@echo " TARGET  - sets the target (debug/release)"

clean:
	rm -rf target/**/obj

mrproper: clean
	rm -rf target
	rm -f $(BINARY)
