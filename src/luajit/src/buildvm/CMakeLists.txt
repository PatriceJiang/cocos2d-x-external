cmake_minimum_required(VERSION 3.6)

project(luajit C)


if(WIN32)
    add_definitions(
        /D_CRT_SECURE_NO_DEPRECATE
        /D_CRT_SECURE_NO_WARNINGS
    )
endif()

### minilua
add_executable(buildvm 
    ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm.c 
    ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_asm.c 
    ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_peobj.c 
    ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_lib.c
    ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_fold.c
    ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_arch.h
)

add_custom_command(TARGET buildvm POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E echo "POST_BUILD: remove generated ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_arch.h}"
    COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_CURRENT_LIST_DIR}/../host/buildvm_arch.h
)

target_include_directories(buildvm PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/..
    ${CMAKE_CURRENT_LIST_DIR}/../host
    ${CMAKE_CURRENT_LIST_DIR}/../../dynasm
)
