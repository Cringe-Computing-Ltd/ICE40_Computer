#include <stdio.h>
#include "pico/stdlib.h"
#include "board.h"
#include "../../build/bitstream.h"
#include "debug.h"
#include "font.h"

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
    fpga::configure(build_ICE40_Computer_bin, build_ICE40_Computer_bin_len);

    // Signal end of load by turning on the LED
    gpio_put(PICO_DEFAULT_LED_PIN, 1);

    // Wait 100ms for FPGA to be stable
    sleep_ms(100);

    // Initialize debugger
    debug::init();

    // Load font
    for (int i = 0; i < 128; i++) {
        debug::poke(0x2000 + (i * 4), (font8x8_basic[i][1] << 8) | font8x8_basic[i][0]);
        debug::poke(0x2000 + (i * 4) + 1, (font8x8_basic[i][3] << 8) | font8x8_basic[i][2]);
        debug::poke(0x2000 + (i * 4) + 2, (font8x8_basic[i][5] << 8) | font8x8_basic[i][4]);
        debug::poke(0x2000 + (i * 4) + 3, (font8x8_basic[i][7] << 8) | font8x8_basic[i][6]);
    }

    debug::poke(0x0000, 0x0000);
    debug::poke(0x0001, 0x0800);
    debug::poke(0x0002, 0x0040);
    debug::poke(0x0003, 0x0200);
    debug::poke(0x0004, 0x0080);
    debug::poke(0x0005, 0x00FF);
    debug::poke(0x0006, 0x00C0);
    debug::poke(0x0007, 0x1AC0);
    debug::poke(0x0008, 0x294C);
    debug::poke(0x0009, 0x2901);
    debug::poke(0x000A, 0x110D);
    debug::poke(0x000B, 0x090E);
    debug::poke(0x000C, 0x2005);
    debug::poke(0x000D, 0x000A);
    debug::poke(0x000E, 0x014A);
    debug::poke(0x000F, 0x1808);
    debug::poke(0x0010, 0xA011);
    debug::poke(0x0011, 0x0014);
    debug::poke(0x0012, 0x0000);
    debug::poke(0x0013, 0x0800);
    debug::poke(0x0014, 0x8011);
    debug::poke(0x0015, 0x0009);
    debug::poke(0x0016, 0x0000);
    debug::poke(0x0017, 0x0042);
    debug::poke(0x0018, 0x0015);

    // Lets go
    sleep_ms(100);
    debug::unhalt();

    while(1);
}
