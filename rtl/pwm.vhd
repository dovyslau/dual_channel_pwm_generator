LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY pwm IS
    GENERIC (
        WIDTH_ACC_PERIOD : INTEGER := 64;
        WIDTH_ACC_DUTY : INTEGER := 64
    );
    PORT (
        i_clk : IN STD_LOGIC;
        i_rstn : IN STD_LOGIC;
        i_srst_duty : STD_LOGIC;
        i_srst_period : STD_LOGIC;
        i_duty : IN STD_LOGIC_VECTOR(WIDTH_ACC_DUTY - 1 DOWNTO 0);
        i_period : IN STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD - 1 DOWNTO 0);
        o_period_end : OUT STD_LOGIC;
        o_pwm : OUT STD_LOGIC
    );
END pwm;

ARCHITECTURE Behavioral OF pwm IS

    COMPONENT nco IS
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
    END COMPONENT;

    SIGNAL period_pulse : STD_LOGIC;
    SIGNAL duty_pulse : STD_LOGIC;
    SIGNAL pwm : STD_LOGIC;

BEGIN

    u_nco_period : nco
    GENERIC MAP(
        WIDTH_ACC => WIDTH_ACC_PERIOD
    )
    PORT MAP(
        i_rstn => i_rstn,
        i_clk => i_clk,
        i_srst => i_srst_period,
        i_en => '1',
        i_inc => i_period,
        o_nco => o_period_end,
        o_nco_reg => period_pulse
    );

    u_nco_duty : nco
    GENERIC MAP(
        WIDTH_ACC => WIDTH_ACC_DUTY
    )
    PORT MAP(
        i_rstn => i_rstn,
        i_clk => i_clk,
        i_srst => i_srst_duty,
        i_en => pwm,
        i_inc => i_duty,
        o_nco => OPEN,
        o_nco_reg => duty_pulse
    );

    PROCESS (i_clk, i_rstn)
    BEGIN
        IF i_rstn = '0' THEN
            pwm <= '0';
        ELSIF rising_edge(i_clk) THEN
            IF period_pulse = '1' THEN
                pwm <= '1';
            ELSIF duty_pulse = '1' THEN
                pwm <= '0';
            END IF;
        END IF;
    END PROCESS;

    o_pwm <= pwm;

END Behavioral;