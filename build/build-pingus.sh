#!/bin/bash
# Cross-compile Pingus 0.7.6 for Android arm64 -> libmain.so
set -e
ROOT="/home/hatch/workspace/pingus-apk"
SRC="$ROOT/pingus-src"
NDK="$ROOT/android-sdk/ndk/27.0.12077973"
PREFIX="$ROOT/build-arm64"
TARGET=aarch64-linux-android21
TC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
JOBS=2
BLD="$ROOT/bld/pingus"
mkdir -p "$BLD/obj"

# ---- collect sources (mirrors SConscript globs, minus desktop-only parts) ----
SRCS=""
add_glob() { for f in $1; do if [ -f "$f" ]; then SRCS="$SRCS $f"; fi; done; }
cd "$SRC"
add_glob "external/tinygettext/tinygettext/*.cpp"
add_glob "external/logmich/src/*.cpp"
add_glob "src/editor/*.cpp"
for d in display display/delta gui input resource screen sound system; do
  add_glob "src/engine/$d/*.cpp"
done
add_glob "src/lisp/*.cpp"
add_glob "src/math/*.cpp"
for d in pingus pingus/actions pingus/colliders pingus/components pingus/movers \
         pingus/particles pingus/screens pingus/worldmap pingus/worldobjs util; do
  add_glob "src/$d/*.cpp"
done
SRCS="$SRCS src/main.cpp"
echo "$SRCS" | tr ' ' '\n' | grep -c cpp | xargs echo "source files:"

# shim-include FIRST: our 1.2-API SDL_image.h/SDL_mixer.h shadow the SDL2 ones;
# include/SDL provides the sdl12-compat 1.2 headers (<SDL.h> etc.).
# NOTE: $PREFIX/include/SDL2 is deliberately absent so no SDL2 header can
# leak into a Pingus translation unit and clash with the 1.2 types.
INCLUDES="-I$ROOT/shim-include -I$PREFIX/include/SDL -I$ROOT/libpng -I$ROOT/bld/libpng \
  -I$SRC/src -I$SRC/external/tinygettext -I$SRC/external/logmich/include -I$ROOT"
DEFINES='-DVERSION="0.7.6" -DHAVE_SDL -Dmain=SDL_main'
CXXFLAGS="--target=$TARGET -fPIC -O2 -std=c++11 -ffunction-sections -fdata-sections \
  -fno-strict-aliasing -fexceptions -frtti $INCLUDES $DEFINES"

# ---- compile (parallel) ----
echo "$SRCS" | tr ' ' '\n' | grep '\.cpp$' > "$BLD/sources.txt"
export SRC BLD TC CXXFLAGS
compile_one() {
  src="$1"
  obj="$BLD/obj/$(echo "$src" | sed 's|/|_|g').o"
  if [ ! -f "$obj" ] || [ "$SRC/$src" -nt "$obj" ]; then
    # shellcheck disable=SC2086
    "$TC/clang++" $CXXFLAGS -c "$SRC/$src" -o "$obj" 2> "$obj.err" || { echo "FAILED: $src"; head -25 "$obj.err"; return 1; }
  fi
}
export -f compile_one
< "$BLD/sources.txt" xargs -P "$JOBS" -I{} bash -c 'compile_one "$@"' _ {} || exit 1
OBJS=""
while read -r s; do OBJS="$OBJS $BLD/obj/$(echo "$s" | sed 's|/|_|g').o"; done < "$BLD/sources.txt"
echo "compiled $(echo "$OBJS" | wc -w) objects"

# ---- img shim (C) ----
"$TC/clang" --target=$TARGET -fPIC -O2 -I$PREFIX/include/SDL -c "$ROOT/img_shim.c" -o "$BLD/obj/img_shim.o"
"$TC/clang" --target=$TARGET -fPIC -O2 -g -I$ROOT -c "$ROOT/debug_hook.c" -o "$BLD/obj/debug_hook.o"

# ---- link ----
"$TC/clang++" --target=$TARGET -shared -o "$BLD/libmain.so" $OBJS "$BLD/obj/img_shim.o" "$BLD/obj/debug_hook.o" \
  "$ROOT/bld/libpng/libpng18.a" -L$PREFIX/lib -lSDL2_image -lSDL2_mixer -lSDL -lSDL2 \
  -llog -landroid -ldl -lm -lz -Wl,--gc-sections
echo "=== libmain.so ==="
ls -la "$BLD/libmain.so"
"$TC/llvm-nm" -D "$BLD/libmain.so" | grep -w SDL_main | head -2
