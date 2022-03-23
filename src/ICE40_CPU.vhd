library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ICE40_CPU is port(
    CLK : in std_logic;
    MEM_ADDR : out std_logic_vector(15 downto 0);
    MEM_IN : out std_logic_vector(15 downto 0);
    MEM_OUT : in std_logic_vector(15 downto 0)
);
end entity;

architecture mannerisms of ICE40_CPU is
    type EXEC_STATES is (FETCH, IDLE, LOAD, EXEC, CONTD, SKIP, RELOAD);
    signal ip : std_logic_vector(15 downto 0) := "0000000000000000";
    signal state : EXEC_STATES := FETCH;
    signal state_after_idle : EXEC_STATES;
    
    signal opcode : std_logic_vector(3 downto 0);
    signal dst : std_logic_vector(3 downto 0);
    signal src : std_logic_vector (3 downto 0);
    signal dst_content : std_logic_vector(15 downto 0);
    signal src_content : std_logic_vector(15 downto 0);

    -- [nf, sf, cf, XXX]
    signal flags : std_logic_vector(3 downto 0) := "0000";


    signal regs : std_logic_vector((16 * 8 - 1) downto 0);
    signal a : std_logic_vector(15 downto 0);
    signal b : std_logic_vector(15 downto 0);
    signal c : std_logic_vector(15 downto 0);
    signal d : std_logic_vector(15 downto 0);
    signal e : std_logic_vector(15 downto 0);
    signal f : std_logic_vector(15 downto 0);
    signal g : std_logic_vector(15 downto 0);
    signal h : std_logic_vector(15 downto 0);


    signal multmp : std_logic_vector(31 downto 0);

