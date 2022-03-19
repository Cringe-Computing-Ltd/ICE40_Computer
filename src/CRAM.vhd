library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity CRAM is port(
	-- Read port
    r_clk	: in	std_logic;
    r_addr	: in	std_logic_vector(10 downto 0);
    r_data	: out	std_logic_vector(7 downto 0);

    --  Write port
    w_clk	: in	std_logic;
    w_e  	: in	std_logic;
    w_addr	: in	std_logic_vector(9 downto 0);
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

    signal bram_wes     : std_logic_vector(3 downto 0);
begin

    -- Instantiate all BRAMs
    bram0   : ice_bram port map(rclk => r_clk, raddr => r_addr(8 downto 1), rdata => bram0_rdata, wclk => w_clk, we => bram_wes(0), waddr => w_addr(7 downto 0), wdata => w_data);
    bram1   : ice_bram port map(rclk => r_clk, raddr => r_addr(8 downto 1), rdata => bram1_rdata, wclk => w_clk, we => bram_wes(1), waddr => w_addr(7 downto 0), wdata => w_data);
    bram2   : ice_bram port map(rclk => r_clk, raddr => r_addr(8 downto 1), rdata => bram2_rdata, wclk => w_clk, we => bram_wes(2), waddr => w_addr(7 downto 0), wdata => w_data);
    bram3   : ice_bram port map(rclk => r_clk, raddr => r_addr(8 downto 1), rdata => bram3_rdata, wclk => w_clk, we => bram_wes(3), waddr => w_addr(7 downto 0), wdata => w_data);
        
    -- Multiplex RDATA
    r_data <=       bram0_rdata(7 downto 0)  when ((r_addr(10 downto 9) = "00") and (r_addr(0) = '0')) else
                    bram0_rdata(15 downto 8) when ((r_addr(10 downto 9) = "00") and (r_addr(0) = '1')) else
                    bram1_rdata(7 downto 0)  when ((r_addr(10 downto 9) = "01") and (r_addr(0) = '0')) else
                    bram1_rdata(15 downto 8) when ((r_addr(10 downto 9) = "01") and (r_addr(0) = '1')) else
                    bram2_rdata(7 downto 0)  when ((r_addr(10 downto 9) = "10") and (r_addr(0) = '0')) else
                    bram2_rdata(15 downto 8) when ((r_addr(10 downto 9) = "10") and (r_addr(0) = '1')) else
                    bram3_rdata(7 downto 0)  when ((r_addr(10 downto 9) = "11") and (r_addr(0) = '0')) else
                    bram3_rdata(15 downto 8) when ((r_addr(10 downto 9) = "11") and (r_addr(0) = '1')) else
                    X"00";

    -- Multiplex WE
    bram_wes <= "0001" when (w_addr(9 downto 8) = "00") else
                "0010" when (w_addr(9 downto 8) = "01") else
                "0100" when (w_addr(9 downto 8) = "10") else
                "1000" when (w_addr(9 downto 8) = "11") else
                "0000";

end architecture behavior;