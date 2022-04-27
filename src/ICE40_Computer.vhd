library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ICE40_Computer is port(
	CLK_100	: in	std_logic;
	leds : out std_logic_vector(2 downto 0);
    VGA_OUT : out std_logic_vector(2 downto 0);
    VGA_HS : out std_logic;
    VGA_VS : out std_logic;
    BTN : in std_logic_vector(1 downto 0);
    SW : in std_logic_vector(7 downto 0);
    SEG_A : out std_logic_vector(6 downto 0);
    SEG_B : out std_logic_vector(6 downto 0)
);
end entity ICE40_Computer;

architecture behavior of ICE40_Computer is
    component VGA_GEN is port(
        -- Clock input
        CLK_100	        : in    std_logic;

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

    component Debug is port(
        spi_cram    : in	std_logic;
        spi_rst     : in	std_logic;
        spi_clk	    : in	std_logic;
        spi_data    : in	std_logic;
        vram_addr   : out	std_logic_vector(12 downto 0);
        vram_data   : out	std_logic_vector(15 downto 0);
        vram_e      : out	std_logic;
        cram_addr   : out	std_logic_vector(9 downto 0);
        cram_data   : out	std_logic_vector(15 downto 0);
        cram_e      : out	std_logic;
        TEMP_OUT   : out	std_logic_vector(15 downto 0)
    );
    end component Debug;

    component ICE40_CPU is port(
        CLK         : in std_logic;
        MEM_ADDR    : out std_logic_vector(15 downto 0);
        MEM_IN      : out std_logic_vector(15 downto 0);
        MEM_OUT     : in std_logic_vector(15 downto 0);
        MEM_WE      : out std_logic
    );
    end component;

    component MemoryMap is port(
        -- CPU Port
        CPU_ADDR    : in    std_logic_vector(15 downto 0);
        CPU_MEM_OUT : out   std_logic_vector(15 downto 0);
        CPU_WE      : in    std_logic;

        -- ROM Port
        ROM_ADDR    : out   std_logic_vector(10 downto 0);
        ROM_OUT     : in    std_logic_vector(15 downto 0);

        -- VRAM Port
        VRAM_ADDR   : out   std_logic_vector(12 downto 0);
        VRAM_WE     : out   std_logic;

        -- CRAM Port
        CRAM_ADDR   : out   std_logic_vector(9 downto 0);
        CRAM_WE     : out   std_logic;

        -- RAM Port
        RAM_OUT     : in    std_logic_vector(15 downto 0);
        RAM_WE      : out   std_logic
    );
    end component;

    component ROM is port(
        r_clk	: in	std_logic;
        r_addr	: in	std_logic_vector(10 downto 0);
        r_data	: out	std_logic_vector(15 downto 0);

        w_clk   : in	std_logic;
        w_e  	: in	std_logic;
        w_addr	: in	std_logic_vector(10 downto 0);
        w_data	: in	std_logic_vector(15 downto 0)
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

    component SevenSegment is port(
        inp	: in std_logic_vector(3 downto 0);
        outp : out	std_logic_vector(6 downto 0)
    );
    end component;

    signal cnt          : std_logic_vector(25 downto 0) := "00000000000000000000000000";

    signal CLK_25_175   : std_logic;

    signal counter      : std_logic_vector(31 downto 0) := X"00000000";
    signal step         : std_logic_vector(3 downto 0) := X"0";

    signal VRAM_CLK     : std_logic;
    signal VRAM_WE      : std_logic;
    signal VRAM_ADDR    : std_logic_vector(12 downto 0);
    signal VRAM_DATA    : std_logic_vector(15 downto 0);

    signal CRAM_CLK     : std_logic;
    signal CRAM_WE      : std_logic;
    signal CRAM_ADDR    : std_logic_vector(9 downto 0);
    signal CRAM_DATA    : std_logic_vector(15 downto 0);

    signal ROM_ADDR    : std_logic_vector(10 downto 0);
    signal ROM_DATA    : std_logic_vector(15 downto 0);

    signal RAM_DATA_OUT : std_logic_vector(15 downto 0);
    signal RAM_WE       : std_logic;

    signal CPU_ADDR     : std_logic_vector(15 downto 0);
    signal CPU_MEM_IN   : std_logic_vector(15 downto 0);
    signal CPU_MEM_OUT  : std_logic_vector(15 downto 0);
    signal CPU_MEM_WE   : std_logic;

    signal CPU_CLK      : std_logic;

    signal startup_counter  : std_logic_vector(31 downto 0) := X"00000000";
    signal ram_ready : std_logic := '0';

    signal DEBUG_OUT  : std_logic_vector(15 downto 0);

begin
    RTX_3090ti : VGA_GEN port map(
        CLK_100         => CLK_100,
        CLK_25_175_OUT  => CLK_25_175,
        VGA_OUT         => VGA_OUT,
        VGA_HS          => VGA_HS,
        VGA_VS          => VGA_VS,
        VRAM_W_CLK      => SW(0),
        VRAM_W_E        => VRAM_WE,
        VRAM_W_ADDR     => VRAM_ADDR,
        VRAM_W_DATA     => VRAM_DATA,
        CRAM_W_CLK      => SW(0),
        CRAM_W_E        => CRAM_WE,
        CRAM_W_ADDR     => CRAM_ADDR,
        CRAM_W_DATA     => CRAM_DATA
    );

    ThreadRipperPro : ICE40_CPU port map(
        CLK         => CPU_CLK,
        MEM_ADDR    => CPU_ADDR,
        MEM_IN      => CPU_MEM_IN,
        MEM_OUT     => CPU_MEM_OUT,
        MEM_WE      => CPU_MEM_WE
    );

    bootloader : ROM port map(
        r_clk	=> CPU_CLK,
        r_addr	=> ROM_ADDR,
        r_data	=> ROM_DATA,

        w_clk   => '0',
        w_e  	=> '0',
        w_addr	=> "00000000000",
        w_data	=> "0000000000000000"
    );

    ramtest : RAM port map(
        clk	        => CPU_CLK,
        addr	    => CPU_ADDR,
        data_in     => CPU_MEM_IN,
        data_out	=> RAM_DATA_OUT,
        w_e         => RAM_WE
    );

    debugger : Debug port map(
        spi_cram    => SW(2),
        spi_rst     => SW(3),
        spi_clk	    => SW(0),
        spi_data    => SW(1),
        vram_addr   => VRAM_ADDR,
        vram_data   => VRAM_DATA,
        vram_e      => VRAM_WE,
        cram_addr   => CRAM_ADDR,
        cram_data   => CRAM_DATA,
        cram_e      => CRAM_WE,
        TEMP_OUT    => DEBUG_OUT
    );

    sega : SevenSegment port map(
        inp	  => DEBUG_OUT(3 downto 0),
        outp  => SEG_A
    );

    segb : SevenSegment port map(
        inp	  => DEBUG_OUT(7 downto 4),
        outp  => SEG_B
    );

    leds <= not SW(2 downto 0);
    

    -- mmap : MemoryMap port map(
    --     CPU_ADDR    => CPU_ADDR,
    --     CPU_MEM_OUT => CPU_MEM_OUT,
    --     CPU_WE      => CPU_MEM_WE,
    --     ROM_ADDR    => ROM_ADDR,
    --     ROM_OUT     => ROM_DATA,
    --     VRAM_ADDR   => VRAM_ADDR,
    --     VRAM_WE     => VRAM_WE,
    --     CRAM_ADDR   => CRAM_ADDR,
    --     CRAM_WE     => CRAM_WE,
    --     RAM_OUT     => RAM_DATA_OUT,
    --     RAM_WE      => RAM_WE
    -- );

    -- leds <= "110" when (cnt(24 downto 23) = "00") else
    --         "101" when (cnt(24 downto 23) = "01") else
    --         "011" when (cnt(24 downto 23) = "10") else
    --         "101";

    CPU_CLK <= cnt(1) and ram_ready;

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
    
end behavior;