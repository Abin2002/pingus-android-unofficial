# Pingus Android — Unofficial Port

An unofficial Android port of **Pingus 0.7.6**, the free Lemmings clone.

**Original game:** Pingus by Ingo Ruhnke and contributors
([pingus.seul.org](https://pingus.seul.org), GitHub: Grumbel/pingus)
**License:** GNU GPL v3 (see COPYING)

This is a **community port, not affiliated with the Pingus developers**.
All credit for the game goes to them. This repo contains the Android
build scripts and the source patches needed to cross-compile Pingus
for Android (arm64).

## What this is

- Pingus 0.7.6 (C++, SDL 1.2) running on Android via:
  - **sdl12-compat** (SDL 1.2 API on top of SDL2)
  - **SDL2** + SDL2_image + SDL2_mixer
  - Android NDK r27, arm64-v8a, minSdk 21
- Touch taps act as mouse clicks
- Game data bundled in the APK, extracted on first launch

## Patches

The `patches/` directory documents every change made to upstream sources:

| File | Upstream | Change |
|------|----------|--------|
| `sdl12-compat-SDL12_compat.c` | sdl12-compat | Android fixes: libSDL2.so dlopen fallback, RGBX32 texture format, skip GL context release on Android, force 32-bit, SDL_UpdateTexture path, drop FINGER events, synthetic motion handling |
| `SDL2-SDL_render_gles2.c` | SDL2 | List RGBX32 first in texture formats |
| `pingus-main.cpp` etc. | Grumbel/pingus 0.7.6 | SDL_main C linkage, missing includes, shared_ptr fixes |

See `patches/README.md` for the full list.

## Building

Requires: Android NDK r27, JDK 17, ~4GB disk.

1. Fetch upstream sources (see `fetch-sources.sh` for exact versions)
2. Apply patches from `patches/`
3. Run `./build-libs.sh`, `./build-pingus.sh`, `./build-apk.sh`

See `BUILDING.md` for details.

## License

This port is released under the **GNU General Public License v3**,
the same as Pingus itself. See COPYING.
