LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pulse_sync is
    port (
        i_rstn    : in std_logic;
        i_clk_a   : in std_logic;
        i_clk_b   : in std_logic;
        i_pulse_a : in std_logic;
        o_pulse_b : out std_logic
    );
end pulse_sync;

architecture Behavioral of pulse_sync is
    signal pulse_a_reg : std_logic;
    signal pulse_b_reg : std_logic_vector(2 downto 0);
begin

    process(i_clk_a, i_rstn)
    begin
        if i_rstn = '0' then
            pulse_a_reg <= '0';
        elsif rising_edge(i_clk_a) then
            if i_pulse_a = '1' then
                pulse_a_reg <= not pulse_a_reg;
            else 
                pulse_a_reg <= pulse_a_reg;
            end if;
        end if;
    end process;
    
    process(i_clk_b, i_rstn)
    begin
        if i_rstn = '0' then
            pulse_b_reg <= (others => '0');
        elsif rising_edge(i_clk_b) then
            pulse_b_reg <= pulse_b_reg(1 downto 0) & pulse_a_reg;
        end if;
    end process;

    o_pulse_b <= pulse_b_reg(2) xor pulse_b_reg(1);

end Behavioral;