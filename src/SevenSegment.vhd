library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity SevenSegment is port(
    inp     : in	std_logic_vector(3 downto 0);
    outp	: out	std_logic_vector(6 downto 0)
);
end entity;

architecture behavior of SevenSegment is begin

    outp <= "0111111" when (inp = X"0") else
            "0000110" when (inp = X"1") else
            "1011011" when (inp = X"2") else
            "1001111" when (inp = X"3") else
            "1100110" when (inp = X"4") else
            "1101101" when (inp = X"5") else
            "1111101" when (inp = X"6") else
            "0000111" when (inp = X"7") else
            "1111111" when (inp = X"8") else
            "1101111" when (inp = X"9") else
            "1110111" when (inp = X"A") else
            "1111100" when (inp = X"B") else
            "0111001" when (inp = X"C") else
            "1011110" when (inp = X"D") else
            "1111001" when (inp = X"E") else
            "1110001" when (inp = X"F") else
            "0000000";

end architecture;