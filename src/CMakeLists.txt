cmake_minimum_required(VERSION 3.6)
project(external)

if(ANDROID)
    add_subdirectory(android-specific/cpufeatures)
    add_subdirectory(android-specific/pvmp3dec)
    add_subdirectory(android-specific/tremolo)
endif()

add_subdirectory(Box2D)
add_subdirectory(chipmunk)
add_subdirectory(freetype)
add_subdirectory(recast)
add_subdirectory(zlib)
add_subdirectory(bullet/src)
# add_subdirectory(curl)
# add_subdirectory(glfw)
add_subdirectory(jpeg)
add_subdirectory(lua)
# add_subdirectory(luajit)
# add_subdirectory(openssl) TODO: remove, replaced by libressl
add_subdirectory(libressl)
add_subdirectory(png)
add_subdirectory(rapidjson/lib)

set(BUILD_TESTING OFF)
add_subdirectory(uv)
add_subdirectory(webp)

## websockets options
set(LWS_WITH_SHARED OFF)
set(LWS_WITH_LIBUV ON)
set(LWS_WITHOUT_TESTAPPS ON)
set(LWS_LINK_TESTAPPS_DYNAMIC ON)
set(LWS_WITHOUT_TEST_SERVER ON)
set(LWS_WITHOUT_TEST_PING ON)
set(LWS_WITHOUT_TEST_ECHO ON)
set(LWS_WITHOUT_TEST_CLIENT ON)
set(LWS_WITHOUT_TEST_FRAGGLE ON)
set(LWS_STATIC_PIC ON)
## websockets paths
set(LIBUV_FOUND ON)
set(LWS_LIBUV_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/uv/include)
set(LWS_LIBUV_LIBRARIES $<TARGET_FILE:uv_a>)
set(OPENSSL_FOUND ON)
set(OPENSSL_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/libressl/include)
set(OPENSSL_LIBRARIES $<TARGET_FILE:crypto> $<TARGET_FILE:ssl>)
add_subdirectory(websockets)
if(TARGET websockets)
    add_dependencies(websockets uv_a ssl crypto)
endif()


add_library(external empty.cpp)

target_link_libraries(external
    Box2D
    chipmunk
    freetype
    recast
    zlib
    BulletSoftBody BulletCollision BulletDynamics LinearMath  # bullet
    # curl
    # glfw
    jpeg
    lua
    # luajit
    # openssl
    crypto ssl tls  # libressl
    png
    rapidjson
    uv_a
    webp
    websockets
)

if(ANDROID)
    target_link_libraries(external pvmp3dec tremolo)
endif()
