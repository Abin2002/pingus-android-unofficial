# Patches

This directory contains the **modified source files** (not diffs).
To apply: replace the corresponding file in the upstream source tree.

## sdl12-compat: `SDL12_compat.c`

Upstream: https://github.com/libsdl-org/sdl12-compat

Android-specific changes:
1. **dlopen fallback**: `LoadSDL20Library()` falls back to `libSDL2.so`
   (was only trying desktop `libSDL2-2.0.so.0`).
2. **Texture format**: 32bpp app format forced to `SDL_PIXELFORMAT_RGBX32`
   (not XRGB8888); texture created as `RGBX32` to avoid YUV conversion crash.
3. **EGL fix**: `UnlockVideoRenderer()` skips `SDL_GL_MakeCurrent(NULL,NULL)`
   on Android (`ANDROID`/`__ANDROID__` guard) — fixes `editable == nullptr`
   assertion on Android 12.
4. **Force 32-bit**: `appfmt` always `RGBX32` regardless of requested bpp
   (Pingus requests 16-bit, which caused image duplication).
5. **Texture upload**: `SDL_UpdateRects` uses `SDL_UpdateTexture` instead of
   `LockTexture`/`memcpy`/`UnlockTexture` (GLES2 lock path returns invalid
   `pixel_data` on some devices).
6. **Input**: FINGER events dropped entirely from SDL2's queue (return 0,
   not 1) to prevent swipe flooding; synthetic MOUSEMOTION from touch
   dropped; one MOTION synthesized on BUTTONDOWN for button hover state.
7. **Audio**: `SDL_AUDIODRIVER=opensles` (default driver CFI-crashes on
   Android 12; dummy driver is silent).
8. **Orientation**: `setOrientationBis()` overridden in PingusActivity to
   force `SCREEN_ORIENTATION_SENSOR_LANDSCAPE` (SDL2 overrides manifest).
9. **Keyboard**: `windowSoftInputMode="stateAlwaysHidden"` + `onWindowFocusChanged`
   and `onResume` hide the soft keyboard (game needs no text input).

## SDL2: `SDL_render_gles2.c`

Upstream: https://github.com/libsdl-org/SDL (branch release-2.32.x)

Change: `texture_formats[0]` set to `SDL_PIXELFORMAT_RGBX32` (was YV12).
The Android GLES2 renderer only listed YUV formats first, which sdl12-compat
picked, causing a segfault (no RGB→YUV blit in SDL2).

## Pingus 0.7.6

Upstream: https://github.com/Grumbel/pingus (v0.7.6)

- `src/pingus/main.cpp`: `extern "C"` on `main` for SDL_main.
- `src/engine/display/display.cpp`: added missing
  `#include "util/raise_exception.hpp"`.
- `src/lisp/getters.hpp`: two `shared_ptr::get()` fixes.
- `src/engine/display/sdl_framebuffer.cpp`: (no change, for reference)
- New: `img_shim.c` bridges `IMG_Load` and `Mix_GetError` to SDL2.
