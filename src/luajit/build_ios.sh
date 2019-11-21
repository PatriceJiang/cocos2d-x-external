#!/bin/bash 

set -x

LUAJIT_ROOT=/Users/cocos/Github/cocos2d-x-external/src/luajit

rm -rf ${LUAJIT_ROOT}/ios-build 

cmake  \
-H${LUAJIT_ROOT} \
-B${LUAJIT_ROOT}/ios-build \
-GXcode \
-DCMAKE_SYSTEM_NAME=iOS \
-DCMAKE_OSX_SYSROOT=iphoneos \
-DCMAKE_C_FLAGS="-miphoneos-version-min=8.0" \
-DCMAKE_OSX_DEPLOYMENT_TARGET=9.3 \
-DCMAKE_OSX_ARCHITECTURES="armv7" \



#-DLUAJIT_IOS_ARCH="arm64" \
## armv7;armv7s;arm64;i386;x86_64
#-DCMAKE_OSX_ARCHITECTURES="armv7" \



