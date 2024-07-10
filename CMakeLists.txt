cmake_minimum_required(VERSION 3.26)
project(dungeonloop LANGUAGES CXX Swift)

# Must have at least C++17.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_OSX_DEPLOYMENT_TARGET 13.0)

# Verify that we have a new enough compiler
if("${CMAKE_Swift_COMPILER_VERSION}" VERSION_LESS 5.10)
  message(FATAL_ERROR "Bidirectional C++ Interop requires Swift 5.10 or greater. Have ${CMAKE_Swift_COMPILER_VERSION}")
endif()

if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND
   NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  message(FATAL_ERROR "Project requires building with Clang.
  Have ${CMAKE_CXX_COMPILER_ID}")
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Emscripten")
  set(EMSCRIPTEN TRUE)
endif()

# Make sure all binaries are placed into the same build folder.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Link your project against CF statically, rather than as a shared library.
set(CUTE_FRAMEWORK_STATIC ON)
set(CF_FRAMEWORK_BUILD_SAMPLES OFF)
set(CF_FRAMEWORK_BUILD_TESTS OFF)

# This will download and build Cute Framework just once the first time you build your game.
include(FetchContent)
FetchContent_Declare(
  cute
  GIT_REPOSITORY https://github.com/RandyGaul/cute_framework
  GIT_TAG 1.0
  GIT_PROGRESS TRUE
  # Apply patch to Cute Framework to make it work with Swift.
  PATCH_COMMAND git co CMakeLists.txt && git apply ../../../patches/000-cute_framework.patch
)
FetchContent_MakeAvailable(cute)

# Source code for your game.
add_executable(
  dungeonloop
  src/main.swift
)

# Our source code will be in the `src` folder.
target_include_directories(dungeonloop PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>)

# Support for web builds through the Emscripten compiler.
if(EMSCRIPTEN)
  set(CMAKE_EXECUTABLE_SUFFIX ".html")
  target_compile_options(dungeonloop PUBLIC -O1 -fno-rtti -fno-exceptions)
  target_link_options(dungeonloop PRIVATE -o dungeonloop.html --preload-file ${CMAKE_SOURCE_DIR}/content@/content --emrun -s ASYNCIFY=1 -O1)
endif()

# Some basic information needed for CMake to generate your Info.plist file.
# This is necessary for e.g. iOS builds.
if(APPLE)
  set_target_properties(dungeonloop PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.layer22.dungeonloop"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
  )
endif()

# Make the game link against Cute Framework.
target_link_libraries(dungeonloop cute)

# For convenience on Windows, set MSVC debugger's working directory in the build folder.
# Also ask MSVC to make the game the startup project.
if (MSVC)
  set_property(TARGET dungeonloop PROPERTY VS_DEBUGGER_WORKING_DIRECTORY $<TARGET_FILE_DIR:dungeonloop>)
  set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT dungeonloop)
endif()
