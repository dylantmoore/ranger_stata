# Makefile for ranger_plugin (C++ wrapper around ranger library)
#
# Targets:
#   all            - Build for local platform (darwin-arm64)
#   darwin         - Build for macOS Apple Silicon (arm64)
#   windows        - Cross-compile for Windows x86_64 (requires mingw-w64)
#   linux          - Cross-compile for Linux x86_64 (requires Linux or cross-compiler)
#   all-platforms  - Build all three targets
#   clean          - Remove all built plugins

VENDOR_RANGER = vendor/ranger

INCLUDES = -I$(VENDOR_RANGER) -I. -Wno-deprecated-declarations

# All ranger C++ source files (excluding R-specific and DataSparse)
RANGER_SRCS = \
    $(VENDOR_RANGER)/Data.cpp \
    $(VENDOR_RANGER)/Forest.cpp \
    $(VENDOR_RANGER)/ForestClassification.cpp \
    $(VENDOR_RANGER)/ForestProbability.cpp \
    $(VENDOR_RANGER)/ForestRegression.cpp \
    $(VENDOR_RANGER)/ForestSurvival.cpp \
    $(VENDOR_RANGER)/Tree.cpp \
    $(VENDOR_RANGER)/TreeClassification.cpp \
    $(VENDOR_RANGER)/TreeProbability.cpp \
    $(VENDOR_RANGER)/TreeRegression.cpp \
    $(VENDOR_RANGER)/TreeSurvival.cpp \
    $(VENDOR_RANGER)/utility.cpp

# Plugin source
PLUGIN_SRC = ranger_plugin.cpp

# stplugin.c — compiled as C separately per platform (different -D flags)
STPLUGIN_SRC = stplugin.c

# Output filenames
TARGET_DARWIN  = ranger_plugin.darwin-arm64.plugin
TARGET_WINDOWS = ranger_plugin.windows-x86_64.plugin
TARGET_LINUX   = ranger_plugin.linux-x86_64.plugin

# ── Darwin (macOS arm64) ─────────────────────────────────────────────
DARWIN_CXX    = g++
DARWIN_CC     = gcc
DARWIN_CXXFLAGS = -std=c++14 -O3 -fPIC -DSYSTEM=APPLEMAC -arch arm64 $(INCLUDES)
DARWIN_CFLAGS   = -O3 -fPIC -DSYSTEM=APPLEMAC -arch arm64 -I.
DARWIN_LDFLAGS  = -bundle -lpthread

# ── Windows (x86_64, cross-compiled with mingw-w64) ─────────────────
WIN_CXX    = x86_64-w64-mingw32-g++
WIN_CC     = x86_64-w64-mingw32-gcc
WIN_CXXFLAGS = -std=c++14 -O3 -DSYSTEM=STWIN32 $(INCLUDES)
WIN_CFLAGS   = -O3 -DSYSTEM=STWIN32 -I.
WIN_LDFLAGS  = -shared -static-libstdc++ -static-libgcc -lpthread

# ── Linux (x86_64) ──────────────────────────────────────────────────
LINUX_CXX    = g++
LINUX_CC     = gcc
LINUX_CXXFLAGS = -std=c++14 -O3 -fPIC -DSYSTEM=OPUNIX $(INCLUDES)
LINUX_CFLAGS   = -O3 -fPIC -DSYSTEM=OPUNIX -I.
LINUX_LDFLAGS  = -shared -static-libstdc++ -static-libgcc -lpthread

# ── Phony targets ───────────────────────────────────────────────────
.PHONY: all darwin windows linux all-platforms clean

# Default: build for the local platform only
all: darwin

darwin: $(TARGET_DARWIN)
windows: $(TARGET_WINDOWS)
linux: $(TARGET_LINUX)
all-platforms: darwin windows linux

# ── Build rules ─────────────────────────────────────────────────────

# Darwin — compile stplugin.c as C, then link everything as C++
$(TARGET_DARWIN): $(PLUGIN_SRC) $(RANGER_SRCS) $(STPLUGIN_SRC)
	$(DARWIN_CC) $(DARWIN_CFLAGS) -c $(STPLUGIN_SRC) -o stplugin.darwin.o
	$(DARWIN_CXX) $(DARWIN_CXXFLAGS) $(DARWIN_LDFLAGS) -o $@ $(PLUGIN_SRC) $(RANGER_SRCS) stplugin.darwin.o
	rm -f stplugin.darwin.o

# Windows — compile stplugin.c as C with mingw, then link everything as C++
$(TARGET_WINDOWS): $(PLUGIN_SRC) $(RANGER_SRCS) $(STPLUGIN_SRC)
	$(WIN_CC) $(WIN_CFLAGS) -c $(STPLUGIN_SRC) -o stplugin.windows.o
	$(WIN_CXX) $(WIN_CXXFLAGS) $(WIN_LDFLAGS) -o $@ $(PLUGIN_SRC) $(RANGER_SRCS) stplugin.windows.o
	rm -f stplugin.windows.o

# Linux — compile stplugin.c as C, then link everything as C++
$(TARGET_LINUX): $(PLUGIN_SRC) $(RANGER_SRCS) $(STPLUGIN_SRC)
	$(LINUX_CC) $(LINUX_CFLAGS) -c $(STPLUGIN_SRC) -o stplugin.linux.o
	$(LINUX_CXX) $(LINUX_CXXFLAGS) $(LINUX_LDFLAGS) -o $@ $(PLUGIN_SRC) $(RANGER_SRCS) stplugin.linux.o
	rm -f stplugin.linux.o

clean:
	rm -f $(TARGET_DARWIN) $(TARGET_WINDOWS) $(TARGET_LINUX)
	rm -f stplugin.darwin.o stplugin.windows.o stplugin.linux.o
