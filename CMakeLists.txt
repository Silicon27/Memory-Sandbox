cmake_minimum_required(VERSION 3.31)
project(memory_sandbox)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)  # Add this

add_executable(memory_sandbox
        main.cpp
        src/cprocess/Gao/includes/impl/Gao.cpp
)

target_include_directories(memory_sandbox
        PRIVATE
        ${CMAKE_SOURCE_DIR}/src/cprocess/Gao/includes/single_include
)

add_subdirectory(src/cprocess/Gao)
add_subdirectory(src/cprocess/Gao/src/si)