library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_done : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
component datapath is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        
        dsel_load : in STD_LOGIC;
        output_load : in STD_LOGIC;
        load_to_mem : in STD_LOGIC;
        load_from_mem : in STD_LOGIC
    );
end component;
-- Segnali interni per matchare quelli nel datapath
signal dsel_load : STD_LOGIC;
signal output_load : STD_LOGIC;
signal load_to_mem : STD_LOGIC;
signal load_from_mem : STD_LOGIC;
-- Segnali per la macchina a stati
type STATE_TYPE is (IDLE, RESET, INPUT_READ, MEM_LOAD, MEM_READ, WRITE_OUT);
signal cur_state, next_state : STATE_TYPE;
begin
    DATAPATH0: datapath port map(
        i_clk => i_clk,
        i_rst => i_rst,
        i_start => i_start ,
        i_w => i_w,
        o_z0 => o_z0,
        o_z1 => o_z1,
        o_z2 => o_z2,
        o_z3 => o_z3,
        o_mem_addr => o_mem_addr,
        i_mem_data => i_mem_data,
        dsel_load => dsel_load,
        output_load => output_load,
        load_to_mem => load_to_mem,
        load_from_mem => load_from_mem
    );

    -- Reset o passaggio a prossimo stato
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            cur_state <= RESET;
        elsif rising_edge(i_clk) then
            cur_state <= next_state;
        end if;
    end process;
    
    -- Determina a quale stato passare
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            next_state <= cur_state;
            case cur_state is
                when IDLE =>
                    if i_start = '1' then
                        next_state <= INPUT_READ;
                    elsif i_rst = '1' then
                        next_state <= RESET;
                    end if;
                when RESET =>
                    if i_rst = '0' then
                        next_state <= IDLE;
                    end if;
                when INPUT_READ =>
                    if i_start = '0' then
                        next_state <= MEM_LOAD;
                    end if;
                when MEM_LOAD =>
                    next_state <= MEM_READ;
                when MEM_READ =>
                    next_state <= WRITE_OUT;
                when WRITE_OUT =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;
    
    -- Modifica variabili per ogni stato
    process(cur_state)
    begin
        -- Reset vari effettuati a ogni ciclo di clock
        o_done <= '0';
        dsel_load <= '0';
        output_load <= '0';
        o_mem_we <= '0';    -- Sempre a 0, mai usata
        o_mem_en <= '0';
        load_to_mem <= '0';
        load_from_mem <= '0';
        
        case cur_state is
            when IDLE =>
            when RESET =>
            when INPUT_READ =>
            when MEM_LOAD =>
                o_mem_en <= '1';
                load_to_mem <= '1';
            when MEM_READ =>
                o_mem_en <= '1';
                load_from_mem <= '1';
            when WRITE_OUT =>
                output_load <= '1';
                o_done <= '1';
        end case;
    end process;
end Behavioral;

--------------
-- DATAPATH --
--------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity datapath is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        
        dsel_load : in STD_LOGIC;
        output_load : in STD_LOGIC;
        load_to_mem : in STD_LOGIC;
        load_from_mem : in STD_LOGIC
    );
end datapath;

architecture Behavioral_DP of datapath is
    -- Altri segnali interni
    signal reg_input : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
    signal d_sel : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal reg0 : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal reg1 : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal reg2 : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal reg3 : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    -- Segnale per contare bit immessi
    signal bit_counter : integer range 0 to 17 := 0;
    
begin
       
    -- Reset
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if  i_rst = '1' then
                reg_input <= "0000000000000000";
                d_sel <= "00";
                o_mem_addr <= "0000000000000000";
            elsif output_load = '1' then
                reg_input <= "0000000000000000";
                d_sel <= "00";
            elsif i_start = '1' then
                -- Salvataggio direttamente su d_sel
                if bit_counter = 0 then
                    d_sel(1) <= i_w;
                elsif bit_counter = 1 then
                    d_sel(0) <= i_w;
                else 
                    -- Inserisco nel bit meno significativo di un registro temporaneo
                    reg_input <= reg_input(14 downto 0) & i_w;
                end if;
            elsif i_start = '0' then
                if load_to_mem = '1' then
                    o_mem_addr <= reg_input(15 downto 0);
                end if;
           end if;
        end if;
    end process;
    
   
    -- Aggiornamento bit_counter
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if  i_start = '1' then
                -- Incremento contatore
                bit_counter <= bit_counter + 1;
            else
                -- Resetta contatore se start = 0
                bit_counter <= 0;
            end if;
        end if;
    end process;
    
    ----------------------
    -- COPIA DA MEMORIA --
    ----------------------
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                reg0 <= "00000000";
                reg1 <= "00000000";
                reg2 <= "00000000";
                reg3 <= "00000000";
            elsif load_from_mem = '1' then
                if d_sel = "00" then
                    reg0 <= i_mem_data;
                elsif d_sel = "01" then
                    reg1 <= i_mem_data;
                elsif d_sel = "10" then
                    reg2 <= i_mem_data;
                elsif d_sel = "11" then
                    reg3 <= i_mem_data;
                end if;
            end if;
        end if;
    end process;
    
    -- SEGNALE IN USCITA
    process(output_load, i_rst, i_clk)
    begin
        if output_load = '1' then
            o_z0 <= reg0;
            o_z1 <= reg1;
            o_z2 <= reg2;
            o_z3 <= reg3;
        else
            o_z0 <= "00000000";
            o_z1 <= "00000000";
            o_z2 <= "00000000";
            o_z3 <= "00000000";
        end if;
    end process;

end Behavioral_DP;


