#!/bin/bash
# Build SDL2 + satellites + sdl12-compat for Android arm64
set -e
ROOT="/home/hatch/workspace/pingus-apk"
NDK="$ROOT/android-sdk/ndk/27.0.12077973"
ABI=arm64-v8a
API=21
PREFIX="$ROOT/build-arm64"
TOOLCHAIN="$NDK/build/cmake/android.toolchain.cmake"
JOBS=2

export JAVA_HOME="$ROOT/jdk17"
export PATH="$JAVA_HOME/bin:$PATH"

common="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN -DANDROID_ABI=$ABI -DANDROID_PLATFORM=android-$API \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_SHARED_LIBS=ON"

echo "=== SDL2 ==="
cmake -S "$ROOT/SDL2" -B "$ROOT/bld/SDL2" $common \
  -DSDL_TESTS=OFF -DSDL_TEST_LIBRARY=OFF > /tmp/cmake-sdl2.log 2>&1
cmake --build "$ROOT/bld/SDL2" -j$JOBS >> /tmp/cmake-sdl2.log 2>&1
cmake --install "$ROOT/bld/SDL2" >> /tmp/cmake-sdl2.log 2>&1

SDL2LOC="-DSDL2_LIBRARY=$PREFIX/lib/libSDL2.so -DSDL2_INCLUDE_DIR=$PREFIX/include/SDL2"

echo "=== SDL2_image (stb backend: PNG+JPEG, no external deps) ==="
cmake -S "$ROOT/SDL2_image" -B "$ROOT/bld/SDL2_image" $common $SDL2LOC \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DSDL2IMAGE_BACKEND_STB=ON \
  -DSDL2IMAGE_AVIF=OFF -DSDL2IMAGE_JXL=OFF -DSDL2IMAGE_SVG=OFF \
  -DSDL2IMAGE_TIF=OFF -DSDL2IMAGE_WEBP=OFF \
  -DSDL2IMAGE_SAMPLES=OFF > /tmp/cmake-sdl2image.log 2>&1
cmake --build "$ROOT/bld/SDL2_image" -j$JOBS >> /tmp/cmake-sdl2image.log 2>&1
cmake --install "$ROOT/bld/SDL2_image" >> /tmp/cmake-sdl2image.log 2>&1

echo "=== SDL2_mixer (WAVE + tracker MOD via vendored libxmp + minimp3) ==="
cmake -S "$ROOT/SDL2_mixer" -B "$ROOT/bld/SDL2_mixer" $common $SDL2LOC \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DSDL2MIXER_VENDORED=ON \
  -DSDL2MIXER_CMD=OFF \
  -DSDL2MIXER_FLAC=OFF -DSDL2MIXER_GME=OFF \
  -DSDL2MIXER_MOD=ON -DSDL2MIXER_MOD_XMP=ON -DSDL2MIXER_MOD_XMP_SHARED=OFF \
  -DSDL2MIXER_MP3=ON -DSDL2MIXER_MP3_MINIMP3=ON \
  -DSDL2MIXER_MIDI=OFF -DSDL2MIXER_OPUS=OFF -DSDL2MIXER_VORBIS="" \
  -DSDL2MIXER_WAVPACK=OFF -DSDL2MIXER_FLAC=OFF \
  -DSDL2MIXER_WAVE=ON \
  -DSDL2MIXER_SAMPLES=OFF > /tmp/cmake-sdl2mixer.log 2>&1
cmake --build "$ROOT/bld/SDL2_mixer" -j$JOBS >> /tmp/cmake-sdl2mixer.log 2>&1
cmake --install "$ROOT/bld/SDL2_mixer" >> /tmp/cmake-sdl2mixer.log 2>&1

echo "=== sdl12-compat ==="
cmake -S "$ROOT/sdl12-compat" -B "$ROOT/bld/sdl12-compat" $common $SDL2LOC \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DSDL12TESTS=OFF -DSDL12DEVEL=ON > /tmp/cmake-sdl12.log 2>&1
cmake --build "$ROOT/bld/sdl12-compat" -j$JOBS >> /tmp/cmake-sdl12.log 2>&1
cmake --install "$ROOT/bld/sdl12-compat" >> /tmp/cmake-sdl12.log 2>&1

echo "=== ALL LIBS DONE ==="
ls "$PREFIX/lib"
