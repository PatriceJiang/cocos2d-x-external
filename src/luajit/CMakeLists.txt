cmake_minimum_required(VERSION 3.6)

project(luajit C)


if(WIN32)
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

endif()

set(output_dir ${CMAKE_BINARY_DIR}/include)
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

add_custom_command(TARGET buildvm POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E echo "POST_BUILD: remove generated ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h}"
    COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
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
set(BUILD_LUA_STATIC ON)
if(BUILD_LUA_STATIC)
    add_library(lua
        ${lua_src}
    )
else()
    add_library(lua SHARED
        ${lua_src}
    )
    target_compile_definitions(lua PUBLIC
        LUA_BUILD_AS_DLL
    )
endif()

target_include_directories(lua PRIVATE
    ${output_dir}
)

set_target_properties(lua PROPERTIES  
    PUBLIC_HEADER "${SRC_HEADERS}"
)

### luajit
add_executable(luajit 
    ${CMAKE_CURRENT_LIST_DIR}/src/luajit.c
)
target_compile_definitions(luajit PRIVATE
    _CRT_SECURE_NO_DEPRECATE
)
target_link_libraries(luajit lua)
set_target_properties(luajit PROPERTIES 
    LINK_FLAGS /SUBSYSTEM:CONSOLE
)

### generate headers 
function(buildvm_generate)
    set(oneValueArgs DEF OUTPUT)
    set(multiValueArgs DEPENDS)
    cmake_parse_arguments(opt "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    add_custom_command(OUTPUT ${opt_OUTPUT} 
        COMMAND buildvm ARGS -m ${opt_DEF} -o ${opt_OUTPUT} ${opt_DEPENDS}
        DEPENDS ${opt_DEPENDS}
    )
    target_sources(lua PRIVATE ${opt_OUTPUT})
    add_custom_command(TARGET lua POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "POST_BUILD: remove generated file ${opt_OUTPUT}"
        COMMAND ${CMAKE_COMMAND} -E remove -f ${opt_OUTPUT}
    )
endfunction()


buildvm_generate(OUTPUT ${output_dir}/objs/lj_vm.obj DEF peobj)
buildvm_generate(OUTPUT ${output_dir}/lj_bcdef.h DEF bcdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_ffdef.h DEF ffdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_libdef.h DEF libdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_recdef.h DEF recdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/src/jit/vmdef.lua DEF vmdef DEPENDS ${LBLIB_SC})
buildvm_generate(OUTPUT ${output_dir}/lj_folddef.h DEF folddef DEPENDS ${CMAKE_CURRENT_LIST_DIR}/src/lj_opt_fold.c)

### buildvm

message(STATUS "target CMAKE_SYSTEM_PROCESSOR: 
    ${CMAKE_SYSTEM_PROCESSOR}
    ${CMAKE_GENERATOR_PLATFORM}
    ${CMAKE_SYSTEM_NAME}
    ")

if(WIN32)

    if(BUILD_WIN32)
        set(DASM_AFLAGS -LN -D WIN -D JIT -D FFI)
        set(DASM_ARCH x86)
    else()
        set(DASM_AFLAGS -LN -D WIN -D JIT -D FFI -D P64)
        set(DASM_ARCH x64)
    endif()
endif()


set(dynasm_dir ${CMAKE_CURRENT_LIST_DIR}/dynasm)
file(GLOB dasm_lua ${dynasm_dir}/*.lua)

add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h
    COMMAND minilua ARGS ${dynasm_dir}/dynasm.lua ${DASM_AFLAGS} -o 
        ${CMAKE_CURRENT_LIST_DIR}/src/host/buildvm_arch.h 
        ${CMAKE_CURRENT_LIST_DIR}/src/vm_${DASM_ARCH}.dasc
    DEPENDS ${dasm_lua}
)