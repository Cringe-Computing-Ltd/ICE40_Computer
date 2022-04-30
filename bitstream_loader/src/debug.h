#pragma once
#include <stdint.h>

#define DEBUG_BAUDRATE  128000

// Comm pins
#define DEBUG_CLK       18
#define DEBUG_MOSI      19
#define DEBUG_RST       20

namespace debug {
    enum Command {
        HALT    = 0,
        UNHALT  = 1,
        POKE    = 2
    };

    void init();
    void reset();
    void command(uint16_t cmd, uint16_t arg0 = 0, uint16_t arg1 = 0);
    void halt();
    void unhalt();
    void poke(uint16_t addr, uint16_t data);
};