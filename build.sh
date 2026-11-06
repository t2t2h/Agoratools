#!/bin/bash
# ===================================================================
# build.sh — بناء AgoraBoost.dylib مباشرة بـ clang (بدون Theos/Substrate)
# شغّل السكريبت ده على ماك فيه Xcode Command Line Tools مُثبتة.
# ===================================================================
set -e

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
OUT="AgoraBoost.dylib"

echo "==> بناء AgoraBoost.dylib للمعمارية arm64 و arm64e ..."

clang -dynamiclib \
    -arch arm64 -arch arm64e \
    -isysroot "$SDK_PATH" \
    -miphoneos-version-min=14.0 \
    -fobjc-arc \
    -framework Foundation \
    -framework CoreGraphics \
    -install_name "@executable_path/Frameworks/AgoraBoost.dylib" \
    AgoraBoost.m \
    -o "$OUT"

echo "==> توقيع مبدئي ad-hoc للدايلب ..."
codesign -f -s - "$OUT"

echo "==> تم! الملف الناتج: $OUT"
echo "    دلوقتي اتبع خطوات الحقن (injection) الموجودة في README.md"
