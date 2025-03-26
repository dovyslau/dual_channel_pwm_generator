LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY nco IS
    GENERIC (
        WIDTH_ACC : INTEGER := 64
    );
    PORT (
        i_rstn : IN STD_LOGIC;
        i_clk : IN STD_LOGIC;
        i_srst : IN STD_LOGIC;
        i_en : IN STD_LOGIC;
        i_inc : IN STD_LOGIC_VECTOR(WIDTH_ACC - 1 DOWNTO 0);
        o_nco : OUT STD_LOGIC;
        o_nco_reg : OUT STD_LOGIC
    );
END nco;

ARCHITECTURE Behavioral OF nco IS

    SIGNAL inc : STD_LOGIC_VECTOR(WIDTH_ACC - 1 DOWNTO 0);
    SIGNAL acc : STD_LOGIC_VECTOR(WIDTH_ACC - 1 DOWNTO 0);
    SIGNAL add : STD_LOGIC_VECTOR(WIDTH_ACC DOWNTO 0);
    SIGNAL carry : STD_LOGIC;
    SIGNAL cnt : STD_LOGIC_VECTOR(WIDTH_ACC - 1 DOWNTO 0); --debug
BEGIN

    add <= ('0' & acc) + ('0' & i_inc);
    carry <= add(WIDTH_ACC);

    PROCESS (i_clk, i_rstn)
    BEGIN
        IF i_rstn = '0' THEN
            acc <= (OTHERS => '0');
            cnt <= (OTHERS => '0');
        ELSIF rising_edge(i_clk) THEN
            IF i_srst = '1' THEN
                cnt <= (OTHERS => '0');
                acc <= (OTHERS => '0');
            ELSIF i_en = '1' THEN
                acc <= add(WIDTH_ACC - 1 DOWNTO 0);
                --debug
                IF carry = '1' THEN
                    cnt <= (OTHERS => '0');
                ELSE
                    cnt <= cnt + '1';
                END IF;
                --------
            END IF;
        END IF;
    END PROCESS;

    o_nco <= carry;

    PROCESS (i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            o_nco_reg <= carry;
        END IF;
    END PROCESS;
END Behavioral;