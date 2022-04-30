#include "debug.h"
#include "pico/stdlib.h"
#include "hardware/spi.h"

namespace debug {
    void init() {
        // Init reset pin
        gpio_init(DEBUG_RST);
        gpio_set_dir(DEBUG_RST, GPIO_OUT);
        gpio_put(DEBUG_RST, 0);
        
        // Init SPI controller
        gpio_set_function(DEBUG_MOSI, GPIO_FUNC_SPI);
        gpio_set_function(DEBUG_CLK, GPIO_FUNC_SPI);
        spi_init(spi0, DEBUG_BAUDRATE);
        spi_set_format(spi0, 16, SPI_CPOL_0, SPI_CPHA_0, SPI_LSB_FIRST);

        // Reset debugger
        reset();
    }

    void reset() {
        uint16_t dummy = 0;
        gpio_put(DEBUG_RST, 1);
        spi_write16_blocking(spi0, &dummy, 1);
        gpio_put(DEBUG_RST, 0);
    }

    void command(uint16_t cmd, uint16_t arg0, uint16_t arg1) {
        uint16_t dummy = 0;
        spi_write16_blocking(spi0, &cmd, 1);
        spi_write16_blocking(spi0, &arg0, 1);
        spi_write16_blocking(spi0, &arg1, 1);
        spi_write16_blocking(spi0, &dummy, 1);
    }
    
    void halt() {
        command(Command::HALT);
        sleep_ms(100);
    }

    void unhalt() {
        command(Command::UNHALT);
        sleep_ms(100);
    }

    void poke(uint16_t addr, uint16_t data) {
        command(Command::POKE, addr, data);
    }
};