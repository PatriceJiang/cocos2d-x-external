#!/bin/bash 

set -x

ANDROID_SDK=C:/Users/pt-win/AppData/Local/Android/Sdk
LUAJIT_ROOT=C:/Github/cocos2d-x-external/src/luajit
NDK_ROOT=C:/Users/pt-win/AppData/Local/Android/Sdk/ndk/20.0.5594570
CMAKE_DIR=$ANDROID_SDK/cmake/3.10.2.4988404/bin
MinGW64=C:/mingw-w64/x86_64-8.1.0-posix-seh-rt_v6-rev0/mingw64/bin

$CMAKE_DIR/cmake  \
--verbose=1 \
-H${LUAJIT_ROOT} \
-B${LUAJIT_ROOT}/android-build \
-GNinja \
-DANDROID_ABI=x86 \
-DLUAJIT_HOST_GENERATOR="MinGW Makefiles" \
-DLUAJIT_MinGW64_PATH=$MinGW64 \
-DANDROID_NDK=$NDK_ROOT \
-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LUAJIT_ROOT}/android-build/libs \
-DCMAKE_BUILD_TYPE=Debug \
-DCMAKE_MAKE_PROGRAM=$CMAKE_DIR/ninja \
-DCMAKE_TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake \
-DANDROID_NATIVE_API_LEVEL=23 \
-DANDROID_TOOLCHAIN=clang \



#-G"Android Gradle - Ninja" \