library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Computer is port(
    CLK_50	: in	std_logic;

    -- LEDs
    leds : out std_logic_vector(2 downto 0);

    -- VGA
    VGA_OUT : out std_logic_vector(2 downto 0);
    VGA_HS : out std_logic;
    VGA_VS : out std_logic;

    -- SPI Debugger Port
    SW : in std_logic_vector(7 downto 0);

    SEG_A : out std_logic_vector(6 downto 0);
    SEG_B : out std_logic_vector(6 downto 0);

    -- PS/2 Keyboard
    PS2_CLK     : in  std_logic;
    PS2_DATA    : in  std_logic
);
end entity;

architecture behavior of Computer is
    component VGA_GEN is port(
        -- Clock input
        CLK_50	        : in    std_logic;

        -- VGA Signals
        VGA_OUT         : out   std_logic_vector(2 downto 0);
        VGA_HS          : out   std_logic;
        VGA_VS          : out   std_logic;

        -- 25.175MHz clock for the CPU
        CLK_25_175_out  : out   std_logic;

        -- VRAM write port
        VRAM_W_CLK      : in    std_logic;
        VRAM_W_E        : in    std_logic;
        VRAM_W_ADDR     : in    std_logic_vector(12 downto 0);
        VRAM_W_DATA     : in    std_logic_vector(15 downto 0);

        -- CRAM write port
        CRAM_W_CLK      : in    std_logic;
        CRAM_W_E        : in    std_logic;
        CRAM_W_ADDR     : in    std_logic_vector(9 downto 0);
        CRAM_W_DATA     : in    std_logic_vector(15 downto 0)
    );
    end component;

    component PS2Driver is port(
        PS2_CLK     :   in  std_logic;
        PS2_DATA    :   in  std_logic;

        BUF_R_CLK   :   in  std_logic;
        BUF_R_ADDR  :   in  std_logic_vector(7 downto 0);
        BUF_R_DATA  :   out std_logic_vector(15 downto 0)
    );
    end component;

    component CPU is port(
        CLK         : in std_logic;
        MEM_ADDR    : out std_logic_vector(15 downto 0);
        MEM_IN      : out std_logic_vector(15 downto 0);
        MEM_OUT     : in std_logic_vector(15 downto 0);
        MEM_WE      : out std_logic;
        HALT        : in  std_logic;
        INTERRUPT   : in  std_logic;
        DEBUG_OUT   : out std_logic_vector(7 downto 0)
    );
    end component;

    component Debugger is port(
        -- SPI Input from MCU
        SPI_CLK         : in    std_logic;
        SPI_DATA        : in    std_logic;
        SPI_RST         : in    std_logic;

        -- Memory interface to Mapper
        MAP_MEM_ADDR    : out   std_logic_vector(15 downto 0);
        MAP_MEM_IN      : out   std_logic_vector(15 downto 0);
        MAP_MEM_OUT     : in    std_logic_vector(15 downto 0);
        MAP_MEM_WE      : out   std_logic;

        -- Memory interface to CPU
        CPU_MEM_ADDR    : in    std_logic_vector(15 downto 0);
        CPU_MEM_IN      : in    std_logic_vector(15 downto 0);
        CPU_MEM_WE      : in    std_logic;
        CPU_HALT        : out   std_logic
    );
    end component;

    component MemoryMap is port(
        -- CPU Port
        CPU_ADDR    : in    std_logic_vector(15 downto 0);
        CPU_MEM_OUT : out   std_logic_vector(15 downto 0);
        CPU_WE      : in    std_logic;

        -- VRAM Port
        VRAM_ADDR   : out   std_logic_vector(12 downto 0);
        VRAM_WE     : out   std_logic;

        -- CRAM Port
        CRAM_ADDR   : out   std_logic_vector(9 downto 0);
        CRAM_WE     : out   std_logic;

        -- PS/2 Buffer
        PS2_ADDR    : out   std_logic_vector(7 downto 0);
        PS2_DATA    : in    std_logic_vector(15 downto 0);

        -- RAM Port
        RAM_OUT     : in    std_logic_vector(15 downto 0);
        RAM_WE      : out   std_logic
    );
    end component;

    component RAM is port(
        clk	        : in	std_logic;
        addr	    : in	std_logic_vector(15 downto 0);
        data_in     : in	std_logic_vector(15 downto 0);
        data_out	: out	std_logic_vector(15 downto 0);
        w_e         : in	std_logic
    );
    end component;

    -- TODO: MOVE THIS TO VHDL
    component SevenSegment is port(
        inp	        : in	std_logic_vector(3 downto 0);
        outp	    : out	std_logic_vector(6 downto 0)
    );
    end component;

    signal cnt          : std_logic_vector(25 downto 0) := "00000000000000000000000000";

    signal CLK_25_175   : std_logic;

    signal counter      : std_logic_vector(31 downto 0) := X"00000000";
    signal step         : std_logic_vector(3 downto 0) := X"0";

    signal VRAM_WE      : std_logic;
    signal VRAM_ADDR    : std_logic_vector(12 downto 0);

    signal CRAM_WE      : std_logic;
    signal CRAM_ADDR    : std_logic_vector(9 downto 0);

    signal RAM_DATA_OUT : std_logic_vector(15 downto 0);
    signal RAM_WE       : std_logic;

    signal CPU_ADDR     : std_logic_vector(15 downto 0);
    signal CPU_MEM_IN   : std_logic_vector(15 downto 0);
    signal CPU_MEM_OUT  : std_logic_vector(15 downto 0);
    signal CPU_MEM_WE   : std_logic;
    signal CPU_HALT     : std_logic;

    signal MAP_MEM_ADDR : std_logic_vector(15 downto 0);
    signal MAP_MEM_IN   : std_logic_vector(15 downto 0);
    signal MAP_MEM_OUT  : std_logic_vector(15 downto 0);
    signal MAP_MEM_WE   : std_logic;

    signal PS2_BUF_ADDR : std_logic_vector(7 downto 0);
    signal PS2_BUF_DATA : std_logic_vector(15 downto 0);
    signal CPU_CLK      : std_logic;

    signal startup_counter  : std_logic_vector(31 downto 0) := X"00000000";
    signal ram_ready : std_logic := '0';

    signal CPU_DEBUG_OUT  : std_logic_vector(7 downto 0);

    signal INV_PS2_CLK    : std_logic;

