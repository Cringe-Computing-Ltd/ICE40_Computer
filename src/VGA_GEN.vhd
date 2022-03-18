library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity VGA_GEN is port(
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
    CRAM_W_ADDR     : in    std_logic_vector(10 downto 0);
    CRAM_W_DATA     : in    std_logic_vector(15 downto 0)
);
end entity;

architecture behavior of VGA_GEN is
    -- Define PLL
    component ice_pll is port(
        clk_in : in std_logic;
        clk_out : out std_logic
    ); 
    end component ice_pll;

    -- Define VRAM
    component VRAM is port(
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
    end component;

    -- Define CRAM
    component CRAM is port(
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
    end component;

    -- VGA Pixel clock
    signal CLK_25_175 : std_logic;

    -- Pixel cursor
    signal cursor_x : std_logic_vector(9 downto 0) := "0000000000";
    signal cursor_y : std_logic_vector(9 downto 0) := "0000000000";

    -- Character line bitmap
    signal bitmap : std_logic_vector(7 downto 0) := "00001111";

    -- Foreground and background color
    signal foreground : std_logic_vector(2 downto 0) := "011";
    signal background : std_logic_vector(2 downto 0) := "100";

    -- VRAM Signals
    signal VRAM_addr : std_logic_vector(12 downto 0) := "0000000000000";
    signal VRAM_data : std_logic_vector(15 downto 0);

    -- CRAM Signals
    signal CRAM_addr : std_logic_vector(10 downto 0);
    signal CRAM_data : std_logic_vector(15 downto 0);

    -- Bitmap to be loaded intro work bitmap
    signal next_bitmap : std_logic_vector(7 downto 0) := "00000000";

    -- Foreground and background colors to be loaded in work registers
    signal next_foreground : std_logic_vector(2 downto 0) := "011";
    signal next_background : std_logic_vector(2 downto 0) := "100";

    -- Bitmap line vertical offset of the next character
    signal next_char_y : std_logic_vector(2 downto 0);

begin
    -- Instantiate PLL to generate the 25.175MHz pixel clock
    VGA_PLL : ice_pll port map (
        clk_in => CLK_100,
        clk_out => CLK_25_175
    );

    -- Instantiate VRAM
    GDDR6X : VRAM port map(
        r_clk => CLK_25_175, 
        r_addr => VRAM_addr,
        r_data => VRAM_data,
        w_clk => VRAM_W_CLK,
        w_e => VRAM_W_E,
        w_addr => VRAM_W_ADDR,
        w_data => VRAM_W_DATA
    );

    -- Instantiate CRAM
    Wingdings : CRAM port map (
        r_clk => CLK_25_175,
        r_addr => CRAM_addr,
        r_data => CRAM_data,
        w_clk => CRAM_W_CLK,
        w_e => CRAM_W_E,
        w_addr => CRAM_W_ADDR,
        w_data => CRAM_W_DATA
    );

    -- Output the pixel clock for the CPU
    CLK_25_175_OUT <= CLK_25_175;

    process(CLK_25_175)
        -- VRAM line skip word count
        variable vram_stride : std_logic_vector(13 downto 0);

        -- Text cursor position
        variable text_x : std_logic_vector(6 downto 0);
        variable text_y : std_logic_vector(6 downto 0);

        -- Character pixel position
        variable char_x : std_logic_vector(2 downto 0);
        variable char_y : std_logic_vector(2 downto 0);

        -- Char code to load into CRAM address
        variable char_code : std_logic_vector(7 downto 0);

        -- CRAM character skip word count
        variable cram_stride : std_logic_vector(11 downto 0);

    begin
        if(rising_edge(CLK_25_175)) then
            -- Advance cursor
            if(cursor_x = 799) then
                if(cursor_y = 524) then
                    cursor_y <= "0000000000";
                else
                    cursor_y <= cursor_y + 1;
                end if;
                cursor_x <= "0000000000";
            else
                cursor_x <= cursor_x + 1;
            end if;

            -- Generate HSync signal
            if ((cursor_x >= 656) and (cursor_x < 752)) then
                VGA_HS <= '1';
            else
                VGA_HS <= '0';
            end if;

            -- Generate VSync signal
            if ((cursor_y >= 490) and (cursor_y < 492)) then
                VGA_VS <= '1';
            else
                VGA_VS <= '0';
            end if;

            -- Generate output            
            if ((cursor_x >= 640) or (cursor_y >= 480)) then
                VGA_OUT <= "000";
            elsif (bitmap(to_integer(unsigned(cursor_x(2 downto 0)))) = '1') then
                VGA_OUT <= foreground;
            else
                VGA_OUT <= background;
            end if;

            -- Set Variables
            text_x := cursor_x(9 downto 3);
            text_y := cursor_y(9 downto 3);
            char_x := cursor_x(2 downto 0);
            char_y := cursor_y(2 downto 0);

            -- Only do character loading within the drawing area
            if ((cursor_x < 640) and (cursor_y < 480)) then
                case char_x is
                    -- STEP 1: Determin address of the next character to load and set VRAM address
                    when "000" => 
                        --Bottom of Last character in last line
                        if((text_x = 79) and (cursor_y = 479)) then
                            VRAM_addr <= "0000000000000";
                            next_char_y <= "000";

                        --Bottom of Last character of a line
                        elsif((text_x = 79) and (char_y = 7)) then
                            vram_stride := "1010000"*(text_y+1); -- 80 * (text_y+1)
                            VRAM_addr <= vram_stride(12 downto 0);
                            next_char_y <= "000";

                        --Last character
                        elsif (text_x = 79) then
                            vram_stride := "1010000"*text_y; -- 80 * text_y
                            VRAM_addr <= vram_stride(12 downto 0);
                            next_char_y <= char_y + 1;
                        
                        -- Any other character
                        else
                            vram_stride := "1010000"*text_y; -- 80 * text_y
                            VRAM_addr <= vram_stride(12 downto 0) + (text_x+1);
                            next_char_y <= char_y;
                        end if;

                    -- STEP 2: Decode output of VRAM and save into staging registers
                    when "010" =>
                        -- Decode VRAM output
                        char_code := VRAM_data(7 downto 0);
                        next_foreground <= VRAM_data(10 downto 8);
                        next_background <= VRAM_data(13 downto 11);
                        
                        -- Load CRAM address
                        cram_stride := char_code * X"8";
                        CRAM_addr <= cram_stride(10 downto 0) + next_char_y;
    
                    -- STEP 3: Update work registers with staging registers and CRAM output
                    when "111" =>
                        -- Update display registers
                        bitmap <= CRAM_data(7 downto 0);
                        foreground <= next_foreground;
                        background <= next_background;

                    when others => null;
                end case;
            end if;
        end if;
    end process;

end behavior;