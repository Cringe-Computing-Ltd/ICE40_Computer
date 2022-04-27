#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"
#include "../../build/bitstream.h"
#include "font.h"

#define UPLOAD_BAUDRATE 16000000

#define FPGA_RS     13
#define FPGA_MISO   12
#define FPGA_MOSI   11
#define FPGA_CLK    10
#define FPGA_CS     9

void ice40_select(bool selected) {
    gpio_put(FPGA_CS, !selected);
}

void ice40_reset() {
    gpio_put(FPGA_RS, 0);
    sleep_us(1);
    gpio_put(FPGA_RS, 1);
    sleep_ms(2);
}

int main() {
    stdio_init_all();

    // Enable both 7-segment displays
    gpio_init(8);
    gpio_init(15);
    gpio_set_dir(8, GPIO_OUT);
    gpio_set_dir(15, GPIO_OUT);
    gpio_put(8, 1);
    gpio_put(15, 1);

    // Wait 100ms for power to stabalize at the FPGA
    sleep_ms(100);
    
    // Configure GPIO
    gpio_set_function(FPGA_MISO, GPIO_FUNC_SPI);
    gpio_set_function(FPGA_MOSI, GPIO_FUNC_SPI);
    gpio_set_function(FPGA_CLK, GPIO_FUNC_SPI);
    bi_decl(bi_3pins_with_func(FPGA_MISO, FPGA_MOSI, FPGA_CLK, GPIO_FUNC_SPI));
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_init(FPGA_RS);
    gpio_init(FPGA_CS);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
    gpio_set_dir(FPGA_RS, GPIO_OUT);
    gpio_set_dir(FPGA_CS, GPIO_OUT);
    gpio_put(PICO_DEFAULT_LED_PIN, 1);
    gpio_put(FPGA_RS, 1);
    gpio_put(FPGA_CS, 1);

    // Initialize SPI
    spi_init(spi1, UPLOAD_BAUDRATE);

    // ===== BITSTREAM LOADING PROCEDURE
    
    // (1) Select device
    ice40_select(true);

    // (2) Reset the FPGA into slave mode
    ice40_reset();
    ice40_select(false);
    uint8_t dummy_uint = 0;
    spi_write_blocking(spi1, &dummy_uint, 1);
    ice40_select(true);

    // (3) Load the bitstream
    spi_write_blocking(spi1, build_ICE40_Computer_bin, build_ICE40_Computer_bin_len);

    // (4) Add 64 more SPI clock cycles to complete initialization
    const uint8_t dummy_blank[16] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    spi_write_blocking(spi1, dummy_blank, 16);

    // (5) Deselect device
    ice40_select(false);

    // Signal end of load by shutting down the LED
    gpio_put(PICO_DEFAULT_LED_PIN, 0);

    sleep_ms(1000);

    const int GPU_MISO =  16;
    const int GPU_MOSI =  19;
    const int GPU_CLK  =  18;
    const int GPU_CRAM =  20;
    const int GPU_RESET = 21;

    // Configure GPIO
    gpio_set_function(GPU_MISO, GPIO_FUNC_SPI); // MISO
    gpio_set_function(GPU_MOSI, GPIO_FUNC_SPI); // MOSI
    gpio_set_function(GPU_CLK, GPIO_FUNC_SPI); // CLK
    bi_decl(bi_3pins_with_func(GPU_MISO, GPU_MOSI, GPU_CLK, GPIO_FUNC_SPI));
    gpio_init(GPU_CRAM); // CRAM
    gpio_init(GPU_RESET); // RESET
    gpio_set_dir(GPU_CRAM, GPIO_OUT);
    gpio_set_dir(GPU_RESET, GPIO_OUT);
    gpio_put(GPU_CRAM, 0);
    gpio_put(GPU_RESET, 0);

    // Initialize SPI
    spi_init(spi0, 40000000);
    spi_set_format(spi0, 16, SPI_CPOL_0, SPI_CPHA_0, SPI_LSB_FIRST);

    const unsigned short testfont[] = {0x1E0C,
                                        0x3333,
                                        0x333F,
                                        0x0033};

    // Reset SPI
    unsigned short allzero = 0x00;
    unsigned short allone = 0xF0F0;
    gpio_put(GPU_RESET, 1);
    spi_write16_blocking(spi0, &allzero, 1);
    gpio_put(GPU_RESET, 0);

    // Write CRAM with all 1
    gpio_put(GPU_CRAM, 1);
    for (int i = 0; i < 128; i++) {
        unsigned short line0 = (font8x8_basic[i*8][0] << 8) | font8x8_basic[i*8][1];
        unsigned short line1 = (font8x8_basic[i*8][2] << 8) | font8x8_basic[i*8][3];
        unsigned short line2 = (font8x8_basic[i*8][4] << 8) | font8x8_basic[i*8][5];
        unsigned short line3 = (font8x8_basic[i*8][6] << 8) | font8x8_basic[i*8][7];
        spi_write16_blocking(spi0, &line0, 1);
        spi_write16_blocking(spi0, &line1, 1);
        spi_write16_blocking(spi0, &line2, 1);
        spi_write16_blocking(spi0, &line3, 1);
    }

    // Reset again
    gpio_put(GPU_RESET, 1);
    spi_write16_blocking(spi0, &allzero, 1);
    gpio_put(GPU_RESET, 0);

    // Write VRAM
    unsigned short ccode = 0x0E00;
    gpio_put(GPU_CRAM, 0);
    for (int i = 0; i < 80*60; i++) {
        ccode = 0x0F00 | (i % 256);
        spi_write16_blocking(spi0, &ccode, 1);
    }
    unsigned char test = 0;
    spi_write_blocking(spi0, &test, 1);

    gpio_put(PICO_DEFAULT_LED_PIN, 1);


    while(1);
}
