library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ICE40_CPU is port(
    CLK         : in    std_logic;
    MEM_ADDR    : out   std_logic_vector(15 downto 0);
    MEM_IN      : out   std_logic_vector(15 downto 0);
    MEM_OUT     : in    std_logic_vector(15 downto 0);
    MEM_WE      : out   std_logic;
    HALT        : in    std_logic;

    DEBUG_OUT   : out   std_logic_vector(7 downto 0) := X"00"
);
end entity;

architecture mannerisms of ICE40_CPU is
    -- Custom types used
    type EXEC_STATES_T  is (FETCH, IDLE, EXEC, CONTD);
    type REGS_T         is array (7 downto 0) of std_logic_vector(15 downto 0);

    -- CPU micro-state
    signal state                :   EXEC_STATES_T                   := FETCH;
    signal state_after_idle     :   EXEC_STATES_T                   := FETCH;
    
    -- Saved values for subsequent instruction cycles
    signal opcode_contd         :   std_logic_vector(5 downto 0)    := "000000";
    signal dst_contd            :   std_logic_vector(4 downto 0)    := "00000";
    signal src_contd            :   std_logic_vector(4 downto 0)    := "00000";
    -- todo: get rid of these
    signal dst_content_contd    :   std_logic_vector(15 downto 0)   := X"0000";
    signal src_content_contd    :   std_logic_vector(15 downto 0)   := X"0000";

    -- General purpose registers
    signal regs                 :   REGS_T                          := (others => X"0000");

    -- Flags [zf, sf, cf, Pizza]
    signal flags                :   std_logic_vector(3 downto 0)    := X"0";

    -- Instruction pointer
    signal ip                   :   std_logic_vector(15 downto 0)   := X"0000";

