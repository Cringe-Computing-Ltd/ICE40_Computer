#include <stdio.h>
#include "pico/stdlib.h"
#include "board.h"
#include "../../build/bitstream.h"
#include "debug.h"
#include "font.h"
#include "rom.h"

int main() {
    stdio_init_all();

    // Initialize onboard LED
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
    gpio_put(PICO_DEFAULT_LED_PIN, 0);

    // Initialize board and 7-segment displays
    board::init();
    seven_segment::enable(true, true);

    // Wait 100ms for power to stabalize at the FPGA
    sleep_ms(100);
    
    // Configure GPIO
    fpga::configure(build_Computer_bin, build_Computer_bin_len);

    // Signal end of load by turning on the LED
    gpio_put(PICO_DEFAULT_LED_PIN, 1);

    // Wait 100ms for FPGA to be stable
    sleep_ms(100);

    // Initialize debugger
    debug::init();

    // Load ROM
    for (int i = 0; i < rom_bin_len; i++) {
        debug::poke(i, rom_bin[i]);
    }

    // Load font
    for (int i = 0; i < 128; i++) {
        debug::poke(0xF800 + (i * 4), (font8x8_basic[i][1] << 8) | font8x8_basic[i][0]);
        debug::poke(0xF800 + (i * 4) + 1, (font8x8_basic[i][3] << 8) | font8x8_basic[i][2]);
        debug::poke(0xF800 + (i * 4) + 2, (font8x8_basic[i][5] << 8) | font8x8_basic[i][4]);
        debug::poke(0xF800 + (i * 4) + 3, (font8x8_basic[i][7] << 8) | font8x8_basic[i][6]);
    }

    // Lets go
    sleep_ms(100);
    debug::unhalt();

    while(1);
}
