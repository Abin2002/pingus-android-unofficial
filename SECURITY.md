# Security Policy

## Supported Versions

This is an unofficial community port. Security updates are best-effort.

| Version | Supported |
|---------|-----------|
| 0.7.6-android (latest) | Yes |
| Older debug builds | No |

## Reporting a Vulnerability

If you find a security issue in the Android-specific code (the files in
`android/`, `build/`, or the documented patches in `patches/`), please
open a GitHub issue with the `security` label. Do not include exploits.

For vulnerabilities in the upstream projects (Pingus, SDL2, sdl12-compat,
SDL2_image, SDL2_mixer), please report them to those projects directly —
this port only repackages their code:

- Pingus: https://github.com/Grumbel/pingus
- SDL2 / sdl12-compat / SDL2_image / SDL2_mixer: https://github.com/libsdl-org

## Scope Notes

- The app requests **no Android permissions** and declares no network
  access. It is an offline single-player game.
- Release APKs are signed with a private release key. Debug-signed builds
  (from `build/build-apk.sh` without `--release`) are for local testing
  only and must not be distributed.
- The release keystore and its passwords are never committed to this
  repository.
