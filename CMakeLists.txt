cmake_minimum_required(VERSION 3.0)

set(TARGET_PLATFORM "NRF51" CACHE STRING "Target platform")
set(SDK_ROOT        ""      CACHE STRING "SDK root folder")

if (SDK_ROOT MATCHES "" AND DEFINED ENV{SDK_ROOT})
  set(SDK_ROOT "$ENV{SDK_ROOT}")
endif ()

if (EXISTS "${SDK_ROOT}/components/toolchain/system_nrf51.c")
  message(STATUS "Using SDK from ${SDK_ROOT}")
else ()
  message(FATAL_ERROR "${SDK_ROOT} is not a valid path to the nRF51 SDK...")
endif ()

set(CMAKE_C_FLAGS "" CACHE STRING "")
include(${CMAKE_SOURCE_DIR}/CMake/toolchain_gcc.cmake)

project(nrf_blinky C ASM)

set(CMAKE_EXECUTABLE_SUFFIX ".elf")

add_custom_target(f_softdevice
  COMMAND nrfjprog -f ${TARGET_PLATFORM} --eraseall
  COMMAND nrfjprog -f ${TARGET_PLATFORM} --program ${SDK_ROOT}/components/softdevice/s110/hex/s110_softdevice.hex
  )

function (add_flash_target target)
  set(ftarget f_${target})

  add_custom_target(${ftarget}
    COMMAND mergehex -m ${SDK_ROOT}/components/softdevice/s110/hex/s110_softdevice.hex ${CMAKE_CURRENT_BINARY_DIR}/${target}.hex -o ${CMAKE_CURRENT_BINARY_DIR}/${target}_s110.hex
    COMMAND nrfjprog -f ${TARGET_PLATFORM} --program ${CMAKE_CURRENT_BINARY_DIR}/${target}_s110.hex --chiperase
    COMMAND nrfjprog -f ${TARGET_PLATFORM} -r
    )
endfunction ()

set(SRCS
  "src/main.c"
  "${SDK_ROOT}/components/libraries/simple_timer/app_simple_timer.c"
  "${SDK_ROOT}/components/drivers_nrf/timer/nrf_drv_timer.c"
  "${SDK_ROOT}/components/drivers_nrf/hal/nrf_delay.c"
  "${SDK_ROOT}/components/drivers_nrf/common/nrf_drv_common.c"
  "${SDK_ROOT}/components/toolchain/system_nrf51.c"
  "${SDK_ROOT}/components/toolchain/gcc/gcc_startup_nrf51.s"
  )

include_directories(
  "include"
  "${SDK_ROOT}/examples/bsp"
  "${SDK_ROOT}/components/drivers_nrf/timer"
  "${SDK_ROOT}/components/drivers_nrf/common"
  "${SDK_ROOT}/components/drivers_nrf/hal"
  "${SDK_ROOT}/components/libraries/simple_timer"
  "${SDK_ROOT}/components/libraries/util"
  "${SDK_ROOT}/components/device"
  "${SDK_ROOT}/components/toolchain"
  "${SDK_ROOT}/components/toolchain/gcc"
  "${SDK_ROOT}/components/softdevice/s110/headers"
  )

add_definitions(
  "-DBOARD_PCA10031"
  "-DSOFTDEVICE_PRESENT"
  "-DNRF51"
  "-DS110"
  "-DBSP_DEFINES_ONLY"
  "-DSWI_DISABLE0"
  "-DBLE_STACK_SUPPORT_REQD"
  "-DBLE_STACK_SUPPORT"
  )

set(target_name ${PROJECT_NAME})

set(MY_LINK_FLAGS
  "-Xlinker -Map=${CMAKE_CURRENT_BINARY_DIR}/${target_name}.map"
  "-mthumb -mabi=aapcs -L${SDK_ROOT}/components/toolchain/gcc"
  "-T${CMAKE_SOURCE_DIR}/linker/s110_nrf51.ld"
  "-Wl,--gc-sections"
  "--specs=nano.specs -lc -lnosys"
  )
string(REGEX REPLACE ";" " " MY_LINK_FLAGS "${MY_LINK_FLAGS}")

add_executable(${target_name} "${SRCS}")
set_target_properties(${target_name} PROPERTIES LINK_FLAGS "${MY_LINK_FLAGS}")

create_hex(${target_name})
add_flash_target(${target_name})
