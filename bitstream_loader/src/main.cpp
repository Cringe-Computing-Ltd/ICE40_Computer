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

    // // Draw a block character
    // for (int i = 0; i < 80*60; i++) {
    //     debug::poke(0x0800 + i, 0x0F00 | (i % 128));
    // }

    // debug::poke(0x0800 + 0, 0x0F00 | 'H');
    // debug::poke(0x0800 + 1, 0x0F00 | 'e');
    // debug::poke(0x0800 + 2, 0x0F00 | 'l');
    // debug::poke(0x0800 + 3, 0x0F00 | 'l');
    // debug::poke(0x0800 + 4, 0x0F00 | 'o');
    // debug::poke(0x0800 + 5, 0x0F00 | ' ');
    // debug::poke(0x0800 + 6, 0x0F00 | 'W');
    // debug::poke(0x0800 + 7, 0x0F00 | 'o');
    // debug::poke(0x0800 + 8, 0x0F00 | 'r');
    // debug::poke(0x0800 + 9, 0x0F00 | 'l');
    // debug::poke(0x0800 + 10, 0x0F00 | 'd');
    // debug::poke(0x0800 + 11, 0x0F00 | '!');

    /*debug::poke(0x0000, 0x0000);
    debug::poke(0x0001, 0xEE00);
    debug::poke(0x0002, 0x000C);
    debug::poke(0x0003, 0x0800);
    //debug::poke(0x0004, 0x8006);
    // debug::poke(0x0005, 0x0004);
    debug::poke(0x0004, 0x0015);*/

    // debug::poke(0x0, 0x0);
    // debug::poke(0x1, 0x0248);
    // debug::poke(0x2, 0xc);
    // debug::poke(0x3, 0x800);
    // debug::poke(0x4, 0x0);
    // debug::poke(0x5, 0x0265);
    // debug::poke(0x6, 0xc);
    // debug::poke(0x7, 0x801);
    // debug::poke(0x8, 0x0);
    // debug::poke(0x9, 0x026c);
    // debug::poke(0xa, 0xc);
    // debug::poke(0xb, 0x802);
    // debug::poke(0xc, 0x0);
    // debug::poke(0xd, 0x026c);
    // debug::poke(0xe, 0xc);
    // debug::poke(0xf, 0x803);
    // debug::poke(0x10, 0x0);
    // debug::poke(0x11, 0x026f);
    // debug::poke(0x12, 0xc);
    // debug::poke(0x13, 0x804);
    // debug::poke(0x14, 0x0);
    // debug::poke(0x15, 0x0220);
    // debug::poke(0x16, 0xc);
    // debug::poke(0x17, 0x805);
    // debug::poke(0x18, 0x0);
    // debug::poke(0x19, 0x0257);
    // debug::poke(0x1a, 0xc);
    // debug::poke(0x1b, 0x806);
    // debug::poke(0x1c, 0x0);
    // debug::poke(0x1d, 0x026f);
    // debug::poke(0x1e, 0xc);
    // debug::poke(0x1f, 0x807);
    // debug::poke(0x20, 0x0);
    // debug::poke(0x21, 0x0272);
    // debug::poke(0x22, 0xc);
    // debug::poke(0x23, 0x808);
    // debug::poke(0x24, 0x0);
    // debug::poke(0x25, 0x026c);
    // debug::poke(0x26, 0xc);
    // debug::poke(0x27, 0x809);
    // debug::poke(0x28, 0x0);
    // debug::poke(0x29, 0x0264);
    // debug::poke(0x2a, 0xc);
    // debug::poke(0x2b, 0x80a);
    // debug::poke(0x2c, 0x0);
    // debug::poke(0x2d, 0x0221);
    // debug::poke(0x2e, 0xc);
    // debug::poke(0x2f, 0x80b);
    // debug::poke(0x30, 0x8006);
    // debug::poke(0x31, 0x30);

    debug::poke(0x0, 0xc0);
    debug::poke(0x1, 0x800);
    debug::poke(0x2, 0x100);
    debug::poke(0x3, 0x80);
    debug::poke(0x4, 0x0);
    debug::poke(0x5, 0x0);
    debug::poke(0x6, 0x140);
    debug::poke(0x7, 0x1);
    debug::poke(0x8, 0x200b);
    debug::poke(0x9, 0xc806);
    debug::poke(0xa, 0x13);
    debug::poke(0xb, 0x40);
    debug::poke(0xc, 0x200);
    debug::poke(0xd, 0x4a);
    debug::poke(0xe, 0x8c1);
    debug::poke(0xf, 0x28c3);
    debug::poke(0x10, 0x2803);
    debug::poke(0x11, 0x8006);
    debug::poke(0x12, 0x8);
    debug::poke(0x13, 0x0);
    debug::poke(0x14, 0x69);
    debug::poke(0x15, 0x15);

    // Lets go
    sleep_ms(100);
    debug::unhalt();

    while(1);
}
