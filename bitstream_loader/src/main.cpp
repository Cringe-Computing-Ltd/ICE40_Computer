#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "../../build/bitstream.h"
#include "font.h"
#include "raccoon.h"
#include "board.h"

int main() {
    stdio_init_all();

    // Init onboard LED
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
    gpio_put(PICO_DEFAULT_LED_PIN, 0);

    // Initialize the FPGA and seven segment displays
    board::init();
    seven_segment::enable(true, true);
    fpga::configure(build_ICE40_Computer_bin, build_ICE40_Computer_bin_len);

    // Turn on LED to indicate init is complete
    gpio_put(PICO_DEFAULT_LED_PIN, 1);

    while (1);

    // // Signal end of load by shutting down the LED
    // gpio_put(PICO_DEFAULT_LED_PIN, 0);

    // sleep_ms(1000);

    // const int GPU_MISO =  16;
    // const int GPU_MOSI =  19;
    // const int GPU_CLK  =  18;
    // const int GPU_CRAM =  20;
    // const int GPU_RESET = 21;

    // // Configure GPIO
    // gpio_set_function(GPU_MISO, GPIO_FUNC_SPI); // MISO
    // gpio_set_function(GPU_MOSI, GPIO_FUNC_SPI); // MOSI
    // gpio_set_function(GPU_CLK, GPIO_FUNC_SPI); // CLK
    // gpio_init(GPU_CRAM); // CRAM
    // gpio_init(GPU_RESET); // RESET
    // gpio_set_dir(GPU_CRAM, GPIO_OUT);
    // gpio_set_dir(GPU_RESET, GPIO_OUT);
    // gpio_put(GPU_CRAM, 0);
    // gpio_put(GPU_RESET, 0);

    // // Initialize SPI
    // spi_init(spi0, 16000000);
    // spi_set_format(spi0, 16, SPI_CPOL_0, SPI_CPHA_0, SPI_LSB_FIRST);

    // const unsigned short testfont[] = {0x1E0C,
    //                                     0x3333,
    //                                     0x333F,
    //                                     0x0033};

    // // Reset SPI
    // unsigned short allzero = 0x00;
    // unsigned short allone = 0xF0F0;
    // gpio_put(GPU_RESET, 1);
    // spi_write16_blocking(spi0, &allzero, 1);
    // gpio_put(GPU_RESET, 0);

    // // Write CRAM with all 1
    // gpio_put(GPU_CRAM, 1);
    // for (int i = 0; i < 128; i++) {
    //     unsigned short line0 = ((unsigned short)font8x8_basic[i][1] << 8) | (unsigned short)font8x8_basic[i][0];
    //     unsigned short line1 = ((unsigned short)font8x8_basic[i][3] << 8) | (unsigned short)font8x8_basic[i][2];
    //     unsigned short line2 = ((unsigned short)font8x8_basic[i][5] << 8) | (unsigned short)font8x8_basic[i][4];
    //     unsigned short line3 = ((unsigned short)font8x8_basic[i][7] << 8) | (unsigned short)font8x8_basic[i][6];
    //     spi_write16_blocking(spi0, &line0, 1);
    //     spi_write16_blocking(spi0, &line1, 1);
    //     spi_write16_blocking(spi0, &line2, 1);
    //     spi_write16_blocking(spi0, &line3, 1);
    // }
    // unsigned char test = 0;
    // spi_write_blocking(spi0, &test, 1);

    // // Reset again
    // gpio_put(GPU_RESET, 1);
    // spi_write16_blocking(spi0, &allzero, 1);
    // gpio_put(GPU_RESET, 0);

    // // Write VRAM
    // unsigned short ccode = 0x0000;
    // gpio_put(GPU_CRAM, 0);
    // for (int i = 0; i < 80*60; i++) {
    //     int x = i % 80;
    //     int y = i / 80;

    //     if (y < 58) {
    //         ccode = 0x0300 | raccoon[i];
    //     }
    //     else {
    //         ccode = 0x0F00;
    //     }

    //     spi_write16_blocking(spi0, &ccode, 1);
    // }
    // spi_write_blocking(spi0, &test, 1);

    // gpio_put(PICO_DEFAULT_LED_PIN, 1);

    // int col = 0;
    // while(1) {
    //     // Reset
    //     gpio_put(GPU_RESET, 1);
    //     spi_write16_blocking(spi0, &allzero, 1);
    //     gpio_put(GPU_RESET, 0);

    //     gpio_put(GPU_CRAM, 0);

    //     ccode = 0x0F00 | (col % 128);
    //     spi_write16_blocking(spi0, &ccode, 1);
        
    //     spi_write_blocking(spi0, &test, 1);

    //     sleep_ms(50);
    //     col++;
    // }
}
