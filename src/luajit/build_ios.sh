#!/bin/bash 

set -x

LUAJIT_ROOT=/Users/cocos/Github/cocos2d-x-external/src/luajit


cmake  \
--verbose=1 \
-H${LUAJIT_ROOT} \
-B${LUAJIT_ROOT}/ios-build \
-GXcode \
-DCMAKE_SYSTEM_NAME=iOS \
-DCMAKE_OSX_ARCHITECTURES="arm64"


## armv7;armv7s;arm64;i386;x86_64