begin
    RTX_3090ti : VGA_GEN port map(
        CLK_50         => CLK_50,
        CLK_25_175_OUT  => CLK_25_175,
        VGA_OUT         => VGA_OUT,
        VGA_HS          => VGA_HS,
        VGA_VS          => VGA_VS,
        VRAM_W_CLK      => CPU_CLK,
        VRAM_W_E        => VRAM_WE,
        VRAM_W_ADDR     => VRAM_ADDR,
        VRAM_W_DATA     => MAP_MEM_IN,
        CRAM_W_CLK      => CPU_CLK,
        CRAM_W_E        => CRAM_WE,
        CRAM_W_ADDR     => CRAM_ADDR,
        CRAM_W_DATA     => MAP_MEM_IN
    );

    ThreadRipperPro : CPU port map(
        CLK         => CPU_CLK,
        MEM_ADDR    => CPU_ADDR,
        MEM_IN      => CPU_MEM_IN,
        MEM_OUT     => MAP_MEM_OUT,
        MEM_WE      => CPU_MEM_WE,
        HALT        => CPU_HALT,
        INTERRUPT   => '0',
        DEBUG_OUT   => CPU_DEBUG_OUT
    );

    ramtest : RAM port map(
        clk	        => CPU_CLK,
        addr	    => MAP_MEM_ADDR,
        data_in     => MAP_MEM_IN,
        data_out	=> RAM_DATA_OUT,
        w_e         => RAM_WE
    );

    debug : Debugger port map(
        -- SPI Input from MCU
        SPI_CLK         => SW(0),
        SPI_DATA        => SW(1),
        SPI_RST         => SW(2),

        -- Memory interface to Mapper
        MAP_MEM_ADDR    => MAP_MEM_ADDR,
        MAP_MEM_IN      => MAP_MEM_IN,
        MAP_MEM_OUT     => MAP_MEM_OUT,
        MAP_MEM_WE      => MAP_MEM_WE,

        -- Memory interface to CPU
        CPU_MEM_ADDR    => CPU_ADDR,
        CPU_MEM_IN      => CPU_MEM_IN,
        CPU_MEM_WE      => CPU_MEM_WE,
        CPU_HALT        => CPU_HALT
    );

    segA : SevenSegment port map(
        inp	        => CPU_DEBUG_OUT(3 downto 0),
        outp	    => SEG_A
    );

    segB : SevenSegment port map(
        inp	        => CPU_DEBUG_OUT(7 downto 4),
        outp	    => SEG_B
    );

    mmap : MemoryMap port map(
        CPU_ADDR    => MAP_MEM_ADDR,
        CPU_MEM_OUT => MAP_MEM_OUT,
        CPU_WE      => MAP_MEM_WE,
        VRAM_ADDR   => VRAM_ADDR,
        VRAM_WE     => VRAM_WE,
        CRAM_ADDR   => CRAM_ADDR,
        CRAM_WE     => CRAM_WE,
        PS2_ADDR    => PS2_BUF_ADDR,
        PS2_DATA    => PS2_BUF_DATA,
        RAM_OUT     => RAM_DATA_OUT,
        RAM_WE      => RAM_WE
    );

    INV_PS2_CLK <= not PS2_CLK;

    typewriter : PS2Driver port map(
        PS2_CLK     => INV_PS2_CLK,
        PS2_DATA    => PS2_DATA,

        BUF_R_CLK   => CPU_CLK,
        BUF_R_ADDR  => PS2_BUF_ADDR,
        BUF_R_DATA  => PS2_BUF_DATA
    );

    -- leds <= "110" when (cnt(24 downto 23) = "00") else
    --         "101" when (cnt(24 downto 23) = "01") else
    --         "011" when (cnt(24 downto 23) = "10") else
    --         "101";

    leds <= not ((not PS2_CLK) & SW(1 downto 0));

    CPU_CLK <= cnt(1);

    process(CLK_25_175) begin
        if(rising_edge(CLK_25_175)) then
            cnt <= cnt + 1;
            if (startup_counter /= 524288) then
                startup_counter <= startup_counter + 1;
            else
                ram_ready <= '1';
            end if;
        end if;
    end process;
    
end architecture;
