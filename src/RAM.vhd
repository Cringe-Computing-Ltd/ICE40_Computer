library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity RAM is port(
    clk	        : in	std_logic;
    addr	    : in	std_logic_vector(15 downto 0);
    data_in     : in	std_logic_vector(15 downto 0);
    data_out	: out	std_logic_vector(15 downto 0);
    w_e         : in	std_logic
);
end entity;

architecture behavior of RAM is
	-- Block RAM Declaration
	component ice_spram is port (
		ram_clk	        : in	std_logic;
		ram_addr	    : in	std_logic_vector(13 downto 0);
        ram_data_in	    : in	std_logic_vector(15 downto 0);
        ram_data_out    : out	std_logic_vector(15 downto 0);
        ram_we  	    : in	std_logic
	);
	end component;

    -- Wiring
    signal spram0_data_out  : std_logic_vector(15 downto 0);
    signal spram1_data_out  : std_logic_vector(15 downto 0);
    signal spram2_data_out  : std_logic_vector(15 downto 0);
    signal spram3_data_out  : std_logic_vector(15 downto 0);

    signal spram_wes     : std_logic_vector(3 downto 0);
begin

    -- Instantiate all BRAMs
    spram0  : ice_spram port map(ram_clk => clk, ram_addr => addr(13 downto 0), ram_data_in => data_in, ram_data_out => spram0_data_out, ram_we => spram_wes(0));
    spram1  : ice_spram port map(ram_clk => clk, ram_addr => addr(13 downto 0), ram_data_in => data_in, ram_data_out => spram1_data_out, ram_we => spram_wes(1));
    spram2  : ice_spram port map(ram_clk => clk, ram_addr => addr(13 downto 0), ram_data_in => data_in, ram_data_out => spram2_data_out, ram_we => spram_wes(2));
    spram3  : ice_spram port map(ram_clk => clk, ram_addr => addr(13 downto 0), ram_data_in => data_in, ram_data_out => spram3_data_out, ram_we => spram_wes(3));

    -- Multiplex RDATA
    data_out    <=  spram0_data_out when (addr(15 downto 14) = "00") else
                    spram1_data_out when (addr(15 downto 14) = "01") else
                    spram2_data_out when (addr(15 downto 14) = "10") else
                    spram3_data_out when (addr(15 downto 14) = "11") else
                    X"0000";

    -- Multiplex WE
    spram_wes <=    "0000" when (w_e = '0') else
                    "0001" when (addr(15 downto 14) = "00") else
                    "0010" when (addr(15 downto 14) = "01") else
                    "0100" when (addr(15 downto 14) = "10") else
                    "1000" when (addr(15 downto 14) = "11") else
                    "0000";

end architecture;