begin
    -- insert mem things
    process(CLK)
        variable carrier_tmp : std_logic_vector(16 downto 0);

        variable dst_content : std_logic_vector(15 downto 0);
        variable src_content : std_logic_vector(15 downto 0);
    begin
        if(rising_edge(CLK)) then
            case state is
                when FETCH => 
                    MEM_ADDR <= ip;

                    state <= IDLE;
                    state_after_idle <= LOAD;

                when IDLE =>
                    state <= state_after_idle;

                when LOAD =>
                    -- TODO: get rid and this state and make it 
                    opcode <= MEM_OUT(3 downto 0);

                    -- dst
                    dst <= MEM_OUT(7 downto 4);

                    -- src
                    src <= MEM_OUT(11 downto 8);

                    -- map dst with actual register
                    case MEM_OUT(7 downto 4) is
                        when "0000" =>
                            dst_content <= a;
                        when "0001" =>
                            dst_content <= b;
                        when "0010" =>
                            dst_content <= c;
                        when "0011" =>
                            dst_content <= d;
                        when "0100" =>
                            dst_content <= e;
                        when "0101" =>
                            dst_content <= f;
                        when "0110" =>
                            dst_content <= g;
                        when "0111" =>
                            dst_content <= h;
                        when others => null; -- to compile
                    end case;

                    --map src with acutal register
                    case MEM_OUT(11 downto 8) is
                        when "0000" =>
                            src_content <= a;
                        when "0001" =>
                            src_content <= b;
                        when "0010" =>
                            src_content <= c;
                        when "0011" =>
                            src_content <= d;
                        when "0100" =>
                            src_content <= e;
                        when "0101" =>
                            src_content <= f;
                        when "0110" =>
                            src_content <= g;
                        when "0111" =>
                            src_content <= h;
                        when others => null; -- to compile
                    end case;

                    -- check if complies to mask
                    if ((flags and MEM_OUT(15 downto 12)) = MEM_OUT(15 downto 12)) then
                        state <= SKIP;
                    else
                        state <= EXEC;
                    end if;
                
                when EXEC =>
                    
                    case opcode is
                        -- ldi: load imm into dst.
                        when "0000" =>
                            MEM_ADDR <= ip + 1;

                            state <= IDLE;
                            state_after_idle <= CONTD;
                            -- FALLTHROUGH CONTD

                        -- st: store src into [dst]
                        when "0001" =>
                            MEM_ADDR <= dst_content;
                            MEM_IN <= src_content;
                        
                            ip <= ip + 1;

                            state <= IDLE;
                            state_after_idle <= FETCH;
                            -- END st
                        
                        -- ld: load [src] into dst
                        when "0010" =>
                            MEM_ADDR <= src_content;
                            
                            state <= IDLE;
                            state_after_idle <= CONTD;
                            -- FALLTHROUGH CONTD
                        
                        -- add: put dst+src into dst
                        when "0011" =>
                            carrier_tmp := ('0' & dst_content) + ('0' & src_content);

                            -- set result
                            dst_content <= carrier_tmp(15 downto 0);

                            -- set cf (carry)
                            flags(2) <= carrier_tmp(16);

                            ip <= ip + 1;
                            state <= RELOAD;
                            -- END add
                        
                        -- sub: put dst-src into dst
                        when "0100" =>
                            carrier_tmp := ('0' & dst_content) - ('0' & src_content);

                            -- set result
                            dst_content <= carrier_tmp(15 downto 0);

                            -- set cf (carry)
                            flags(2) <= carrier_tmp(16);
                            
                            ip <= ip + 1;
                            state <= RELOAD;
                            -- END sub
                        
                        -- mul: put dst*src into d:dst ()
                        when "0101" =>
                            multmp <= dst_content*src_content;

                            flags(2) <= '0';

                            state <= CONTD;
                            -- FALLTHROUGH CONTD
                        
                        -- jmp: jump to dst
                        when "0110" =>
                            ip <= dst_content;

                            state <= FETCH;
                            -- END jmp

                        -- xchg: exchange dst and src
                        when "0111" =>
                            dst_content <= src_content;
                            src_content <= dst_content;

                            ip <= ip + 1;
                            state <= RELOAD;
                            -- END xchg
                        
                        -- xor: dst = dst xor b
                        when "1000" =>
                            dst_content <= dst_content xor src_content;

                            ip <= ip + 1;
                            state <= RELOAD;
                            -- END xor
                        
                        -- and: dst = dst and src
                        when "1001" =>
                            dst_content <= dst_content and src_content;

                            ip <= ip + 1;
                            state <= RELOAD;
                            -- 
                        
                        -- or: dst = dst or src
                        when "1010" =>
                            dst_content <= dst_content or src_content;

                            ip <= ip + 1;
                            state <= RELOAD;

                        -- cmp: compares dst and src
                        when "1011" =>
                            carrier_tmp := ('0' & dst_content) - ('0' & src_content);

                            if (carrier_tmp(15 downto 0) = "0000000000000000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;

                            flags(1) <= carrier_tmp(15);
                            flags(2) <= carrier_tmp(16);

                            ip <= ip + 1;
                            state <= FETCH;
                            -- END cmp
                        
                        -- sti: store dst into imm
                        when "1100" =>
                            MEM_ADDR <= ip + 1;
                            MEM_IN <= dst_content;

                            ip <= ip + 2;

                            state <= IDLE;
                            state_after_idle <= FETCH;
                            -- END sti
                        when others => null; -- to compile
                    end case;

                when CONTD =>
                    case opcode is
                        -- ldi: load imm into dst. (suite)
                        when "0000" =>
                            dst_content <= MEM_OUT;

                            ip <= ip + 2;
                            state <= RELOAD;
                            -- END ldi
                        
                        -- ld: load [src] into dst. (suite)
                        when "0010" =>
                            dst_content <= MEM_OUT;

                            ip <= ip + 1;
                            state <= RELOAD;
                            -- END ld
                        
                        -- mul: put dst*src into d:dst ()
                        when "0101" =>
                            dst_content <= multmp(15 downto 0);
                            d <= multmp(31 downto 16);

                            ip <= ip + 1;
                            state <= RELOAD;
                            -- END mul
                        when others => null; -- to compile
                    end case;
                
                -- skip
                when SKIP =>
                    case opcode is
                        -- ldi: need skip 2
                        when "0000" =>
                            ip <= ip + 2;
                        when "1100" =>
                            ip <= ip + 2;
                        when others =>
                            ip <= ip + 1;
                    end case;
                    state <= FETCH;


                -- reload value in dst.
                when RELOAD =>
                    -- remap dst_content into according dst
                    case dst is
                        when "0000" =>
                            a <= dst_content;
                        when "0001" =>
                            b <= dst_content;
                        when "0010" =>
                            c <= dst_content;
                        when "0011" =>
                            d <= dst_content;
                        when "0100" =>
                            e <= dst_content;
                        when "0101" =>
                            f <= dst_content;
                        when "0110" =>
                            g <= dst_content;
                        when "0111" =>
                            h <= dst_content;
                        when others => null; -- to compile
                    end case;

                    -- remap src_content into according src
                    case src is
                        when "0000" =>
                            a <= src_content;
                        when "0001" =>
                            b <= src_content;
                        when "0010" =>
                            c <= src_content;
                        when "0011" =>
                            d <= src_content;
                        when "0100" =>
                            e <= src_content;
                        when "0101" =>
                            f <= src_content;
                        when "0110" =>
                            g <= src_content;
                        when "0111" =>
                            h <= src_content;
                        when others => null; -- to compile
                    end case;

                    -- set zf (zero flag)
                    if (dst_content = "0000000000000000") then
                        flags(0) <= '1';
                    else
                        flags(0) <= '0';
                    end if;

                    -- set sf (sign flag)
                    flags(1) <= dst_content(15);

                    state <= FETCH;
            end case;     
                
            
        end if;
    end process;
end mannerisms ; -- mannerisms




