library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ICE40_VGA is port(
	CLK_100	: in	std_logic;
	VGA_OUT : out std_logic_vector(2 downto 0);
    VGA_HS : out std_logic;
    VGA_VS : out std_logic;
    CLK_25_175_out : out std_logic
);
end entity;

architecture behavior of ICE40_VGA is
    -- Define PLL
    component ice_pll is port(
        clk_in : in std_logic;
        clk_out : out std_logic
    ); 
    end component ice_pll;

    -- Define VRAM
    component ICE40_VRAM is port(
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
    component ICE40_CRAM is port(
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

    signal CLK_25_175 : std_logic;

    signal cursor_x : std_logic_vector(9 downto 0) := "0000000000";
    signal cursor_y : std_logic_vector(9 downto 0) := "0000000000";

    signal bitmap : std_logic_vector(7 downto 0) := "00001111";
    signal foreground : std_logic_vector(2 downto 0) := "011";
    signal background : std_logic_vector(2 downto 0) := "100";

    signal VRAM_addr : std_logic_vector(12 downto 0) := "0000000000000";
    signal VRAM_data : std_logic_vector(15 downto 0);

    signal CRAM_addr : std_logic_vector(10 downto 0);
    signal CRAM_data : std_logic_vector(15 downto 0);

    signal next_char_y : std_logic_vector(2 downto 0);
    signal char_foreground : std_logic_vector(2 downto 0) := "011";
    signal char_background : std_logic_vector(2 downto 0) := "100";

    signal next_bitmap : std_logic_vector(7 downto 0) := "00000000";

    signal next_text_x_temp_do_not_use : std_logic_vector(6 downto 0);

begin
    VGA_PLL : ice_pll port map (
        clk_in => CLK_100,
        clk_out => CLK_25_175
    );

    GDDR6X : ICE40_VRAM port map(
        r_clk => CLK_25_175, 
        r_addr => VRAM_addr,
        r_data => VRAM_data,
        w_clk => '0',
        w_e => '0',
        w_addr => "0000000000000",
        w_data => "0000000000000000"
    );

    Wingdings : ICE40_CRAM port map (
        r_clk => CLK_25_175,
        r_addr => CRAM_addr,
        r_data => CRAM_data,
        w_clk => '0',
        w_e => '0',
        w_addr => "00000000000",
        w_data => "0000000000000000"
    );

    CLK_25_175_OUT <= CLK_25_175;

    process(CLK_25_175)
        variable vram_stride : std_logic_vector(13 downto 0);

        variable text_x : std_logic_vector(6 downto 0);
        variable text_y : std_logic_vector(6 downto 0);
        variable char_x : std_logic_vector(2 downto 0);
        variable char_y : std_logic_vector(2 downto 0);

        variable char_code : std_logic_vector(7 downto 0);
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

            -- Generate sync signals
            if ((cursor_x >= 656) and (cursor_x < 752)) then
                VGA_HS <= '1';
            else
                VGA_HS <= '0';
            end if;

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

            if ((cursor_x < 640) and (cursor_y < 480)) then
                case char_x is
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
                        else
                            vram_stride := "1010000"*text_y; -- 80 * text_y
                            VRAM_addr <= vram_stride(12 downto 0) + (text_x+1);
                            next_char_y <= char_y;
                        end if;
                    when "010" =>
                        -- Decode VRAM output
                        char_code := VRAM_data(7 downto 0);
                        char_foreground <= VRAM_data(10 downto 8);
                        char_background <= VRAM_data(13 downto 11);
                        
                        -- Load CRAM address
                        cram_stride := char_code * X"8";
                        CRAM_addr <= cram_stride(10 downto 0) + next_char_y;
    
                    when "111" =>
                        -- Update display registers
                        bitmap <= CRAM_data(7 downto 0);
                        foreground <= char_foreground;
                        background <= char_background;

                    --To compile
                    when others => null;
                end case;
            end if;
        end if;
    end process;

end behavior ; -- behavior