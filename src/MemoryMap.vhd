library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity MemoryMap is port(
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
end entity MemoryMap;

architecture behavior of MemoryMap is
	signal wes : std_logic_vector(2 downto 0);
begin

ROM_ADDR <= CPU_ADDR(10 downto 0);
VRAM_ADDR <= CPU_ADDR - X"0800";
CRAM_ADDR <= CPU_ADDR - X"2000";

CPU_MEM_OUT <=  ROM_OUT when (CPU_ADDR(15 downto 11) = "00000") else
                RAM_OUT;

wes <=  "000" when (CPU_WE = '0') else
        "001" when ((CPU_ADDR(15 downto 11) >= "00001") and (CPU_ADDR(15 downto 11) < "00100")) else
        "010" when (CPU_ADDR(15 downto 11) = "00100") else
        "100";

VRAM_WE <= wes(0);
CRAM_WE <= wes(1);
RAM_WE  <= wes(2);

end architecture behavior;