begin
    -- insert mem things
    DEBUG_OUT <= regs(0)(7 downto 0);

    process(CLK)
        -- alu_op_out: contains the last carry bit to set the flag
        variable alu_op_out : std_logic_vector(16 downto 0);
        -- mult_tmp: contains the full result of a multiplication
        variable mult_tmp : std_logic_vector(31 downto 0) := X"00000000";
        -- tmp
        variable tmp : std_logic_vector(15 downto 0);

        variable opcode : std_logic_vector(5 downto 0);
        variable src : std_logic_vector(4 downto 0);
        variable dst : std_logic_vector(4 downto 0);

        -- todo: get rid of these
        variable dst_content : std_logic_vector(15 downto 0);
        variable src_content : std_logic_vector(15 downto 0);

        variable tmp_content : std_logic_vector(15 downto 0);
        variable jmp_cond_ok : std_logic;

        -- TODO: get rid of this, probably unneeded.
        variable reload : std_logic := '0';
    begin
        if(rising_edge(CLK)) then
            case state is
                when FETCH =>
                    if (HALT = '0') then
                        MEM_ADDR <= ip;
                        MEM_WE <= '0';
    
                        state <= IDLE;
                        state_after_idle <= EXEC;
                    end if;

                when IDLE =>
                    state <= state_after_idle;

                when EXEC =>
                    opcode := MEM_OUT(5 downto 0);
                    dst := MEM_OUT(10 downto 6);
                    src := MEM_OUT(15 downto 11);

                    dst_content := regs(to_integer(unsigned(dst)));
                    src_content := regs(to_integer(unsigned(src)));

                    opcode_contd <= opcode;
                    dst_contd <= dst;
                    src_contd <= src;
                    
                    -- get rid of this
                    dst_content_contd <= dst_content;
                    src_content_contd <= src_content;
                    
                    case opcode is
                        -- mvi: put imm into dst
                        when "000000" =>
                            MEM_ADDR <= ip + 1;

                            state <= IDLE;
                            state_after_idle <= CONTD;
                            -- FALLTHROUGH CONTD
                            
                        -- mvr: move src into dst
                        when "000001" =>
                            regs(to_integer(unsigned(dst))) <= src_content;

                            ip <= ip + 1;
                            state <= FETCH;
                        
                         -- xcg: exchange dst and src
                        when "000010" =>
                            regs(to_integer(unsigned(src))) <= dst_content;
                            regs(to_integer(unsigned(dst))) <= src_content;

                            ip <= ip + 1;
                            state <= FETCH;
                         
                        -- ldr: puts [src] into dst
                        when "000011" =>
                            MEM_ADDR <= src_content;
                            
                            state <= IDLE;
                            state_after_idle <= CONTD;
                            -- FALLTHROUGH CONTD

                        -- sti: store src into [imm]
                        when "000100" =>
                            MEM_ADDR <= ip + 1;

                            state <= IDLE;
                            state_after_idle <= CONTD;
                         
                        -- str: store src into [dst]
                        when "000101" =>
                            MEM_ADDR <= dst_content;
                            MEM_IN <= src_content;
                            MEM_WE <= '1';
                        
                            ip <= ip + 1;
                            state <= IDLE;
                            state_after_idle <= FETCH;
                        
                        -- add: puts dst+src into dst
                        when "000110" =>
                            alu_op_out := ('0' & dst_content) + ('0' & src_content);

                            -- result
                            regs(to_integer(unsigned(dst))) <= alu_op_out(15 downto 0);

                            -- flags
                            if (alu_op_out(15 downto 0) = X"0000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;
                            flags(1) <= alu_op_out(15);
                            flags(2) <= alu_op_out(16);

                            ip <= ip + 1;
                            state <= FETCH;
                        
                        -- sub: put dst-src into dst
                        when "000111" =>
                            alu_op_out := ('0' & dst_content) - ('0' & src_content);

                            -- result
                            regs(to_integer(unsigned(dst))) <= alu_op_out(15 downto 0);

                            -- flags
                            if (alu_op_out(15 downto 0) = X"0000") then
                                flags(0) <= '1';
                            else
                                flags(1) <= '0';
                            end if;
                            flags(1) <= alu_op_out(15);
                            flags(2) <= alu_op_out(16);
                            
                            ip <= ip + 1;
                            state <= FETCH;
                      
                        -- cmp: compares dst and src
                        when "001000" =>
                            alu_op_out := ('0' & dst_content) - ('0' & src_content);

                            if (alu_op_out(15 downto 0) = "0000000000000000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;
                            flags(1) <= alu_op_out(15);
                            flags(2) <= alu_op_out(16);

                            ip <= ip + 1;
                            state <= FETCH;
                            
                        -- mul: put dst*src into d:dst
                        when "001001" =>
                            mult_tmp := dst_content*src_content;

                            regs(to_integer(unsigned(dst))) <= mult_tmp(15 downto 0);
                            regs(3) <= mult_tmp(31 downto 16);

                            -- TODO: fill flags correctly
                            flags <= X"0";

                            ip <= ip + 1;
                            state <= FETCH;

                            
                        -- inc: increment dst
                        -- note: temporarily doesn't update flags
                        when "001010" =>
                            tmp := dst_content + X"0001";

                            regs(to_integer(unsigned(dst))) <= tmp;

                            ip <= ip + 1;
                            state <= FETCH;
                        
                        -- dec: decrement dst
                        -- note: temporarily only updates zf
                        when "001011" =>
                            tmp := dst_content - X"0001";

                            regs(to_integer(unsigned(dst))) <= tmp;

                            if (tmp = X"0000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;

                            ip <= ip + 1;
                            state <= FETCH;
                            
                        -- xor: dst = dst xor b
                        when "001100" =>
                            tmp := dst_content xor src_content;
                            regs(to_integer(unsigned(dst))) <= tmp;

                            if (tmp = X"0000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;
                                flags(1) <= tmp(15);
                            flags(2) <= '0';

                            ip <= ip + 1;
                            state <= FETCH;
                        
                        -- and: dst = dst and src
                        when "001101" =>
                            tmp := dst_content and src_content;
                            regs(to_integer(unsigned(dst))) <= tmp;

                            if (tmp = X"0000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;
                            flags(1) <= tmp(15);
                            flags(2) <= '0';

                            ip <= ip + 1;
                            state <= FETCH;

                        -- or: dst = dst or src
                        when "001110" =>
                            tmp := dst_content or src_content;
                            regs(to_integer(unsigned(dst))) <= tmp;

                            if (tmp = X"0000") then
                                flags(0) <= '1';
                            else
                                flags(0) <= '0';
                            end if;
                            flags(1) <= tmp(15);
                            flags(2) <= '0';

                            ip <= ip + 1;
                            state <= FETCH;
                      
                        -- shl: shift left
                        when "001111" => 
                            regs(to_integer(unsigned(dst))) <= std_logic_vector(shift_left(unsigned(dst_content), to_integer(unsigned(src))));

                            ip <= ip + 1;
                            state <= FETCH;

                        -- shr: shift right
                        when "010000" =>
                            regs(to_integer(unsigned(dst))) <= std_logic_vector(shift_right(unsigned(dst_content), to_integer(unsigned(src))));

                            ip <= ip + 1;
                            state <= FETCH;
                                             
                        -- jmp: jump to dst
                        when "010001" =>
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
                            
                        -- psi: push immediate
                        when "010010" =>
                            MEM_ADDR <= ip + 1;
                            regs(7) <= regs(7) - 1;

                            state_after_idle <= CONTD;
                            state <= IDLE;

                        -- psh: push dst
                        when "010011" =>
                            -- write dst_content into [rsp - 1]
                            MEM_ADDR <= regs(7) - 1;
                            MEM_IN <= dst_content;
                            MEM_WE <= '1';

                            -- decrement dst
                            regs(7) <= regs(7) - 1;

                            ip <= ip + 1;
                            state_after_idle <= FETCH;
                            state <= IDLE;

                        -- pop: pop to dst
                        when "010100" =>
                            MEM_ADDR <= regs(7);

                            regs(7) <= regs(7) + 1;
                            
                            state_after_idle <= CONTD;
                            state <= IDLE;
                        
                        -- hlt: halt
                        when "010101" =>
                            state <= FETCH;

                        -- ret: return using IP from stack
                        when "010110" =>
                            MEM_ADDR <= regs(7);

                            regs(7) <= regs(7) + 1;
                            
                            state_after_idle <= CONTD;
                            state <= IDLE;

                        when others => null; -- to compile
                    end case;

                when CONTD =>
                    -- restore the variable
                    opcode := opcode_contd;
                    dst := dst_contd;
                    src := src_contd;
                    dst_content := dst_content_contd;
                    src_content := src_content_contd;

                    case opcode is
                        -- mvi: put imm into dst
                        when "000000" =>
                            regs(to_integer(unsigned(dst))) <= MEM_OUT;

                            ip <= ip + 2;
                            state <= FETCH;
                           
                        -- ldr: load [src] into dst
                        when "000011" =>
                            regs(to_integer(unsigned(dst))) <= MEM_OUT;

                            ip <= ip + 1;
                            state <= FETCH;
                            
                        -- sti: stores src into [imm]
                        when "000100" =>
                            MEM_ADDR <= MEM_OUT;
                            MEM_IN <= src_content;
                            MEM_WE <= '1';

                            ip <= ip + 2;
                            state_after_idle <= FETCH;
                            state <= IDLE;
                     
                        -- jmp: contd for immediate
                        when "010001" =>
                            ip <= MEM_OUT;
                            state <= FETCH;               

                        -- psi: push immediate
                        when "010010" =>
                            MEM_ADDR <= regs(7);
                            MEM_IN <= MEM_OUT;
                            MEM_WE <= '1';

                            ip <= ip + 2;
                            state_after_idle <= FETCH;
                            state <= IDLE;

                        -- pop: pop to dst
                        when "010100" =>
                            regs(to_integer(unsigned(dst))) <= MEM_OUT;

                            ip <= ip + 1;
                            state <= FETCH;

                        -- ret: return using IP from the stack
                        when "010110" =>
                            ip <= MEM_OUT;
                            state <= FETCH;
                        
                        when others => null; -- to compile
                    end case;
            end case;
        end if;
    end process;
end mannerisms ; -- mannerisms




