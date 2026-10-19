#!/bin/bash
# Fetch the exact upstream sources used by this port.
# Run from the repository root: ./fetch-sources.sh
#
# After fetching, apply the patched files from patches/ over the
# corresponding upstream files (see patches/README.md), then run
# build/build-libs.sh, build/build-pingus.sh, build/build-apk.sh.
set -euo pipefail

echo "=== SDL2 (release-2.32.x) ==="
git clone --depth 1 --branch release-2.32.x \
  https://github.com/libsdl-org/SDL.git SDL2

echo "=== SDL2_image (SDL2 branch, STB backend) ==="
git clone --depth 1 --branch SDL2 \
  https://github.com/libsdl-org/SDL_image.git SDL2_image

echo "=== SDL2_mixer (SDL2 branch, vendored libxmp) ==="
git clone --depth 1 --branch SDL2 \
  https://github.com/libsdl-org/SDL_mixer.git SDL2_mixer

echo "=== sdl12-compat (main) ==="
git clone --depth 1 \
  https://github.com/libsdl-org/sdl12-compat.git sdl12-compat

echo "=== Pingus 0.7.6 ==="
git clone --depth 1 --branch v0.7.6 \
  https://github.com/Grumbel/pingus.git pingus-src
# If the tag does not exist upstream, use the 0.7.6 release tarball:
#   curl -L -o pingus-0.7.6.tar.gz \
#     https://github.com/Grumbel/pingus/archive/refs/tags/v0.7.6.tar.gz

echo "=== Android NDK r27 ==="
echo "Download from https://developer.android.com/ndk/downloads"
echo "Expected version: 27.0.12077973"
echo "Place under android-sdk/ndk/ (see build scripts for layout)."

echo "=== Android SDK pieces ==="
echo "  platform:      android-34"
echo "  build-tools:   34.0.0"
echo "  JDK:           Temurin 17 (https://adoptium.net)"

echo "=== Other ==="
echo "  Boost headers 1.86 (https://www.boost.org)"
echo "  libpng (static, for screenshot.cpp)"

echo ""
echo "Done. Now copy the files from patches/ over the matching upstream"
echo "files (see patches/README.md), then build."
