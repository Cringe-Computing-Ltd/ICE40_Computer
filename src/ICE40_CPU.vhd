library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ICE40_CPU is port(
    CLK : in std_logic;
    MEM_ADDR : out std_logic_vector(15 downto 0);
    MEM_IN : out std_logic_vector(15 downto 0);
    MEM_OUT : in std_logic_vector(15 downto 0);
    MEM_WE : out std_logic
);
end entity;

architecture mannerisms of ICE40_CPU is
    type EXEC_STATES is (FETCH, IDLE, EXEC, CONTD);
    type REGS_T is array (31 downto 0) of std_logic_vector(15 downto 0);
    signal ip : std_logic_vector(15 downto 0) := "0000000000000000";
    signal state : EXEC_STATES := FETCH;
    signal state_after_idle : EXEC_STATES;
    
    signal opcode_longlive : std_logic_vector(5 downto 0);
    signal dst_longlive : std_logic_vector(4 downto 0);
    signal src_longlive : std_logic_vector (4 downto 0);
    signal dst_content_longlive : std_logic_vector(15 downto 0);
    signal src_content_longlive : std_logic_vector(15 downto 0);

    -- [zf, sf, cf, Pizza]
    signal flags : std_logic_vector(3 downto 0) := "0000";


    signal regs : REGS_T;


    signal multmp : std_logic_vector(31 downto 0);

