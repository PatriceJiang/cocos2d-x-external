#!/bin/bash 

set -x

ANDROID_SDK=C:/Users/pt-win/AppData/Local/Android/Sdk
BUILD_SRC=C:/Github/cocos2d-x-external/src
#BUILD_SRC=C:/Github/cocos2d-x-external/src/libressl
NDK_ROOT=C:/Users/pt-win/AppData/Local/Android/Sdk/ndk/20.0.5594570
CMAKE_DIR=$ANDROID_SDK/cmake/3.10.2.4988404/bin

## remove & rebuild
rm -rf ${BUILD_SRC}/all-build

BUILD_DIR=$BUILD_SRC/all-build

$CMAKE_DIR/cmake  \
--verbose=1 \
-H${BUILD_SRC} \
-B${BUILD_DIR} \
-GNinja \
-DANDROID_ABI=armeabi-v7a \
-DANDROID_NDK=$NDK_ROOT \
-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${BUILD_DIR}/libs \
-DCMAKE_BUILD_TYPE=Debug \
-DCMAKE_MAKE_PROGRAM=$CMAKE_DIR/ninja \
-DCMAKE_TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake \
-DANDROID_NATIVE_API_LEVEL=23 \
-DANDROID_TOOLCHAIN=clang \

echo "run-build:
$CMAKE_DIR/cmake --build $BUILD_DIR"