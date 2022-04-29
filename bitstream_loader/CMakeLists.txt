cmake_minimum_required(VERSION 3.13)
include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)
project(bitstream_loader)
pico_sdk_init()

file(GLOB_RECURSE SRC "src/*.cpp")

add_executable(bitstream_loader ${SRC})

target_link_libraries(bitstream_loader pico_stdlib hardware_spi)

pico_enable_stdio_usb(bitstream_loader 1)
pico_enable_stdio_uart(bitstream_loader 0)
pico_add_extra_outputs(bitstream_loader)