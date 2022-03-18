library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ICE40_Computer is port(
	CLK_100	: in	std_logic;
	leds : out std_logic_vector(2 downto 0);
    VGA_OUT : out std_logic_vector(2 downto 0);
    VGA_HS : out std_logic;
    VGA_VS : out std_logic
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
        CRAM_W_ADDR     : in    std_logic_vector(10 downto 0);
        CRAM_W_DATA     : in    std_logic_vector(15 downto 0)
    );
    end component;

    component ICE40_CPU is port(
        CLK : in std_logic;
        MEM_ADDR : out std_logic_vector(15 downto 0);
        MEM_IN : out std_logic_vector(15 downto 0);
        MEM_OUT : in std_logic_vector(15 downto 0)
    );
    end component;

    signal cnt : std_logic_vector(25 downto 0) := "00000000000000000000000000";

    signal CLK_25_175 : std_logic;

begin
    RTX_3090ti : VGA_GEN port map(
        CLK_100 => CLK_100,
        CLK_25_175_OUT => CLK_25_175,
        VGA_OUT => VGA_OUT,
        VGA_HS => VGA_HS,
        VGA_VS => VGA_VS,
        VRAM_W_CLK => '0',
        VRAM_W_E => '0',
        VRAM_W_ADDR => "0000000000000",
        VRAM_W_DATA => X"0000",
        CRAM_W_CLK => '0',
        CRAM_W_E => '0',
        CRAM_W_ADDR => "00000000000",
        CRAM_W_DATA => X"0000"
    );

    ThreadRipperPro : ICE40_CPU port map(
        CLK => CLK_25_175,
        MEM_ADDR => open,
        MEM_IN => open,
        MEM_OUT => X"0000"
    );

    process(CLK_100)
    begin
        if(rising_edge(CLK_100)) then
            cnt <= cnt + 1;
        end if;
        leds <= NOT cnt(25 downto 23); 
    end process;
end behavior;