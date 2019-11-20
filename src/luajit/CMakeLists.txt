    cmake_minimum_required(VERSION 3.6)

project(luajit C)

if("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Windows")
    set(HOST_GENERATOR "Visual Studio 15 2017")
    #set(HOST_GENERATOR "MinGW Makefiles")
    set(HOST_CMAKE cmake)
elseif("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Darwin")
    set(HOST_GENERATOR "Unix Makefiles")
    #set(HOST_GENERATOR "Xcode")
    set(HOST_CMAKE cmake)
    execute_process(COMMAND xcrun --sdk macosx --show-sdk-path
        OUTPUT_VARIABLE sdk_path 
    )
    set(HOST_SYSTEM_NAME -DCMAKE_SYSTEM_NAME=Darwin )#-DCMAKE_OSX_SYSROOT=${sdk_path})
elseif("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Linux")
    set(HOST_GENERATOR "Unix Makefiles")
    set(HOST_CMAKE cmake)
else()
    message(FATAL_ERROR "Unsupport platform \"${CMAKE_HOST_SYSTEM_NAME}\"")
endif()



if(WIN32)
set(BUILD_LUA_STATIC OFF)
else()
set(BUILD_LUA_STATIC ON)
endif()


if("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Windows")
    set(MINILUA ${CMAKE_BINARY_DIR}/minilua/Debug/minilua.exe)
    set(BUILDVM ${CMAKE_BINARY_DIR}/buildvm/Debug/buildvm.exe)
    # set(MINILUA ${CMAKE_BINARY_DIR}/minilua/minilua.exe)
    # set(BUILDVM ${CMAKE_BINARY_DIR}/buildvm/buildvm.exe)
    set(HOST_WINDOWS ON)
elseif("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Linux")
    set(MINILUA ${CMAKE_BINARY_DIR}/minilua/minilua)
    set(BUILDVM ${CMAKE_BINARY_DIR}/buildvm/buildvm)
    set(HOST_LINUX ON)
elseif("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Darwin")
    set(MINILUA ${CMAKE_BINARY_DIR}/minilua/minilua)
    set(BUILDVM ${CMAKE_BINARY_DIR}/buildvm/buildvm)
    set(HOST_APPLE ON)
endif()



### buildvm

