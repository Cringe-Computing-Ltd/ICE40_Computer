library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity PS2Driver is port(
    PS2_CLK     :   in  std_logic;
    PS2_DATA    :   in  std_logic;

    BUF_R_CLK   :   in  std_logic;
    BUF_R_ADDR  :   in  std_logic_vector(7 downto 0);
    BUF_R_DATA  :   out std_logic_vector(15 downto 0)
);
end entity;

architecture behavior of PS2Driver is
    --signals
    signal cnt          :   std_logic_vector(3 downto 0)    := X"0";
    signal data_raw     :   std_logic_vector(10 downto 0)   := "00000000000";
    signal buf_pos      :   std_logic_vector(6 downto 0)    := "0000000";

    -- Totally not cursed cross-clock thingy
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

    -- Buffer signals
    signal buf_we   :   std_logic := '0';
    signal buf_addr :   std_logic_vector(7 downto 0);
    signal buf_data :   std_logic_vector(15 downto 0);
begin

    -- Instantiate buffer
    kbd_buffer   : ice_bram port map(rclk => BUF_R_CLK, raddr => BUF_R_ADDR, rdata => BUF_R_DATA, wclk => PS2_CLK, we => buf_we, waddr => buf_addr, wdata => buf_data);

    process(PS2_CLK)
        --variables
        variable new_data_raw : std_logic_vector(10 downto 0);
    begin
        if(rising_edge(PS2_CLK)) then
            new_data_raw := PS2_DATA & data_raw(10 downto 1);
            data_raw <= new_data_raw;

            case (cnt) is
                when X"8" =>
                    cnt <= cnt + 1;

                    buf_addr <= '0' & buf_pos;
                    buf_data <= X"00" & new_data_raw(10 downto 3);
                    buf_we <= '1';

                    buf_pos <= buf_pos + 1;

                when X"9" =>
                    cnt <= cnt + 1;

                    buf_addr <= X"FF";
                    buf_data <= "000000000" & buf_pos;

                when X"A" =>
                    cnt <= X"0";

                    buf_we <= '0';

                when others =>
                    cnt <= cnt + 1;
            end case;

        end if;
    end process;
end architecture;