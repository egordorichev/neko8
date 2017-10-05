STD=c++14

NAME=neko8
VERSION=0.0.6
BINARY=$(NAME).$(VERSION)

ifndef ARCH
ARCH=x86-64
endif

ifndef OS
OS=linux
endif

ifndef TARGET
TARGET=debug
endif

CFLAGS:=$(CFLAGS) -std=$(STD) -march=$(ARCH)

ifeq ($(TARGET),debug)
CFLAGS:=$(CFLAGS) -O0 -Wall -DDEBUG
endif

ifeq ($(TARGET),release)
CFLAGS:=$(CFLAGS) -O2 -DNDEBUG
endif

ifeq ($(OS),linux)
LDFLAGS:=$(LDFLAGS) $(shell sdl2-config --cflags) $(shell sdl2-config --libs) -lluajit-5.1
CFLAGS:=$(CFLAGS) $(shell sdl2-config --cflags) $(shell sdl2-config --libs) -w
endif

ifeq ($(OS),macos)
LDFLAGS:=$(LDFLAGS) $(shell sdl2-config --libs) -lluajit-5.1
CFLAGS:=$(CFLAGS) $(shell sdl2-config --cflags) -w
endif

ifeq ($(OS),windows)
BINARY:=$(BINARY).exe
LIBS:=$(LIBS) $(wildcard libs/**/*.lib)
CFLAGS:=$(CFLAGS) -w -D_REENTRANT
endif