message(STATUS "target CMAKE_SYSTEM_PROCESSOR: 
    ${CMAKE_SYSTEM_PROCESSOR}
    CMAKE_GENERATOR_PLATFORM : ${CMAKE_GENERATOR_PLATFORM}
    CMAKE_SYSTEM_NAME : ${CMAKE_SYSTEM_NAME}
    ")

set(DASM_ARCH)
set(DASM_AFLAGS)
#set(HOST_CFLAGS)
set(LJ_VM lj_vm.obj)
set(LJVM_MODE elfasm)

set(TARGET_LJARCH)
set(TARGET_ARCH)


if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    list(APPEND HOST_CFLAGS -DLUAJIT_OS=LUAJIT_OS_OSX)
    set(TARGET_OSX ON)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    list(APPEND HOST_CFLAGS -DLUAJIT_OS=LUAJIT_OS_LINUX)
    set(TARGET_LINUX ON)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    list(APPEND HOST_CFLAGS -DLUAJIT_OS=LUAJIT_OS_WINDOWS -malign-double)
    set(TARGET_WINDOWS ON)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
    list(APPEND HOST_CFLAGS -DLUAJIT_OS=LUAJIT_OS_OSX)
    set(TARGET_IOS ON)
    execute_process(COMMAND xcrun --sdk iphoneos --show-sdk-path
        OUTPUT_VARIABLE sdk_path 
    )
    set(IOS_SDK ${sdk_path})
else()
    list(APPEND HOST_CFLAGS -DLUAJIT_OS=LUAJIT_OS_OTHER)
endif()


if(MSVC)
    add_definitions(
        /D_CRT_SECURE_NO_DEPRECATE
        /D_CRT_SECURE_NO_WARNINGS
        "/D_CRT_STDIO_INLINE=__declspec(dllexport)__inline"
    )
    string(TOLOWER "${CMAKE_GENERATOR_PLATFORM}" win_platform)
    if("${win_platform}" STREQUAL "win32")
        set(BUILD_WIN32 ON)
    else()
        set(BUILD_WIN64 ON)
    endif()

    if(BUILD_WIN32)
        set(CMAKE_C_FLAGS  /arch:SSE2)
        set(CMAKE_CXX_FLAGS  /arch:SSE2)
    else()
        add_definitions(/DLUAJIT_ENABLE_GC64)
    endif()

    message(STATUS "BUILD_WIN64: " ${BUILD_WIN64})
    message(STATUS "BUILD_WIN32: " ${BUILD_WIN32})

    if(BUILD_WIN32)
        set(DASM_AFLAGS -LN -D WIN -D JIT -D FFI)
        set(DASM_ARCH x86)
    elseif(BUILD_WIN64)
        set(DASM_AFLAGS -LN -D WIN -D JIT -D FFI -D P64)
        set(DASM_ARCH x64)
    endif()
    set(LJVM_MODE peobj)
endif()

if(ANDROID OR HOST_LINUX OR HOST_APPLE)

    set(default_flags ${CMAKE_C_FLAGS})

    if(ANDROID)
        if("${ANDROID_ABI}" MATCHES "armeabi.*")
            set(DASM_ARCH arm)
        elseif("${ANDROID_ABI}" STREQUAL "arm64-v8a")
            set(DASM_ARCH arm64)
        elseif("${ANDROID_ABI}" STREQUAL "x86")
            set(DASM_ARCH x86)
            set(CMAKE_C_FLAGS -march=i686 -msse -msse2 -mfpmath=sse)
        elseif("${ANDROID_ABI}" STREQUAL "x86_64")
            set(DASM_ARCH x64)
        else()
            message(FATAL_ERROR "Unsupport architecture \"${CMAKE_ANDROID_ARCH}\"")
        endif()
    elseif(HOST_LINUX)
        # set(DASM_ARCH x86)
        # list(APPEND TARGET_ARCH "-m32")

        set(DASM_ARCH x64)
        list(APPEND HOST_CFLAGS -DLUAJIT_OS=LUAJIT_OS_LINUX)
    elseif(TARGET_OSX)
       # set(DASM_ARCH x64)

        set(DASM_ARCH x86)
        list(APPEND default_flags "-m32")
        set(LJVM_MODE machasm)
    elseif(TARGET_IOS)
        set(LJVM_MODE machasm)
        #set(DASM_ARCH arm64)
        #list(APPEND default_flags -DLJ_NO_SYSTEM=1 -DLUAJIT_ENABLE_GC64)
        list(APPEND CMAKE_C_FLAGS -miphoneos-version-min=8.0)
        set(DASM_ARCH arm)
        list(APPEND default_flags -m32 ) 
        list(APPEND TARGET_ARCH -m32)

        #set(ENV{IPHONEOS_DEPLOYMENT_TARGET} 10.0)
    endif()

    message(STATUS "Compiler: ${CMAKE_C_COMPILER}")
    separate_arguments(default_flags)
    if(ANDROID)
        execute_process(COMMAND ${CMAKE_C_COMPILER}
            ${default_flags}
            --target=${CMAKE_C_COMPILER_TARGET}
            --gcc-toolchain=${ANDROID_TOOLCHAIN_ROOT}
            -D_FILE_OFFSET_BITS=64
            -D_LARGETFILE_SOURCE
            -U_FORTIFY_SOURCE
            -E ${CMAKE_CURRENT_LIST_DIR}/src/lj_arch.h
            -dM
            -mfloat-abi=softfp -Wl,--fix-cortex-a8
            OUTPUT_VARIABLE TARGET_TESTARCH
            OUTPUT_STRIP_TRAILING_WHITESPACE
            )
    elseif(TARGET_IOS)
        message(STATUS "？？？CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
        message(STATUS "？？？IOS_SDK: ${IOS_SDK}")
        message(STATUS "？？？CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
        message(STATUS "??? CMAKE_OSX_DEVELOPMENT_TARGET: ${CMAKE_OSX_DEPLOYMENT_TARGET}")

        execute_process(COMMAND ${CMAKE_C_COMPILER}
            --sysroot ${IOS_SDK}
            -D_FILE_OFFSET_BITS=64
            -D_LARGETFILE_SOURCE
            -U_FORTIFY_SOURCE
            -arch armv7
            -E ${CMAKE_CURRENT_LIST_DIR}/src/lj_arch.h
            -dM
            -mfloat-abi=softfp -Wl,--fix-cortex-a8
           # -m32
            OUTPUT_VARIABLE TARGET_TESTARCH
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    elseif(HOST_LINUX OR HOST_APPLE)
        execute_process(COMMAND ${CMAKE_C_COMPILER}
            ${default_flags}
           -D_FILE_OFFSET_BITS=64
            -D_LARGETFILE_SOURCE
            -U_FORTIFY_SOURCE
            -E ${CMAKE_CURRENT_LIST_DIR}/src/lj_arch.h
            -dM
            OUTPUT_VARIABLE TARGET_TESTARCH
            OUTPUT_STRIP_TRAILING_WHITESPACE
            )
    else()
        message(FATAL_ERROR "Dont know which platform")
    endif()
    #message(WARNING "TARGET_TESTARCH: ${TARGET_TESTARCH}")
    #file(WRITE "C:/Projects/output.txt" ${TARGET_TESTARCH})
    file(WRITE "/Users/cocos/Projects/output.txt" ${TARGET_TESTARCH})

    if("${TARGET_TESTARCH}" STREQUAL "")
        message(FATAL_ERROR "Failed to exec ")
    endif()


    string(FIND "${TARGET_TESTARCH}" "LJ_TARGET_X64 " fpos)
    if(${fpos} GREATER -1)
        set(TARGET_LJARCH x64)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_TARGET_X86 " fpos)
    if(${fpos} GREATER -1)
        set(TARGET_LJARCH x86)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_TARGET_ARM " fpos)
    if(${fpos} GREATER -1)
        set(TARGET_LJARCH arm)
        if(TARGET_IOS)
            list(APPEND TARGET_ARCH -D IOS)
        endif()
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_TARGET_ARM64 " fpos)
    if(${fpos} GREATER -1)
        set(TARGET_LJARCH arm64)
        string(FIND "${TARGET_TESTARCH}" "__AARCH64EB__" fpos)
        if(${fpos} GREATER -1)
            list(APPEND TARGET_ARCH "-D__AARCH64EB__=1")
        endif()
    endif()

    list(APPEND TARGET_ARCH "-DLUAJIT_TARGET=LUAJIT_ARCH_${TARGET_LJARCH}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDLUAJIT_OS_LINUX")

    string(FIND "${TARGET_TESTARCH}" "LJ_LE 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D ENDIAN_LE)
    else()
        list(APPEND DASM_AFLAGS -D ENDIAN_BE)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_ARCH_BITS 64" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D P64)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_HASJIT 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D JIT)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_HASFFI 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D FFI)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_DUALNUM 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D DUALNUM)
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_ARCH_HASFPU 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D FPU)
        list(APPEND TARGET_ARCH "-DLJ_ARCH_HASFPU=1")
    else()
        list(APPEND TARGET_ARCH "-DLJ_ARCH_HASFPU=0")
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_ABI_SOFTFP 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND TARGET_ARCH "-DLJ_ABI_SOFTFP=1")
    else()
        list(APPEND DASM_AFLAGS -D HFABI)
        list(APPEND TARGET_ARCH "-DLJ_ABI_SOFTFP=0")
    endif()

    string(FIND "${TARGET_TESTARCH}" "LJ_NO_UNWIND 1" fpos)
    if(${fpos} GREATER -1)
        list(APPEND DASM_AFLAGS -D LJ_NO_UNWIND)
        list(APPEND TARGET_ARCH "-DDLUAJIT_NO_UNWIND")
    endif()

    string(REGEX MATCH "LJ_ARCH_VERSION [0-9]+" version_string "${TARGET_TESTARCH}")
    message(WARNING "LJ_ARCH_VERSION -> ${version_string}")
    if(version_string)
        string(LENGTH "LJ_ARCH_VERSION " start_index)
        string(SUBSTRING "${version_string}" ${start_index} -1 version_number)
        list(APPEND DASM_AFLAGS -D VER=${version_number})
    endif()

    if("${TARGET_LJARCH}" STREQUAL "x64")
        string(FIND "${TARGET_TESTARCH}" "LJ_FR2 1" fpos)
        if(${fpos} GREATER -1)
            set(DASM_ARCH x86)
        endif()
    endif()

    #set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${TARGET_ARCH}")

    set(LJ_VM lj_vm.S)

endif()

message(STATUS "DASM_AFLAGS: ${DASM_AFLAGS}")
message(STATUS "DASM_ARCH: ${DASM_ARCH}")
message(STATUS "TARGET_ARCH: ${TARGET_ARCH}")
message(STATUS "HOST_SYSTEM_NAME: ${HOST_SYSTEM_NAME}")

set(dynasm_dir ${CMAKE_CURRENT_LIST_DIR}/dynasm)
file(GLOB dasm_lua ${dynasm_dir}/*.lua)

add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
    #COMMAND ${CMAKE_COMMAND} -E echo "DASM_AFLAGS:: ${DASM_AFLAGS}"
    COMMAND ${MINILUA} ARGS ${dynasm_dir}/dynasm.lua ${DASM_AFLAGS} -o
        ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
        ${CMAKE_CURRENT_LIST_DIR}/src/vm_${DASM_ARCH}.dasc
    DEPENDS minilua ${dasm_lua} 
)

#if("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Windows")
#    string(REGEX REPLACE "-D" "/D" TARGET_ARCH "${TARGET_ARCH}")
#endif()

list(APPEND HOST_CFLAGS ${TARGET_ARCH})
add_custom_target(buildvm 
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/buildvm
    COMMAND ${HOST_CMAKE}
        -S ${CMAKE_CURRENT_LIST_DIR}/src/buildvm
        -G ${HOST_GENERATOR}
        -B"${CMAKE_BINARY_DIR}/buildvm" 
        -D CMAKE_C_FLAGS="${HOST_CFLAGS}"
        ${HOST_SYSTEM_NAME}
        #-Awin32
    COMMAND ${HOST_CMAKE} --build ${CMAKE_BINARY_DIR}/buildvm
    DEPENDS ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
)

set(flags "${HOST_CFLAGS}")
string(REPLACE ";" " " flags "${flags}")
#list(APPEND HOST_CFLAGS -target i386-apple-darwin-unknown)

set(COMMAND_STRING 
"#!/bin/bash
set -x
${HOST_CMAKE} -S \"${CMAKE_CURRENT_LIST_DIR}/src/minilua\" \
    -G \"${HOST_GENERATOR}\" \
    -B\"${CMAKE_BINARY_DIR}/minilua\" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_FLAGS=\"${flags}\" \
    ${HOST_SYSTEM_NAME}
    "
)
file(WRITE ${CMAKE_BINARY_DIR}/compile_minilua.sh "${COMMAND_STRING}")
message(STATUS "/////////////////////////")
message(STATUS ${COMMAND_STRING})
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/minilua)
add_custom_target(minilua
    #COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/minilua
    #COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/minilua
    #COMMAND ${CMAKE_COMMAND} -E echo "${HOST_SYSTEM_NAME}"
    # COMMAND env -i bash --login ${CMAKE_BINARY_DIR}/compile_minilua.sh
              #  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.14
    #COMMAND env -i bash --login -c "make -C ${CMAKE_BINARY_DIR}/minilua"
    ${HOST_CMAKE} -S ${CMAKE_CURRENT_LIST_DIR}/src/minilua 
        -G ${HOST_GENERATOR}
        -B"${CMAKE_BINARY_DIR}/minilua"
        -DCMAKE_BUILD_TYPE=Debug 
        -DCMAKE_C_FLAGS="${HOST_CFLAGS}" 
        ${HOST_SYSTEM_NAME}
    COMMAND ${HOST_CMAKE} --build ${CMAKE_BINARY_DIR}/minilua
    USE_TERMINAL
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/minilua
    COMMENT "compiling minilua"
)


set(output_dir ${CMAKE_BINARY_DIR}/include)
if(NOT EXISTS ${CMAKE_BINARY_DIR}/include)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include)
endif()
if(NOT EXISTS ${CMAKE_BINARY_DIR}/include/objs)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include/objs)
endif()
#set(output_dir ${CMAKE_CURRENT_LIST_DIR}/src)

set(SRC_HEADERS 
    ${CMAKE_CURRENT_LIST_DIR}/src/lua.h
    ${CMAKE_CURRENT_LIST_DIR}/src/lualib.h
    ${CMAKE_CURRENT_LIST_DIR}/src/lauxlib.h
    ${CMAKE_CURRENT_LIST_DIR}/src/luaconf.h
    ${CMAKE_CURRENT_LIST_DIR}/src/lua.hpp
    ${CMAKE_CURRENT_LIST_DIR}/src/luajit.h
)

set(LBLIB_SC
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_base.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_math.c
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_bit.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_string.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_table.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_io.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_os.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_package.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_debug.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_jit.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/lib_ffi.c
)




### lua
file(GLOB lua_src src/lj_*.c src/lib_*.c)
set(LUA luajit)
if(BUILD_LUA_STATIC)
    add_library(${LUA}
        ${lua_src}
    )
else()
    add_library(${LUA} SHARED
        ${lua_src}
    )
    target_compile_definitions(${LUA} PUBLIC
        LUA_BUILD_AS_DLL
    )

endif()

target_include_directories(${LUA} PRIVATE
    ${output_dir}
)
set_target_properties(${LUA} PROPERTIES  
    PUBLIC_HEADER "${SRC_HEADERS}"
)

add_dependencies(${LUA} minilua buildvm)

### luajit
# add_executable(luajit
#     ${CMAKE_CURRENT_LIST_DIR}/src/luajit.c
# )
# target_compile_definitions(luajit PRIVATE
#     _CRT_SECURE_NO_DEPRECATE
# )
# target_link_libraries(luajit lua)
# set_target_properties(luajit PROPERTIES
#     LINK_FLAGS /SUBSYSTEM:CONSOLE
# )

### generate headers 
function(buildvm_generate)
    set(oneValueArgs DEF OUTPUT)
    set(multiValueArgs DEPENDS)
    cmake_parse_arguments(opt "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    add_custom_command(OUTPUT ${opt_OUTPUT} 
        COMMAND ${BUILDVM} ARGS -m ${opt_DEF} -o ${opt_OUTPUT} ${opt_DEPENDS}
        DEPENDS ${opt_DEPENDS}
    )
    target_sources(${LUA} PRIVATE ${opt_OUTPUT})
    add_custom_command(TARGET ${LUA} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "POST_BUILD: remove generated file ${opt_OUTPUT}"
        COMMAND ${CMAKE_COMMAND} -E remove -f ${opt_OUTPUT}
    )
endfunction()


buildvm_generate(OUTPUT ${output_dir}/objs/${LJ_VM} DEF ${LJVM_MODE})
buildvm_generate(OUTPUT ${output_dir}/lj_bcdef.h DEF bcdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_ffdef.h DEF ffdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_libdef.h DEF libdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_recdef.h DEF recdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/src/jit/vmdef.lua DEF vmdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_folddef.h DEF folddef DEPENDS ${CMAKE_CURRENT_LIST_DIR}/src/lj_opt_fold.c)

install(TARGETS ${LUA})