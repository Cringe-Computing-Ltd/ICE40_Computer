library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity VRAM is port(
	-- Read port
    r_clk	: in	std_logic;
    r_addr	: in	std_logic_vector(12 downto 0);
    r_data	: out	std_logic_vector(15 downto 0);

    --  Write port
    w_clk	: in	std_logic;
    w_e  	: in	std_logic;
    w_addr	: in	std_logic_vector(12 downto 0);
    w_data	: in	std_logic_vector(15 downto 0)
);
end entity;

architecture behavior of VRAM is
	-- Block RAM Declaration
	component ice_bram is port (
		-- Read port
		rclk	: in	std_logic;
		raddr	: in	std_logic_vector(7 downto 0);
		rdata	: out	std_logic_vector(15 downto 0);

		--  Write port
		wclk	: in	std_logic;
		we  	: in	std_logic;
		waddr	: in	std_logic_vector(7 downto 0);
		wdata	: in	std_logic_vector(15 downto 0)
	);
	end component;

    -- Wiring
    signal bram0_rdata  : std_logic_vector(15 downto 0);
    signal bram1_rdata  : std_logic_vector(15 downto 0);
    signal bram2_rdata  : std_logic_vector(15 downto 0);
    signal bram3_rdata  : std_logic_vector(15 downto 0);
    signal bram4_rdata  : std_logic_vector(15 downto 0);
    signal bram5_rdata  : std_logic_vector(15 downto 0);
    signal bram6_rdata  : std_logic_vector(15 downto 0);
    signal bram7_rdata  : std_logic_vector(15 downto 0);
    signal bram8_rdata  : std_logic_vector(15 downto 0);
    signal bram9_rdata  : std_logic_vector(15 downto 0);
    signal bram10_rdata : std_logic_vector(15 downto 0);
    signal bram11_rdata : std_logic_vector(15 downto 0);
    signal bram12_rdata : std_logic_vector(15 downto 0);
    signal bram13_rdata : std_logic_vector(15 downto 0);
    signal bram14_rdata : std_logic_vector(15 downto 0);
    signal bram15_rdata : std_logic_vector(15 downto 0);
    signal bram16_rdata : std_logic_vector(15 downto 0);
    signal bram17_rdata : std_logic_vector(15 downto 0);
    signal bram18_rdata : std_logic_vector(15 downto 0);

    signal bram_wes     : std_logic_vector(18 downto 0);
