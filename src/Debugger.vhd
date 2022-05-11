library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Debugger command format
--
--  Op  Arg0 Arg1 Clock
-- 0000 0000 0000 ----

-- Debugger commands
-- 
-- 0000: Halt
-- 0001: Un-halt
-- 0002: Poke

entity Debugger is port(
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
    CPU_HALT        : out   std_logic := '1'
);
end entity;

architecture behavior of Debugger is
    -- Config
    signal OVERRIDE     : std_logic := '0';

    -- SPI State
    signal N_WORD       : std_logic_vector(1 downto 0) := "00";
    signal WORD_BIT     : std_logic_vector(3 downto 0) := X"0";
    signal SPI_WORD     : std_logic_vector(15 downto 0) := X"0000";

    -- Command buffer
    signal CMD_W0       : std_logic_vector(15 downto 0) := X"0000";
    signal CMD_W1       : std_logic_vector(15 downto 0) := X"0000";
    signal CMD_W2       : std_logic_vector(15 downto 0) := X"0000";

    -- Memory driving signals
    signal DEB_MEM_ADDR : std_logic_vector(15 downto 0) := X"0000";
    signal DEB_MEM_IN   : std_logic_vector(15 downto 0) := X"0000";
    signal DEB_MEM_WE   : std_logic := '0';
begin

    -- Memory control MUX
    MAP_MEM_ADDR    <= DEB_MEM_ADDR when (OVERRIDE = '1') else CPU_MEM_ADDR;
    MAP_MEM_IN      <= DEB_MEM_IN   when (OVERRIDE = '1') else CPU_MEM_IN;
    MAP_MEM_WE      <= DEB_MEM_WE   when (OVERRIDE = '1') else CPU_MEM_WE;
    
    -- SPI State Machine
    process (SPI_CLK)
        variable NEW_SPI_WORD : std_logic_vector(15 downto 0);
    begin
        if (rising_edge(SPI_CLK)) then
            if (SPI_RST = '1') then
                -- Config
                OVERRIDE <= '0';

                -- SPI State
                N_WORD <= "00";
                WORD_BIT <= X"0";
                SPI_WORD <= X"0000";

                -- Command buffer
                CMD_W0 <= X"0000";
                CMD_W1 <= X"0000";
                CMD_W2 <= X"0000";

                -- Memory driving signals
                DEB_MEM_ADDR <= X"0000";
                DEB_MEM_IN <= X"0000";
                DEB_MEM_WE <= '0';
                
            else
                NEW_SPI_WORD := std_logic_vector(shift_left(unsigned(SPI_WORD), 1)) or ("000000000000000" & SPI_DATA);
                SPI_WORD <= NEW_SPI_WORD;

                case (N_WORD) is
                    when "00" => CMD_W0 <= NEW_SPI_WORD;
                    when "01" => CMD_W1 <= NEW_SPI_WORD;
                    when "10" => CMD_W2 <= NEW_SPI_WORD;
                    when "11" =>
                        -- Execute
                        case (CMD_W0) is
                            when X"0000" => CPU_HALT <= '1';
                            when X"0001" => CPU_HALT <= '0';
                            when X"0002" =>
                                case (WORD_BIT) is
                                    when X"0" => OVERRIDE <= '1';
                                    when X"2" =>
                                        DEB_MEM_ADDR <= CMD_W1;
                                        DEB_MEM_IN <= CMD_W2;
                                        DEB_MEM_WE <= '1';
                                    when X"4" =>
                                        DEB_MEM_WE <= '0';
                                    when X"6" => OVERRIDE <= '0';
                                    when others => null;
                                end case;
                            when others => null;
                        end case;
                    when others => null;
                end case;

                -- If on the last bit, increment word counter
                if (WORD_BIT = X"F") then
                    N_WORD <= N_WORD + "01";
                end if;

                -- Increment bit counter
                WORD_BIT <= WORD_BIT + X"1";

            end if;
        end if;
    end process;
end;