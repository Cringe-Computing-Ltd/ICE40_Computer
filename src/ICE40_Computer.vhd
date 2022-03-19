library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ICE40_Computer is port(
	CLK_100	: in	std_logic;
	leds : out std_logic_vector(2 downto 0);
    VGA_OUT : out std_logic_vector(2 downto 0);
    VGA_HS : out std_logic;
    VGA_VS : out std_logic
);
end entity ICE40_Computer;

architecture behavior of ICE40_Computer is
    component VGA_GEN is port(
        -- Clock input
        CLK_100	        : in    std_logic;

        -- VGA Signals
        VGA_OUT         : out   std_logic_vector(2 downto 0);
        VGA_HS          : out   std_logic;
        VGA_VS          : out   std_logic;

        -- 25.175MHz clock for the CPU
        CLK_25_175_out  : out   std_logic;

        -- VRAM write port
        VRAM_W_CLK      : in    std_logic;
        VRAM_W_E        : in    std_logic;
        VRAM_W_ADDR     : in    std_logic_vector(12 downto 0);
        VRAM_W_DATA     : in    std_logic_vector(15 downto 0);

        -- CRAM write port
        CRAM_W_CLK      : in    std_logic;
        CRAM_W_E        : in    std_logic;
        CRAM_W_ADDR     : in    std_logic_vector(9 downto 0);
        CRAM_W_DATA     : in    std_logic_vector(15 downto 0)
    );
    end component;

    component ICE40_CPU is port(
        CLK         : in std_logic;
        MEM_ADDR    : out std_logic_vector(15 downto 0);
        MEM_IN      : out std_logic_vector(15 downto 0);
        MEM_OUT     : in std_logic_vector(15 downto 0)
    );
    end component;

    signal cnt          : std_logic_vector(25 downto 0) := "00000000000000000000000000";

    signal CLK_25_175   : std_logic;

    signal counter      : std_logic_vector(31 downto 0) := X"00000000";
    signal step         : std_logic_vector(3 downto 0) := X"0";

    signal VRAM_WE      : std_logic := '0';
    signal VRAM_ADDR    : std_logic_vector(12 downto 0) := "0000000000000";
    signal VRAM_DATA    : std_logic_vector(15 downto 0) := X"0000";

    signal CRAM_WE      : std_logic := '0';
    signal CRAM_ADDR    : std_logic_vector(9 downto 0) := "0000000000";
    signal CRAM_DATA    : std_logic_vector(15 downto 0) := X"0000";

begin
    RTX_3090ti : VGA_GEN port map(
        CLK_100         => CLK_100,
        CLK_25_175_OUT  => CLK_25_175,
        VGA_OUT         => VGA_OUT,
        VGA_HS          => VGA_HS,
        VGA_VS          => VGA_VS,
        VRAM_W_CLK      => CLK_25_175,
        VRAM_W_E        => VRAM_WE,
        VRAM_W_ADDR     => VRAM_ADDR,
        VRAM_W_DATA     => VRAM_DATA,
        CRAM_W_CLK      => CLK_25_175,
        CRAM_W_E        => CRAM_WE,
        CRAM_W_ADDR     => CRAM_ADDR,
        CRAM_W_DATA     => CRAM_DATA
    );

    ThreadRipperPro : ICE40_CPU port map(
        CLK         => CLK_25_175,
        MEM_ADDR    => open,
        MEM_IN      => open,
        MEM_OUT     => X"0000"
    );

    -- process(CLK_100)
    -- begin
    --     if(rising_edge(CLK_100)) then
    --         cnt <= cnt + 1;
    --     end if;
    --     leds <= NOT cnt(25 downto 23); 
    -- end process;

    leds <= "110" when (cnt(24 downto 23) = "00") else
            "101" when (cnt(24 downto 23) = "01") else
            "011" when (cnt(24 downto 23) = "10") else
            "101";

    process(CLK_25_175)
    begin

        if(rising_edge(CLK_25_175)) then
        
            cnt <= cnt + 1;

            case step is

                when "0000" =>
                    VRAM_ADDR <= counter(12 downto 0);
                    -- if (counter(12 downto 0) = "0000000000000") then
                    --     VRAM_DATA <= X"4300";
                    -- else
                    --     VRAM_DATA <= X"0000";
                    -- end if;

                    VRAM_DATA <= '0' & counter(5 downto 3) & '0' & counter(2 downto 0) & X"00";
                    
                    VRAM_WE <= '1';
                    
                    CRAM_ADDR <= counter(9 downto 0);
                    case counter(1 downto 0) is
                        when "00" => CRAM_DATA <= X"1E0C";
                        when "01" => CRAM_DATA <= X"3333";
                        when "10" => CRAM_DATA <= X"333F";
                        when "11" => CRAM_DATA <= X"0033";
                        when others => CRAM_DATA <= X"0000";
                    end case;
                    CRAM_WE <= '1';

                    step <= "0001";

                when "0001" => step <= "0010";

                when "0010" =>
                    VRAM_WE <= '0';
                    CRAM_WE <= '0';

                    step <= "0011";

                when "0011" =>
                    step <= "0000";
                    counter <= counter + 1;
                when others => step <= "0000";
            end case;


        end if;
    end process;
    
end behavior;