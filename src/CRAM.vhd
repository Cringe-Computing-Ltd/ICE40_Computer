library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity CRAM is port(
	-- Read port
    r_clk	: in	std_logic;
    r_addr	: in	std_logic_vector(10 downto 0);
    r_data	: out	std_logic_vector(15 downto 0);

    --  Write port
    w_clk	: in	std_logic;
    w_e  	: in	std_logic;
    w_addr	: in	std_logic_vector(10 downto 0);
    w_data	: in	std_logic_vector(15 downto 0)
);
end entity CRAM;

architecture behavior of CRAM is
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
	end component ice_bram;

    -- Wiring
    signal bram0_rdata  : std_logic_vector(15 downto 0);
    signal bram1_rdata  : std_logic_vector(15 downto 0);
    signal bram2_rdata  : std_logic_vector(15 downto 0);
    signal bram3_rdata  : std_logic_vector(15 downto 0);
    signal bram4_rdata  : std_logic_vector(15 downto 0);
    signal bram5_rdata  : std_logic_vector(15 downto 0);
    signal bram6_rdata  : std_logic_vector(15 downto 0);
    signal bram7_rdata  : std_logic_vector(15 downto 0);

    signal bram_wes     : std_logic_vector(7 downto 0);
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
    
    -- Multiplex RDATA
    r_data <=       bram0_rdata when (r_addr(10 downto 8) = "000") else
                    bram1_rdata when (r_addr(10 downto 8) = "001") else
                    bram2_rdata when (r_addr(10 downto 8) = "010") else
                    bram3_rdata when (r_addr(10 downto 8) = "011") else
                    bram4_rdata when (r_addr(10 downto 8) = "100") else
                    bram5_rdata when (r_addr(10 downto 8) = "101") else
                    bram6_rdata when (r_addr(10 downto 8) = "110") else
                    bram7_rdata when (r_addr(10 downto 8) = "111") else
                    X"0000";

    -- Multiplex WE
    bram_wes <= "00000001" when (r_addr(10 downto 8) = "000") else
                "00000010" when (r_addr(10 downto 8) = "001") else
                "00000100" when (r_addr(10 downto 8) = "010") else
                "00001000" when (r_addr(10 downto 8) = "011") else
                "00010000" when (r_addr(10 downto 8) = "100") else
                "00100000" when (r_addr(10 downto 8) = "101") else
                "01000000" when (r_addr(10 downto 8) = "110") else
                "10000000" when (r_addr(10 downto 8) = "111") else
                "00000000";

end architecture behavior;