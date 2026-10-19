#!/bin/bash
# Package the Pingus Android port into a signed APK (manual toolchain, no gradle)
set -e
ROOT="/home/hatch/workspace/pingus-apk"
SDK="$ROOT/android-sdk"
BT="$SDK/build-tools/34.0.0"
AJAR="$SDK/platforms/android-34/android.jar"
APKDIR="$ROOT/apk"
OUT="$ROOT/out"
export JAVA_HOME="$ROOT/jdk17"
export PATH="$JAVA_HOME/bin:$PATH"

rm -rf "$OUT"
mkdir -p "$OUT/classes" "$OUT/libs/arm64-v8a"

echo "=== javac ==="
find "$APKDIR/java" -name "*.java" > "$OUT/sources.txt"
javac -encoding UTF-8 --release 8 -classpath "$AJAR" -d "$OUT/classes" @"$OUT/sources.txt" 2>&1 | grep -v "bootstrap\|deprecat" | head -5 || true

echo "=== d8 ==="
"$BT/d8" --min-api 21 --lib "$AJAR" --output "$OUT" $(find "$OUT/classes" -name "*.class" | tr '\n' ' ') 2>&1 | head -3 || true
ls "$OUT/classes.dex"

echo "=== aapt2 compile/link ==="
"$BT/aapt2" compile --dir "$APKDIR/res" -o "$OUT/res.zip"
"$BT/aapt2" link -o "$OUT/base.apk" \
  -I "$AJAR" \
  --manifest "$APKDIR/AndroidManifest.xml" \
  -A "$APKDIR/assets" \
  "$OUT/res.zip" \
  --java "$OUT/gen" \
  --min-sdk-version 21 --target-sdk-version 34 \
  --version-code 1 --version-name "0.7.6"

echo "=== add native libs ==="
mkdir -p "$OUT/stage/lib/arm64-v8a"
cp "$ROOT/bld/pingus/libmain.so" "$OUT/stage/lib/arm64-v8a/"
cp "$ROOT/build-arm64/lib/libSDL2.so" "$OUT/stage/lib/arm64-v8a/"
cp "$ROOT/build-arm64/lib/libSDL.so" "$OUT/stage/lib/arm64-v8a/"
cp "$ROOT/build-arm64/lib/libSDL2_image.so" "$OUT/stage/lib/arm64-v8a/"
cp "$ROOT/build-arm64/lib/libSDL2_mixer.so" "$OUT/stage/lib/arm64-v8a/"
cp "$SDK/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "$OUT/stage/lib/arm64-v8a/"
(cd "$OUT/stage" && zip -q -r -0 "$OUT/base.apk" lib)
(cd "$OUT" && zip -q -j "$OUT/base.apk" classes.dex)

echo "=== zipalign + sign ==="
"$BT/zipalign" -f 4 "$OUT/base.apk" "$OUT/pingus-aligned.apk"
if [ ! -f "$ROOT/debug.keystore" ]; then
  keytool -genkeypair -keystore "$ROOT/debug.keystore" -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10950 -storepass android \
    -keypass android -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
fi
"$BT/apksigner" sign --ks "$ROOT/debug.keystore" --ks-pass pass:android \
  --key-pass pass:android --out "$OUT/pingus.apk" "$OUT/pingus-aligned.apk"
"$BT/apksigner" verify --print-certs "$OUT/pingus.apk" | head -3
ls -la "$OUT/pingus.apk"