begin

    -- Instantiate all BRAMs
    bram0   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram0_rdata, wclk => w_clk, we => bram_wes(0), waddr => w_addr(7 downto 0), wdata => w_data);
    bram1   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram1_rdata, wclk => w_clk, we => bram_wes(1), waddr => w_addr(7 downto 0), wdata => w_data);
    bram2   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram2_rdata, wclk => w_clk, we => bram_wes(2), waddr => w_addr(7 downto 0), wdata => w_data);
    bram3   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram3_rdata, wclk => w_clk, we => bram_wes(3), waddr => w_addr(7 downto 0), wdata => w_data);
    bram4   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram4_rdata, wclk => w_clk, we => bram_wes(4), waddr => w_addr(7 downto 0), wdata => w_data);
    bram5   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram5_rdata, wclk => w_clk, we => bram_wes(5), waddr => w_addr(7 downto 0), wdata => w_data);
    bram6   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram6_rdata, wclk => w_clk, we => bram_wes(6), waddr => w_addr(7 downto 0), wdata => w_data);
    bram7   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram7_rdata, wclk => w_clk, we => bram_wes(7), waddr => w_addr(7 downto 0), wdata => w_data);
    bram8   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram8_rdata, wclk => w_clk, we => bram_wes(8), waddr => w_addr(7 downto 0), wdata => w_data);
    bram9   : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram9_rdata, wclk => w_clk, we => bram_wes(9), waddr => w_addr(7 downto 0), wdata => w_data);
    bram10  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram10_rdata, wclk => w_clk, we => bram_wes(10), waddr => w_addr(7 downto 0), wdata => w_data);
    bram11  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram11_rdata, wclk => w_clk, we => bram_wes(11), waddr => w_addr(7 downto 0), wdata => w_data);
    bram12  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram12_rdata, wclk => w_clk, we => bram_wes(12), waddr => w_addr(7 downto 0), wdata => w_data);
    bram13  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram13_rdata, wclk => w_clk, we => bram_wes(13), waddr => w_addr(7 downto 0), wdata => w_data);
    bram14  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram14_rdata, wclk => w_clk, we => bram_wes(14), waddr => w_addr(7 downto 0), wdata => w_data);
    bram15  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram15_rdata, wclk => w_clk, we => bram_wes(15), waddr => w_addr(7 downto 0), wdata => w_data);
    bram16  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram16_rdata, wclk => w_clk, we => bram_wes(16), waddr => w_addr(7 downto 0), wdata => w_data);
    bram17  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram17_rdata, wclk => w_clk, we => bram_wes(17), waddr => w_addr(7 downto 0), wdata => w_data);
    bram18  : ice_bram port map(rclk => r_clk, raddr => r_addr(7 downto 0), rdata => bram18_rdata, wclk => w_clk, we => bram_wes(18), waddr => w_addr(7 downto 0), wdata => w_data);

    -- Multiplex RDATA
    r_data <=       bram0_rdata when (r_addr(12 downto 8) = "00000") else
                    bram1_rdata when (r_addr(12 downto 8) = "00001") else
                    bram2_rdata when (r_addr(12 downto 8) = "00010") else
                    bram3_rdata when (r_addr(12 downto 8) = "00011") else
                    bram4_rdata when (r_addr(12 downto 8) = "00100") else
                    bram5_rdata when (r_addr(12 downto 8) = "00101") else
                    bram6_rdata when (r_addr(12 downto 8) = "00110") else
                    bram7_rdata when (r_addr(12 downto 8) = "00111") else
                    bram8_rdata when (r_addr(12 downto 8) = "01000") else
                    bram9_rdata when (r_addr(12 downto 8) = "01001") else
                    bram10_rdata when (r_addr(12 downto 8) = "01010") else
                    bram11_rdata when (r_addr(12 downto 8) = "01011") else
                    bram12_rdata when (r_addr(12 downto 8) = "01100") else
                    bram13_rdata when (r_addr(12 downto 8) = "01101") else
                    bram14_rdata when (r_addr(12 downto 8) = "01110") else
                    bram15_rdata when (r_addr(12 downto 8) = "01111") else
                    bram16_rdata when (r_addr(12 downto 8) = "10000") else
                    bram17_rdata when (r_addr(12 downto 8) = "10001") else
                    bram18_rdata when (r_addr(12 downto 8) = "10010") else
                    X"0000";

    -- Multiplex WE
    bram_wes <= "0000000000000000000" when (w_e = '0') else
                "0000000000000000001" when (w_addr(12 downto 8) = "00000") else
                "0000000000000000010" when (w_addr(12 downto 8) = "00001") else
                "0000000000000000100" when (w_addr(12 downto 8) = "00010") else
                "0000000000000001000" when (w_addr(12 downto 8) = "00011") else
                "0000000000000010000" when (w_addr(12 downto 8) = "00100") else
                "0000000000000100000" when (w_addr(12 downto 8) = "00101") else
                "0000000000001000000" when (w_addr(12 downto 8) = "00110") else
                "0000000000010000000" when (w_addr(12 downto 8) = "00111") else
                "0000000000100000000" when (w_addr(12 downto 8) = "01000") else
                "0000000001000000000" when (w_addr(12 downto 8) = "01001") else
                "0000000010000000000" when (w_addr(12 downto 8) = "01010") else
                "0000000100000000000" when (w_addr(12 downto 8) = "01011") else
                "0000001000000000000" when (w_addr(12 downto 8) = "01100") else
                "0000010000000000000" when (w_addr(12 downto 8) = "01101") else
                "0000100000000000000" when (w_addr(12 downto 8) = "01110") else
                "0001000000000000000" when (w_addr(12 downto 8) = "01111") else
                "0010000000000000000" when (w_addr(12 downto 8) = "10000") else
                "0100000000000000000" when (w_addr(12 downto 8) = "10001") else
                "1000000000000000000" when (w_addr(12 downto 8) = "10010") else
                "0000000000000000000";

end architecture;