begin
    -- insert mem things

    process(CLK)
        variable carrier_tmp : std_logic_vector(16 downto 0);

        variable opcode : std_logic_vector(5 downto 0);
        variable src : std_logic_vector(4 downto 0);
        variable dst : std_logic_vector(4 downto 0);
        variable dst_content : std_logic_vector(15 downto 0);
        variable src_content : std_logic_vector(15 downto 0);

        variable tmp_content : std_logic_vector(15 downto 0) := "0000000000000000";
        variable jmp_cond_ok : std_logic := '0';

        -- TODO: get rid of this, probably unneeded.
        variable reload : std_logic := '0';
    begin
        if(rising_edge(CLK)) then
            case state is
                when FETCH => 
                    MEM_ADDR <= ip;
                    MEM_WE <= '0';

                    state <= IDLE;
                    state_after_idle <= EXEC;

                when IDLE =>
                    state <= state_after_idle;

                when EXEC =>
                    -- TODO: get rid and this state and make it 
                    opcode := MEM_OUT(5 downto 0);
                    opcode_longlive <= opcode;

                    -- reg ids
                    dst := MEM_OUT(10 downto 6);
                    src := MEM_OUT(15 downto 11);

                    dst_longlive <= dst;
                    src_longlive <= src;

                    dst_content := regs(to_integer(unsigned(dst)));
                    src_content := regs(to_integer(unsigned(src)));

                    dst_content_longlive <= dst_content;
                    src_content_longlive <= src_content;
                    
                    case opcode is
                        -- ldi: load imm into dst.
                        when "000000" =>
                            MEM_ADDR <= ip + 1;

                            state <= IDLE;
                            state_after_idle <= CONTD;
                            -- FALLTHROUGH CONTD

                        -- st: store src into [dst]
                        when "000001" =>
                            MEM_ADDR <= dst_content;
                            MEM_IN <= src_content;
                            MEM_WE <= '1';
                        
                            ip <= ip + 1;

                            state <= IDLE;
                            state_after_idle <= FETCH;
                            -- END st
                        
                        -- ld: load [src] into dst
                        when "000010" =>
                            MEM_ADDR <= src_content;
                            
                            state <= IDLE;
                            state_after_idle <= CONTD;
                            -- FALLTHROUGH CONTD
                        
                        -- add: put dst+src into dst
                        when "000011" =>
                            carrier_tmp := ('0' & dst_content) + ('0' & src_content);

                            -- set result
                            dst_content := carrier_tmp(15 downto 0);

                            -- set cf (carry)
                            flags(2) <= carrier_tmp(16);

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- END add
                        
                        -- sub: put dst-src into dst
                        when "000100" =>
                            carrier_tmp := ('0' & dst_content) - ('0' & src_content);

                            -- set result
                            dst_content := carrier_tmp(15 downto 0);

                            -- set cf (carry)
                            flags(2) <= carrier_tmp(16);
                            
                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- END sub
                        
                        -- mul: put dst*src into d:dst ()
                        when "000101" =>
                            multmp <= dst_content*src_content;

                            flags(2) <= '0';

                            state <= CONTD;
                            -- FALLTHROUGH CONTD
                        
                        -- jmp: jump to dst
                        when "000110" =>
                            case src(3 downto 0) is
                                -- unconditional
                                when "0000" =>
                                    jmp_cond_ok := '1';
                                -- ==
                                when "1110" =>
                                    jmp_cond_ok := flags(0);
                                -- !=
                                when "1111" =>
                                    jmp_cond_ok := not flags(0);
                                -- >
                                when "1000" =>
                                    jmp_cond_ok := not flags(1) and not flags(0);
                                -- >=
                                when "1001" =>
                                    jmp_cond_ok := not flags(1);
                                -- <
                                when "0100" =>
                                    jmp_cond_ok := flags(1);
                                -- <=
                                when "0101" =>
                                    jmp_cond_ok := flags(1) or flags(0);
                                -- carry
                                when "0001" =>
                                    jmp_cond_ok := flags(2);
                                when others => null;
                            end case;

                            -- condition ok
                            if (jmp_cond_ok = '1') then

                                -- jump immediate
                                if (src(4) = '1') then
                                    MEM_ADDR <= ip + 1;

                                    state_after_idle <= CONTD;
                                    state <= IDLE;
                                
                                
                                -- jmp to register
                                else
                                    ip <= dst_content;
                                    state <= FETCH;
                                end if;

                            -- condition not ok, jmp from immediate
                            elsif (src(4) = '1') then
                                ip <= ip + 2;
                                state <= FETCH;

                            -- condition not ok, jmp from register
                            else
                                ip <= ip + 1;
                                state <= FETCH;
                            end if;
                            -- END jmp

                        -- mov: exchange dst and src
                        when "000111" =>
                            tmp_content := src_content;
                            src_content := dst_content;
                            dst_content := tmp_content;

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- END xchg
                        
                        -- xor: dst = dst xor b
                        when "001000" =>
                            dst_content := dst_content xor src_content;

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- END xor
                        
                        -- and: dst = dst and src
                        when "001001" =>
                            dst_content := dst_content and src_content;

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- 
                        
                        -- or: dst = dst or src
                        when "001010" =>
                            dst_content := dst_content or src_content;

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;

                        -- cmp: compares dst and src
                        when "001011" =>
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
                        when "001100" =>
                            MEM_ADDR <= ip + 1;
                            MEM_IN <= dst_content;
                            MEM_WE <= '1';

                            ip <= ip + 2;

                            state <= IDLE;
                            state_after_idle <= FETCH;
                            -- END sti

                        -- shl: shift left
                        when "001101" => 
                            dst_content := std_logic_vector(shift_left(unsigned(dst_content), to_integer(unsigned(src_content))));
                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;

                        -- shr: shift right
                        when "001110" =>
                            dst_content := std_logic_vector(shift_right(unsigned(dst_content), to_integer(unsigned(src_content))));
                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                        
                        -- mov: move src into dst
                        when "001111" =>
                            tmp_content := src_content;
                            src_content := dst_content;
                            dst_content := src_content;

                            ip <= ip + 1;
                            reload := '1';
                            state <= FETCH;

                        -- inc: increment dst
                        when "010000" =>
                            carrier_tmp := ('0' & dst_content) + ('0' & "0000000000000001");

                            -- set result
                            dst_content := carrier_tmp(15 downto 0);

                            -- set cf (carry)
                            flags(2) <= carrier_tmp(16);

                            ip <= ip + 1;
                            reload := '1';
                            state <= FETCH;
                        
                        -- dec: decrement dst
                        when "010001" =>
                            carrier_tmp := ('0' & dst_content) - ('0' & "0000000000000001");

                            -- set result
                            dst_content := carrier_tmp(15 downto 0);

                            -- set cf (carry)
                            flags(2) <= carrier_tmp(16);

                            ip <= ip + 1;
                            reload := '1';
                            state <= FETCH;

                        -- pshi: push immediate
                        when "010010" =>
                            MEM_ADDR <= ip + 1;
                            regs(31) <= regs(31) - 1;

                            state_after_idle <= CONTD;
                            state <= IDLE;

                        -- psh: push dst
                        when "010011" =>
                            -- write dst_content into [rsp - 1]
                            MEM_ADDR <= regs(31) - 1;
                            MEM_IN <= dst_content;
                            MEM_WE <= '1';

                            -- decrement dst
                            regs(31) <= regs(31) - 1;

                            ip <= ip + 1;
                            state_after_idle <= FETCH;
                            state <= IDLE;

                        -- pop: pop to dst
                        when "010100" =>
                            MEM_ADDR <= regs(31);

                            regs(31) <= regs(31) + 1;
                            
                            state_after_idle <= CONTD;
                            state <= IDLE;

                        when others => null; -- to compile

                        if (reload = '1') then
                            regs(to_integer(unsigned(dst))) <= dst_content;
                            regs(to_integer(unsigned(src))) <= src_content;

                            -- set zf (zero flag)
                            if (dst_content = "0000000000000000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;

                            -- set sf (sign flag)
                            flags(1) <= dst_content(15);
                        end if;
                    end case;

                when CONTD =>
                    -- restore the variable
                    opcode := opcode_longlive;
                    dst := dst_longlive;
                    src := src_longlive;
                    dst_content := dst_content_longlive;
                    src_content := src_content_longlive;

                    case opcode is
                        -- ldi: load imm into dst. (suite)
                        when "000000" =>
                            dst_content := MEM_OUT;

                            ip <= ip + 2;

                            reload := '1';
                            state <= FETCH;
                            -- END ldi
                        
                        -- ld: load [src] into dst. (suite)
                        when "000010" =>
                            dst_content := MEM_OUT;

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- END ld
                        
                        -- mul: put dst*src into d:dst ()
                        when "000101" =>
                            dst_content := multmp(15 downto 0);
                            regs(3) <= multmp(31 downto 16);

                            ip <= ip + 1;

                            reload := '1';
                            state <= FETCH;
                            -- END mul
                        
                        -- jmp: contd for immediate
                        when "000110" =>
                            ip <= MEM_OUT;
                            state <= FETCH;

                        -- pshi: push immediate
                        when "010010" =>
                            MEM_ADDR <= regs(31);
                            MEM_IN <= MEM_OUT;
                            MEM_WE <= '1';

                            ip <= ip + 2;
                            state_after_idle <= FETCH;
                            state <= IDLE;

                        -- pop: pop to dst
                        when "010100" =>
                            dst_content := MEM_OUT;

                            ip <= ip + 1;
                            reload := '1';
                            state <= FETCH;
                        
                        when others => null; -- to compile

                        if (reload = '1') then
                            regs(to_integer(unsigned(dst))) <= dst_content;
                            regs(to_integer(unsigned(src))) <= src_content;
                            -- set zf (zero flag)
                            if (dst_content = "0000000000000000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;

                            -- set sf (sign flag)
                            flags(1) <= dst_content(15);
                        end if;
                    end case;
            end case;     
                
            
        end if;
    end process;
end mannerisms ; -- mannerisms




