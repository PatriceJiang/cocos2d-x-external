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
add_subdirectory(libressl)

set(CURL_ENABLE_DEBUG OFF CACHE BOOL "force set" FORCE)
set(CURL_ENABLE_CURLDEBUG OFF CACHE BOOL "force set" FORCE)
set(CURL_ENABLE_MANUAL OFF CACHE BOOL "force set" FORCE)
set(CMAKE_USE_OPENSSL ON CACHE BOOL "force set" FORCE)
set(CURL_BUILD_TESTING OFF CACHE BOOL "force set" FORCE)
set(CURL_BUILD_CURL_EXE OFF CACHE BOOL "force set" FORCE)
set(CURL_STATICLIB ON CACHE BOOL "force set" FORCE)
#if(NOT WIN32)
    set(CURL_OPENSSL_FOUND ON)
    set(CURL_OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/libressl/include)
    if(TARGET ssl AND TARGET crypto)
        #set(CURL_OPENSSL_LIBRARIES "$<TARGET_FILE:ssl>" "$<TARGET_FILE:crypto>")
        set(CURL_OPENSSL_LIBRARIES ssl crypto)
    else()
        message(FATAL_ERROR "Target ssl or crypto is not found!")
    endif()
# endif()
add_subdirectory(curl)
#if(NOT WIN32)
    add_dependencies(libcurl crypto ssl)
#endif()

# set(CMAKE_C_FLAGS "-g -DANDROID -fdata-sections -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -fno-addrsig -march=armv7-a -mthumb -Wa,--noexecstack -Wformat -Werror=format-security")
# include(CheckCSourceCompiles)
# file(READ test.c TEST_CODE)
# check_c_source_compiles("${TEST_CODE}" test_xxx)
# if(NOT test_xxx)
#     message(FATAL_ERROR "failed to compile test.c")
# endif()

# add_executable(xxx test.c)
# add_custom_command(TARGET xxx POST_BUILD
#     COMMAND ${CMAKE_COMMAND} -E echo "build done!"
# )


# add_subdirectory(glfw)
add_subdirectory(jpeg)
add_subdirectory(lua)
# add_subdirectory(luajit)
# add_subdirectory(openssl) TODO: remove, replaced by libressl
add_subdirectory(png)
add_subdirectory(rapidjson/lib)
add_subdirectory(uv)
add_subdirectory(webp)
# add_subdirectory(websockets)

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
    # websockets
)

if(ANDROID)
    target_link_libraries(external pvmp3dec tremolo)
endif()
