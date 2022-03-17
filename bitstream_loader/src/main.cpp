#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"
#include "../../build/bitstream.h"

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

    while(1);
}
