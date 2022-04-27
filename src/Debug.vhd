library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Debug is port(
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
end entity Debug;

architecture behavior of Debug is
    signal bitn : std_logic_vector(3 downto 0) := X"0";
    signal addr : std_logic_vector(15 downto 0) := X"0000";
    signal out_addr : std_logic_vector(15 downto 0) := X"0000";
    signal data : std_logic_vector(15 downto 0) := X"0000";
    signal out_data : std_logic_vector(15 downto 0) := X"0000";
begin
    vram_addr <= out_addr(12 downto 0);
    cram_addr <= out_addr(9 downto 0);
    vram_data <= out_data;
    cram_data <= out_data;

    TEMP_OUT <= data;

    process (spi_clk)
        variable new_data : std_logic_vector(15 downto 0);
    begin
        if (rising_edge(spi_clk)) then
            if (spi_rst = '1') then
                bitn <= X"0";
                addr <= X"0000";
                out_addr <= X"0000";
                data <= X"0000";
                out_data <= X"0000";
                cram_e <= '0';
                vram_e <= '0';
            else

                new_data := std_logic_vector(shift_left(unsigned(data), 1)) or ("000000000000000" & spi_data);
                
                if (bitn /= "1111") then
                    vram_e <= '0';
                    cram_e <= '0';
                    data <= new_data;
                else
                    vram_e <= not spi_cram;
                    cram_e <= spi_cram;

                    out_addr <= addr;
                    addr <= addr + X"0001";

                    out_data <= new_data;
                    data <= X"0000";
                end if;

                bitn <= bitn + X"1";

            end if;
        end if;
    end process;

end architecture behavior;