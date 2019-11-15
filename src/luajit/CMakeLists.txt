cmake_minimum_required(VERSION 3.6)

project(luajit C)


if(WIN32)
    add_definitions(
        /D_CRT_SECURE_NO_DEPRECATE
        /D_CRT_SECURE_NO_WARNINGS
    #    "/D_CRT_STDIO_INLINE=__declspec(dllexport)__inline"
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

endif()

set(output_dir ${CMAKE_BINARY_DIR}/include)

set(SRC_HEADERS 
    lua.h
    lualib.h
    lauxlib.h
    luaconf.h 
    lua.hpp
    luajit.h
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

### minilua
add_executable(minilua 
    ${CMAKE_CURRENT_LIST_DIR}/src/host/minilua.c
)
target_include_directories(minilua PRIVATE
    src/host
)
set_target_properties(minilua PROPERTIES 
    LINK_FLAGS /SUBSYSTEM:CONSOLE
)

### buildvm target
add_executable(buildvm 
    ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_asm.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_peobj.c 
    ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_lib.c
    ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_fold.c
    ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
)
target_include_directories(buildvm PRIVATE
    src/host
    src
    ${CMAKE_CURRENT_LIST_DIR}/dynasm
)
target_compile_options(buildvm PRIVATE 
    /MD
)

### lua
file(GLOB lua_src src/lj_*.c src/lib_*.c)
add_library(lua SHARED
    ${lua_src}
)
target_compile_definitions(lua PUBLIC
    LUA_BUILD_AS_DLL
)
target_include_directories(lua PRIVATE
    ${output_dir}
)


### luajit
add_executable(luajit 
    ${CMAKE_CURRENT_LIST_DIR}/src/luajit.c
)

target_compile_definitions(luajit PRIVATE
    _CRT_SECURE_NO_DEPRECATE
)

target_link_libraries(luajit lua)

### generate headers 
function(buildvm_generate file arg src_list)
    add_custom_command(OUTPUT ${file}
        COMMAND buildvm -m ${arg} -o ${file} ${src_list}
        DEPENDS ${src_list}
    )
    target_sources(lua PRIVATE ${file})
endfunction()


buildvm_generate(${CMAKE_CURRENT_LIST_DIR}/src/lj_vm.obj peobj "")
buildvm_generate(${output_dir}/lj_bcdef.h bcdef ${LBLIB_SC})
buildvm_generate(${output_dir}/lj_ffdef.h ffdef ${LBLIB_SC})
buildvm_generate(${output_dir}/lj_libdef.h libdef ${LBLIB_SC})
buildvm_generate(${output_dir}/lj_recdef.h recdef ${LBLIB_SC})
buildvm_generate(${CMAKE_CURRENT_LIST_DIR}/src/jit/vmdef.lua vmdef ${LBLIB_SC})
buildvm_generate(${output_dir}/lj_folddef.h folddef ${CMAKE_CURRENT_LIST_DIR}/src/lj_opt_fold.c)

### buildvm

message(STATUS "target CMAKE_SYSTEM_PROCESSOR: 
    ${CMAKE_SYSTEM_PROCESSOR}
    ${CMAKE_GENERATOR_PLATFORM}
    ${CMAKE_SYSTEM_NAME}
    ")

if(WIN32)

    if(BUILD_WIN32)
        set(DASM_AFLAGS -D WIN -D JIT -D FFI )
        set(DASM_ARCH x86)
    else()
        set(DASM_AFLAGS -D WIN -D JIT -D FFI -D P64)
        set(DASM_ARCH x64)
    endif()
endif()

message(STATUS "DASM_AFLAGS: ${DASM_AFLAGS}")

set(dynasm_dir ${CMAKE_CURRENT_LIST_DIR}/dynasm)
file(GLOB dasm_lua ${dynasm_dir}/*.lua)

add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
    COMMAND ${CMAKE_COMMAND} -E echo "dynasm.lua flags: ${DASM_AFLAGS} -o ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h ${CMAKE_CURRENT_LIST_DIR}/src/vm_${DASM_ARCH}.dasc"
    COMMAND minilua ${dynasm_dir}/dynasm.lua -LN ${DASM_AFLAGS} -o ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h ${CMAKE_CURRENT_LIST_DIR}/src/vm_${DASM_ARCH}.dasc
    DEPENDS ${dasm_lua}
)