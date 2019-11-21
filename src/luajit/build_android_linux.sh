#!/bin/bash

set -x

ANDROID_SDK=$ANDROID_SDK_ROOT
LUAJIT_ROOT=/home/jiang/Github/cocos2d-x-external/src/luajit
NDK_ROOT=$ANDROID_NDK_HOME
CMAKE_DIR=$ANDROID_SDK/cmake/3.6.4111459/bin/

rm -rf ${LUAJIT_ROOT}/android-build

$CMAKE_DIR/cmake  \
--verbose=1 \
-H${LUAJIT_ROOT} \
-B${LUAJIT_ROOT}/android-build \
-GNinja \
-DANDROID_ABI=arm64-v8a \
-DANDROID_NDK=$NDK_ROOT \
-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LUAJIT_ROOT}/android-build/libs \
-DCMAKE_BUILD_TYPE=Debug \
-DCMAKE_MAKE_PROGRAM=$CMAKE_DIR/ninja \
-DCMAKE_TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake \
-DANDROID_NATIVE_API_LEVEL=23 \
-DANDROID_TOOLCHAIN=clang \



#-G"Android Gradle - Ninja" \