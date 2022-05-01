library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity MemoryMap is port(
	-- CPU Port
    CPU_ADDR    : in    std_logic_vector(15 downto 0);
    CPU_MEM_OUT : out   std_logic_vector(15 downto 0);
    CPU_WE      : in    std_logic;

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
    signal tmp_vram_addr : std_logic_vector(15 downto 0);
    signal tmp_cram_addr : std_logic_vector(15 downto 0);
begin


tmp_vram_addr <= CPU_ADDR - X"E000";
tmp_cram_addr <= CPU_ADDR - X"F800";

VRAM_ADDR <= tmp_vram_addr(12 downto 0);
CRAM_ADDR <= tmp_cram_addr(9 downto 0);

CPU_MEM_OUT <= RAM_OUT;

wes <=  "000" when (CPU_WE = '0') else
        "001" when ((CPU_ADDR(15 downto 11) >= "11100") and (CPU_ADDR(15 downto 11) < "11111")) else
        "010" when (CPU_ADDR(15 downto 11) = "11111") else
        "100";

VRAM_WE <= wes(0);
CRAM_WE <= wes(1);
RAM_WE  <= wes(2);

end architecture behavior;