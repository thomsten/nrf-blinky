include(CMakeForceCompiler)

set(CMAKE_SYSTEM_NAME Generic)

if (TARGET_PLATFORM MATCHES "NRF51")
  set(CMAKE_SYSTEM_PROCESSOR cortex-m0)
elseif (TARGET_PLATEFORM MATCHES "NRF52")
  set(CMAKE_SYSTEM_PROCESSOR cortex-m4)
endif ()

cmake_force_c_compiler(arm-none-eabi-gcc GNU)

execute_process(
  COMMAND ${CMAKE_C_COMPILER} -print-file-name=libc.a
  OUTPUT_VARIABLE CMAKE_INSTALL_PREFIX
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

# Strip the filename off
get_filename_component(CMAKE_INSTALL_PREFIX
  "${CMAKE_INSTALL_PREFIX}" PATH
)

# Then find the canonical path to the directory one up from there
get_filename_component(CMAKE_INSTALL_PREFIX
  "${CMAKE_INSTALL_PREFIX}/.." REALPATH
)
set(CMAKE_INSTALL_PREFIX  ${CMAKE_INSTALL_PREFIX} CACHE FILEPATH
    "Install path prefix, prepended onto install directories.")

message(STATUS "Cross-compiling with the gcc-arm-embedded toolchain")
message(STATUS "Toolchain prefix: ${CMAKE_INSTALL_PREFIX}")

set(CMAKE_FIND_ROOT_PATH  ${CMAKE_INSTALL_PREFIX})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

if (CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m0")
 set(CMAKE_C_FLAGS
    "-mcpu=cortex-m0 -mthumb -mabi=aapcs -mfloat-abi=soft"
    "-std=gnu99"
    "-Wall"
    "-fno-common -ffunction-sections -fdata-sections -fno-strict-aliasing"
    "-fno-builtin --short-enums -O3"
    )
  string(REGEX REPLACE ";" " " CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m4")
  message(FATAL_ERROR "Target not supported")
endif ()

set(BUILD_SHARED_LIBS OFF)

function(create_hex executable)
  add_custom_command(
    TARGET ${executable}
    POST_BUILD
    COMMAND arm-none-eabi-objcopy -O ihex ${CMAKE_CURRENT_BINARY_DIR}/${executable}.elf ${CMAKE_CURRENT_BINARY_DIR}/${executable}.hex
    )
endfunction(create_hex)
