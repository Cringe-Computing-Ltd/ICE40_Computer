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
    component ICE40_VGA is port(
        CLK_100	: in	std_logic;
        VGA_OUT : out std_logic_vector(2 downto 0);
        VGA_HS : out std_logic;
        VGA_VS : out std_logic;
        CLK_25_175_out : out std_logic
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
    RTX_3090ti : ICE40_VGA port map(
        CLK_100 => CLK_100,
        CLK_25_175_OUT => CLK_25_175,
        VGA_OUT => VGA_OUT,
        VGA_HS => VGA_HS,
        VGA_VS => VGA_VS
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